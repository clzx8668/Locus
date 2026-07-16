import 'dart:async';
import 'package:flutter/foundation.dart';
import '../enums/processing_status.dart';
import '../../features/idea_stream/data/idea_repository.dart';
import 'connectivity_service.dart';
import 'text_cleaner_service.dart';
import 'vector_service.dart';
import 'vector_dedup_service.dart';
import 'ai_router_service.dart';
import 'dispatch_service.dart';
import 'decay_manager.dart';

/// 处理流水线事件
class ProcessingEvent {
  final int payloadId;
  final ProcessingStatus status;
  final String? message;

  const ProcessingEvent({
    required this.payloadId,
    required this.status,
    this.message,
  });
}

/// 处理管线编排器 —— 协调四步异步流水线
class ProcessingPipeline {
  final IdeaRepository _ideaRepository;
  final ConnectivityService _connectivity;
  final TextCleanerService _textCleaner;
  final VectorService _vectorService;
  late final VectorDedupService _dedupService;
  late final AiRouterService _routerService;
  late final DispatchService _dispatchService;
  late final DecayManager _decayManager;

  final _eventController = StreamController<ProcessingEvent>.broadcast();
  final _queue = <int>[];
  final _queuedIds = <int>{};
  bool _isProcessing = false;
  Timer? _workerTimer;
  StreamSubscription<bool>? _connectivitySub;

  ProcessingPipeline(
    this._ideaRepository,
    this._connectivity,
    this._textCleaner,
    this._vectorService,
    VectorDedupService dedupService,
    AiRouterService routerService,
    DispatchService dispatchService,
    DecayManager decayManager,
  ) : _dedupService = dedupService,
      _routerService = routerService,
      _dispatchService = dispatchService,
      _decayManager = decayManager {
    // 监听网络恢复，处理离线队列并重试失败任务
    _connectivitySub = _connectivity.onConnectivityChange.listen((online) {
      if (online) {
        _processOfflineQueue();
        _retryFailedItems();
      }
    });

    // 启动时处理遗留的离线队列和 pending 项目
    Future.microtask(() {
      _processOfflineQueue();
      _retryFailedItems();
    });
  }

  /// 暴露状态变更事件流
  Stream<ProcessingEvent> get events => _eventController.stream;

  /// v17: 仅执行同步第一阶段（清洗+落库），异步阶段由 Worker 执行
  void enqueue(int payloadId) {
    if (_queuedIds.contains(payloadId)) return;
    _queuedIds.add(payloadId);
    processSync(payloadId);
  }

  /// 手动重新入队处理指定 payload（刷新 FTS 索引 + 重新 AI 路由）
  void manualEnqueue(int payloadId) {
    if (_queuedIds.contains(payloadId)) return;
    _queuedIds.add(payloadId);
    processSync(payloadId);
  }

  /// v17: 启动后台异步 Worker，定时扫描 textCleaned 状态的记录
  void _startBackgroundWorker() {
    if (_workerTimer != null) return;
    _workerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isProcessing) return;
      _processNextAsync();
    });
  }

  /// 扫描 textCleaned 状态的记录并出队执行 AI 分析
  Future<void> _processNextAsync() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final items = await _ideaRepository.getByProcessingStatus(
        ProcessingStatus.textCleaned.toDbValue(),
        limit: 3,
      );
      for (final item in items) {
        try {
          await processAsync(item.id);
        } catch (e) {
          await _ideaRepository.updateProcessingStatus(
            item.id,
            ProcessingStatus.failedRetry,
          );
          _emit(item.id, ProcessingStatus.failedRetry, '处理失败，等待重试');
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 后台 Worker 清理
  void disposeWorker() {
    _workerTimer?.cancel();
    _workerTimer = null;
  }

  /// v17 第一阶段（同步）：清洗文本 → 标记 textCleaned
  Future<void> processSync(int payloadId) async {
    final payload = await _ideaRepository.getById(payloadId);
    if (payload == null) return;

    // 离线检测
    if (!_connectivity.isOnline) {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.offlineSaved,
      );
      _emit(payloadId, ProcessingStatus.offlineSaved, '离线已保存');
      return;
    }

    // 标记 textCleaned（清洗在 processAsync 中完成）
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.textCleaned,
    );
    _emit(payloadId, ProcessingStatus.textCleaned);

    _startBackgroundWorker();
  }

  /// v17 第二阶段（异步）：清洗文本 → FTS 索引 → AI 路由 → 分发
  Future<void> processAsync(int payloadId) async {
    final payload = await _ideaRepository.getById(payloadId);
    if (payload == null) return;

    // 清洗文本
    final text = _textCleaner.clean(payload.rawText);

    if (text.trim().isEmpty) {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, '无可向量化文本，跳过后台处理');
      return;
    }

    // Step: FTS 本地索引
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.vectorChecking,
    );
    _emit(payloadId, ProcessingStatus.vectorChecking);

    final uuid = await _ideaRepository.getUuidById(payloadId);
    if (uuid != null && uuid.isNotEmpty) {
      await _generateAndStoreVector(payloadId, text, uuid);
    } else {
      _emit(payloadId, ProcessingStatus.vectorChecking, 'UUID 缺失，跳过向量索引');
    }

    // Step: AI 路由
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.aiRouting,
    );
    _emit(payloadId, ProcessingStatus.aiRouting);

    final routing = await _routerService.route(payloadId);

    if (routing == null) {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, 'AI 路由未返回结果');
      return;
    }

    // 如果 AI 判定为废话，标记衰减并结束
    if (routing.isEphemeral) {
      await _decayManager.markAsEphemeral(payloadId);
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, '标记为日常废话');
      return;
    }

    // 检查是否具备规则化条件
    if (routing.intentTag != 'NOTE' && routing.intentTag != 'HABIT') {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatching,
      );
      _emit(payloadId, ProcessingStatus.dispatching);

      await _dispatchService.stageForReview(payloadId, routing);
    } else {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, routing.intentTag);
    }
  }

  void _emit(int payloadId, ProcessingStatus status, [String? message]) {
    _eventController.add(
      ProcessingEvent(payloadId: payloadId, status: status, message: message),
    );
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final payloadId = _queue.removeAt(0);
      _queuedIds.remove(payloadId);
      try {
        await _processOne(payloadId);
      } catch (e) {
        // 任一阶段失败 → 标记 failed_retry
        await _ideaRepository.updateProcessingStatus(
          payloadId,
          ProcessingStatus.failedRetry,
        );
        _emit(payloadId, ProcessingStatus.failedRetry, '处理失败，等待重试');
      }
    }

    _isProcessing = false;
  }

  /// 处理单个 payload 的四步流水线
  Future<void> _processOne(int payloadId) async {
    final payload = await _ideaRepository.getById(payloadId);
    if (payload == null) return;

    if (payload.rawText.trim().isEmpty) {
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, '无可向量化文本，跳过后台处理');
      return;
    }

    // Step 1: 本地 FTS 索引（纯本地，不依赖网络）
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.vectorChecking,
    );
    _emit(payloadId, ProcessingStatus.vectorChecking);

    final uuid = await _ideaRepository.getUuidById(payloadId);
    if (uuid != null && uuid.isNotEmpty) {
      await _generateAndStoreVector(payloadId, payload.rawText, uuid);
    } else {
      _emit(payloadId, ProcessingStatus.vectorChecking, 'UUID 缺失，跳过向量索引');
    }

    // Step 2: AI 路由与实体抽取
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.aiRouting,
    );
    _emit(payloadId, ProcessingStatus.aiRouting);

    final routingResult = await _routerService.route(payloadId);

    // 如果 AI 判定为废话，标记衰减并结束
    if (routingResult.isEphemeral) {
      await _decayManager.markAsEphemeral(payloadId);
      await _ideaRepository.updateProcessingStatus(
        payloadId,
        ProcessingStatus.dispatched,
      );
      _emit(payloadId, ProcessingStatus.dispatched, '标记为日常废话');
      return;
    }

    // Step 3: 结构化分发 → 暂存到 AI 收件箱（待用户确认）
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.dispatching,
    );
    _emit(payloadId, ProcessingStatus.dispatching);

    // 仅对 CRM / LEDGER / TODO 三个意图暂存到收件箱
    // NOTE / HABIT 无需分发，直接标记完成
    if (['CRM', 'LEDGER', 'TODO'].contains(routingResult.intentTag)) {
      final inboxId = await _dispatchService.stageForReview(
        payloadId,
        routingResult,
      );
      _emit(
        payloadId,
        ProcessingStatus.pendingReview,
        '已暂存到收件箱 #$inboxId，等待确认',
      );
      return;
    }

    // NOTE 等无需分发的类型直接完成
    await _ideaRepository.updateProcessingStatus(
      payloadId,
      ProcessingStatus.dispatched,
    );
    _emit(payloadId, ProcessingStatus.dispatched, '已完成');
  }

  Future<void> _generateAndStoreVector(
    int payloadId,
    String rawText,
    String uuid,
  ) async {
    // 纯本地 FTS 索引：将文本通过 jieba 分词写入 Zvec
    await _vectorService.upsertFtsDoc(uuid: uuid, content: rawText);
    // 本地 FTS 查重
    await _dedupService.checkLocalSimilarity(payloadId, rawText, uuid);
  }

  /// 处理离线队列：将 offlineSaved 状态的消息直接转为 textCleaned 并加入异步 Worker
  Future<void> _processOfflineQueue() async {
    if (!_connectivity.isOnline) return;
    try {
      final items = await _ideaRepository.getByProcessingStatus(
        ProcessingStatus.offlineSaved.toDbValue(),
        limit: 20,
      );
      if (items.isEmpty) return;
      debugPrint('[ProcessingPipeline] 离线队列处理开始，共 ${items.length} 条');
      int processed = 0;
      for (final item in items) {
        try {
          await _ideaRepository.updateProcessingStatus(item.id, ProcessingStatus.textCleaned);
          _emit(item.id, ProcessingStatus.textCleaned, '离线队列恢复，等待AI分析');
          processed++;
        } catch (e) {
          debugPrint('[ProcessingPipeline] 离线队列处理失败 id=${item.id}: $e');
        }
      }
      debugPrint('[ProcessingPipeline] 离线队列处理完成，成功 $processed/${items.length} 条');
      _startBackgroundWorker();
    } catch (e) {
      debugPrint('[ProcessingPipeline] 离线队列扫描失败: $e');
    }
  }

  /// 重试所有挂起的失败任务
  Future<void> _retryFailedItems() async {
    if (!_connectivity.isOnline) return;

    try {
      final pending = await _ideaRepository.getPendingVectorPayloads();
      for (final item in pending) {
        _queuedIds.remove(item.id);
        enqueue(item.id);
      }
    } catch (_) {}
  }

  void dispose() {
    disposeWorker();
    _connectivitySub?.cancel();
    _eventController.close();
  }
}

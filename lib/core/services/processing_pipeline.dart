import 'dart:async';
import 'package:drift/drift.dart' show OrderingTerm;
import '../database/database.dart';
import '../enums/processing_status.dart';
import 'connectivity_service.dart';
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
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  late final VectorDedupService _dedupService;
  late final AiRouterService _routerService;
  late final DispatchService _dispatchService;
  late final DecayManager _decayManager;

  final _eventController = StreamController<ProcessingEvent>.broadcast();
  final _queue = <int>[];
  bool _isProcessing = false;
  StreamSubscription<bool>? _connectivitySub;

  ProcessingPipeline(
    this._db,
    this._connectivity,
    VectorDedupService dedupService,
    AiRouterService routerService,
    DispatchService dispatchService,
    DecayManager decayManager,
  )   : _dedupService = dedupService,
        _routerService = routerService,
        _dispatchService = dispatchService,
        _decayManager = decayManager {
    // 监听网络恢复，重启失败的任务
    _connectivitySub = _connectivity.onConnectivityChange.listen((online) {
      if (online) _retryFailedItems();
    });

    // 启动时处理遗留的 pending 项目
    Future.microtask(() => _retryFailedItems());
  }

  /// 暴露状态变更事件流
  Stream<ProcessingEvent> get events => _eventController.stream;

  /// 将 payload 加入处理队列
  void enqueue(int payloadId) {
    _queue.add(payloadId);
    _processNext();
  }

  void _emit(int payloadId, ProcessingStatus status, [String? message]) {
    _eventController.add(ProcessingEvent(
      payloadId: payloadId,
      status: status,
      message: message,
    ));
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final payloadId = _queue.removeAt(0);
      try {
        await _processOne(payloadId);
      } catch (e) {
        // 任一阶段失败 → 标记 failed_retry
        await _db.updateProcessingStatus(
            payloadId, ProcessingStatus.failedRetry.toDbValue());
        _emit(payloadId, ProcessingStatus.failedRetry, '处理失败，等待重试');
      }
    }

    _isProcessing = false;
  }

  /// 处理单个 payload 的四步流水线
  Future<void> _processOne(int payloadId) async {
    // Step 1: 向量查重
    await _db.updateProcessingStatus(
        payloadId, ProcessingStatus.vectorChecking.toDbValue());
    _emit(payloadId, ProcessingStatus.vectorChecking);

    await _dedupService.checkSimilarity(payloadId);
    // 查重结果（相似通知）可由 UI 层订阅 events 后主动展示

    // Step 2: AI 路由与实体抽取
    await _db.updateProcessingStatus(
        payloadId, ProcessingStatus.aiRouting.toDbValue());
    _emit(payloadId, ProcessingStatus.aiRouting);

    final routingResult = await _routerService.route(payloadId);

    // 如果 AI 判定为废话，标记衰减并结束
    if (routingResult.isEphemeral) {
      await _decayManager.markAsEphemeral(payloadId);
      await _db.updateProcessingStatus(
          payloadId, ProcessingStatus.dispatched.toDbValue());
      _emit(payloadId, ProcessingStatus.dispatched, '标记为日常废话');
      return;
    }

    // Step 3: 结构化分发
    await _db.updateProcessingStatus(
        payloadId, ProcessingStatus.dispatching.toDbValue());
    _emit(payloadId, ProcessingStatus.dispatching);

    final ref = await _dispatchService.dispatch(payloadId, routingResult);

    // 更新分发引用
    if (ref != null) {
      await _db.updateDispatchedRef(payloadId, ref);
    }

    // Step 4: 完成
    await _db.updateProcessingStatus(
        payloadId, ProcessingStatus.dispatched.toDbValue());
    _emit(payloadId, ProcessingStatus.dispatched, ref ?? '已完成');
  }

  /// 重试所有挂起的失败任务
  Future<void> _retryFailedItems() async {
    if (!_connectivity.isOnline) return;

    try {
      final failed = await (_db.select(_db.hubPayloads)
            ..where((t) => t.processingStatus.equals('failed_retry'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

      for (final item in failed) {
        enqueue(item.id);
      }
    } catch (_) {}
  }

  void dispose() {
    _connectivitySub?.cancel();
    _eventController.close();
  }
}

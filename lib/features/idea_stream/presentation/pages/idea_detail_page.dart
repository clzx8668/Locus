import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ai_engine.dart';
import '../../../../core/services/ai_router_service.dart';
import '../../../../core/services/dispatch_service.dart';
import '../../../../core/services/processing_pipeline.dart';
import '../../../../core/enums/processing_status.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/idea_repository.dart';
import '../../../../core/constants/field_labels.dart';
import '../widgets/content_block_editor.dart';
import '../widgets/full_block_editor.dart';
import '../widgets/export_bottom_sheet.dart';
import '../widgets/ai_chat_input_box.dart';
import 'template_management_page.dart';

// 标签颜色对
class _TagColor {
  final Color fg;
  final Color bg;
  const _TagColor(this.fg, this.bg);
}

// 标签彩色调色板（前景色, 背景色）
const _tagPalette = [
  _TagColor(Color(0xFFE85D75), Color(0xFFFDE8EC)), // 玫红
  _TagColor(Color(0xFF5B8FF9), Color(0xFFE8F0FE)), // 蓝
  _TagColor(Color(0xFF61DDAA), Color(0xFFE6F9F3)), // 绿
  _TagColor(Color(0xFFF6BD16), Color(0xFFFFF6D9)), // 金
  _TagColor(Color(0xFF9D68F2), Color(0xFFF3EAFF)), // 紫
  _TagColor(Color(0xFF33A5B7), Color(0xFFE3F4F7)), // 青
  _TagColor(Color(0xFFFF8C42), Color(0xFFFFF0E3)), // 橙
  _TagColor(Color(0xFF7B8DA1), Color(0xFFEFF2F5)), // 灰蓝
];

class IdeaDetailPage extends StatefulWidget {
  final HubPayload payload;

  const IdeaDetailPage({super.key, required this.payload});

  @override
  State<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends State<IdeaDetailPage> {
  final _repo = getIt<IdeaRepository>();
  final _ai = getIt<AiEngine>();
  final _pipeline = getIt<ProcessingPipeline>();
  late final DispatchService _dispatchService;

  // AI 对话输入
  final TextEditingController _aiInputController = TextEditingController();
  bool _isAiWorking = false;
  String _activeAiAction = '';
  final FocusNode _aiInputFocus = FocusNode();

  /// 当前选中的 AI 模型 ID
  String _selectedModel = '';

  final ScrollController _scrollController = ScrollController();

  final Set<int> _expandedTags = {}; // 标签展开状态

  /// 处理状态横幅
  bool _showStatusBanner = true;
  Timer? _statusBannerTimer;

  /// 编辑模式：正在编辑的用户消息ID，以及其配对的AI回复ID
  int? _editingUserConvId;
  int? _editingPairedAiConvId;

  late String _currentTitle;

  late final Stream<List<ContentBlock>> _blocksStream;
  late final Stream<List<AiConversation>> _conversationsStream;
  late final Stream<List<AiTemplate>> _templatesStream;
  late final TemplateRepository _templateRepo;

  @override
  void initState() {
    super.initState();
    _blocksStream = _repo.watchBlocks(widget.payload.id);
    _conversationsStream = _repo.watchConversations(widget.payload.id);
    _templateRepo = getIt<TemplateRepository>();
    _templatesStream = _templateRepo.watchEnabled();
    _dispatchService = getIt<DispatchService>();
    _selectedModel = _ai.modelName;
    _initContentBlocks();
    _initAiConversations();
    _initTitle();
    _resetStatusBanner();
  }

  @override
  void didUpdateWidget(covariant IdeaDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 payload 更新时（如处理状态变更），重新评估横幅
    if (oldWidget.payload.processingStatus != widget.payload.processingStatus ||
        oldWidget.payload.id != widget.payload.id) {
      _resetStatusBanner();
    }
  }

  /// 初始化内容块：如果 DB 中没有块，将 payload.rawText 作为第一个块写入
  void _initContentBlocks() async {
    // 给 StreamBuilder 一点时间，如果已有块则不处理
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 检查是否已有块（通过 listen 回调判断比较麻烦，改用简单延迟触发）
    // 这里用一次查询判断
    try {
      _repo.watchBlocks(widget.payload.id).first.then((blocks) {
        if (!mounted) return;
        if (blocks.isEmpty && widget.payload.rawText.isNotEmpty) {
          _repo.addBlock(
            widget.payload.id,
            'text',
            widget.payload.rawText,
            _parseMediaPaths(widget.payload.mediaPaths),
          );
          // 保留前200字作为列表卡片摘要
          final preview = widget.payload.rawText.length > 200
              ? '${widget.payload.rawText.substring(0, 200)}...'
              : widget.payload.rawText;
          _repo.update(widget.payload.id, preview, widget.payload.intentTag);
        }
      });
    } catch (_) {}
  }

  void _initAiConversations() {
    // 数据库表新建时不需要特别初始化
  }

  void _initTitle() {
    final payloadTitle = widget.payload.title;
    if (payloadTitle != null && payloadTitle.isNotEmpty) {
      _currentTitle = payloadTitle;
    } else {
      // 标题为空时，延迟从首块内容自动提取
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _repo.watchBlocks(widget.payload.id).first.then((blocks) {
          if (!mounted) return;
          if (blocks.isNotEmpty && blocks.first.content.isNotEmpty) {
            final text = blocks.first.content;
            final firstLine = text.split('\n').first.trim();
            if (firstLine.isEmpty) {
              _currentTitle = '';
              return;
            }
            // 去除 Markdown 标题标记
            final cleanTitle = firstLine.replaceFirst(
              RegExp(r'^#{1,3}\s+'),
              '',
            );
            _currentTitle = cleanTitle.length > 30
                ? '${cleanTitle.substring(0, 30)}...'
                : cleanTitle;
            // 写入数据库
            _repo.updateTitle(widget.payload.id, _currentTitle);
            if (mounted) setState(() {});
          }
        });
      });
      _currentTitle = widget.payload.title ?? '';
    }
  }

  bool get _hasActiveInbox {
    final s = widget.payload.processingStatus;
    return s == ProcessingStatus.pendingReview.toDbValue() ||
        s == ProcessingStatus.dispatched.toDbValue() ||
        s == ProcessingStatus.decayed.toDbValue();
  }

  void _resetStatusBanner() {
    final status = ProcessingStatus.fromString(widget.payload.processingStatus);
    // 已完成状态不显示横幅
    if (status == ProcessingStatus.dispatched ||
        status == ProcessingStatus.decayed) {
      _showStatusBanner = false;
      return;
    }
    // 处理中状态：显示横幅，1.5s 后隐藏
    _showStatusBanner = true;
    _statusBannerTimer?.cancel();
    _statusBannerTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showStatusBanner = false);
      }
    });
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这条闪念吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _repo.delete(widget.payload.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showEditTitleDialog(bool isDark) {
    final controller = TextEditingController(text: _currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改标题'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标题',
            filled: true,
            fillColor: isDark
                ? const Color(0xFF262626)
                : const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 100,
          onSubmitted: (val) {
            final newTitle = val.trim();
            _currentTitle = newTitle.isEmpty ? '' : newTitle;
            _repo.updateTitle(
              widget.payload.id,
              newTitle.isEmpty ? null : newTitle,
            );
            setState(() {});
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              _currentTitle = newTitle.isEmpty ? '' : newTitle;
              _repo.updateTitle(
                widget.payload.id,
                newTitle.isEmpty ? null : newTitle,
              );
              setState(() {});
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// pending 状态下的三个图标按钮，供 _InboxFieldList 尾部使用
  Widget _buildPendingActionIcons(
    DispatchInboxData inbox,
    bool confirmDisabled,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            onPressed: () => _regenerateDispatch(inbox),
            icon: const Icon(Icons.refresh, size: 20),
            padding: EdgeInsets.zero,
            tooltip: '重新生成',
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            onPressed: () => _rejectInbox(inbox),
            icon: Icon(Icons.close, size: 20, color: theme.colorScheme.error),
            padding: EdgeInsets.zero,
            tooltip: '拒绝',
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            onPressed: confirmDisabled ? null : () => _confirmDispatch(inbox),
            icon: Icon(
              Icons.check,
              size: 20,
              color: confirmDisabled
                  ? theme.disabledColor
                  : theme.colorScheme.primary,
            ),
            padding: EdgeInsets.zero,
            tooltip: '确认分发',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// 已确认状态下的两个图标按钮（编辑数据 + 撤销分发），供 _InboxFieldList 尾部使用
  Widget _buildConfirmedActionIcons(DispatchInboxData inbox, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editInboxData(inbox),
            padding: EdgeInsets.zero,
            tooltip: '编辑数据',
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            icon: Icon(Icons.undo, size: 20, color: theme.colorScheme.error),
            onPressed: () => _undoDispatch(inbox),
            padding: EdgeInsets.zero,
            tooltip: '撤销分发',
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  /// AI 收件箱审核卡片 —— 内嵌在详情页 AI 对话区下方
  /// v14: 中文字段标签、手动编辑、缺键补录、多目的地同步
  Widget _buildDispatchInboxCard(
    ThemeData theme,
    bool isDark,
    DispatchInboxData inbox, {
    String? dispatchedRef,
  }) {
    final entities = _parseEntities(inbox.extractedData);
    final isConfirmed = inbox.status == 'confirmed';
    final isRejected = inbox.status == 'rejected';
    final intentTag = inbox.intentTag;
    final missingKeys = RequiredFields.detectMissing(intentTag, entities);
    final hasMissing = missingKeys.isNotEmpty;
    // 用户可能编辑了 entities，需要实时检测
    final currentMissing = _getCurrentMissing(intentTag, entities);
    final confirmDisabled = currentMissing.isNotEmpty;

    // 可选同步目标（排除主目标本身）
    final availableTargets = _getAvailableSyncTargets(intentTag);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _intentColor(intentTag).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _intentIcon(intentTag),
                      size: 14,
                      color: _intentColor(intentTag),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI 识别 → $intentTag${isConfirmed
                          ? " (已确认)"
                          : isRejected
                          ? " (已拒绝)"
                          : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _intentColor(intentTag),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isConfirmed)
                Icon(Icons.check_circle, size: 16, color: Colors.green[400])
              else if (isRejected)
                const Icon(Icons.cancel, size: 16, color: Colors.redAccent)
              else
                const Icon(
                  Icons.pending_outlined,
                  size: 16,
                  color: Colors.amber,
                ),
            ],
          ),
          // 缺键警告横幅
          if (!isConfirmed && !isRejected && hasMissing) ...[
            const SizedBox(height: 8),
            _buildMissingFieldsBanner(theme, missingKeys),
          ],
          const SizedBox(height: 8),
          // AI 抽取字段 —— 可点击编辑；pending 状态时将操作图标并入字段底部行
          if (entities.isNotEmpty)
            _buildInboxFields(
              theme,
              isDark,
              entities,
              intentTag,
              false,
              inbox.id,
              trailingActions: isConfirmed
                  ? _buildConfirmedActionIcons(inbox, theme)
                  : isRejected
                  ? null
                  : _buildPendingActionIcons(inbox, confirmDisabled, theme),
            ),
          // 已确认且有分发引用时显示链接
          if (isConfirmed &&
              dispatchedRef != null &&
              dispatchedRef.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInboxDispatchedLinkRow(dispatchedRef),
          ],
          // 多目的地勾选区域（未确认时显示）
          if (!isConfirmed && availableTargets.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSyncTargetsCheckboxes(theme, availableTargets, intentTag),
          ],
          // 操作按钮：pending/已确认的图标按钮已并入字段区域，此处仅渲染已拒绝的按钮
          if (isRejected) ...[
            const SizedBox(height: 8),
            _buildInboxActions(inbox),
          ],
        ],
      ),
    );
  }

  /// 获取可选的额外同步目标（排除主意图对应的表）
  List<String> _getAvailableSyncTargets(String intentTag) {
    const allTargets = ['crm_customers', 'ledger_entries', 'todo_schedules'];
    final mainTarget = _targetTableForIntent(intentTag);
    return allTargets.where((t) => t != mainTarget).toList();
  }

  String _targetTableForIntent(String intentTag) {
    switch (intentTag) {
      case 'CRM':
        return 'crm_customers';
      case 'LEDGER':
        return 'ledger_entries';
      case 'TODO':
        return 'todo_schedules';
      default:
        return '';
    }
  }

  /// 当前实体数据的缺失核心键值（用户可能已在本地编辑过）
  List<String> _getCurrentMissing(
    String intentTag,
    Map<String, dynamic> entities,
  ) {
    return RequiredFields.detectMissing(intentTag, entities);
  }

  /// 用户编辑后的实体数据覆盖（本地内存状态）
  final Map<int, Map<String, dynamic>> _editedEntities = {};

  /// 获取当前生效的实体数据（含用户编辑）
  Map<String, dynamic> _getEffectiveEntities(
    int inboxId,
    Map<String, dynamic> original,
  ) {
    return _editedEntities[inboxId] ?? original;
  }

  /// 缺键警告横幅
  Widget _buildMissingFieldsBanner(ThemeData theme, List<String> missingKeys) {
    final labels = missingKeys.join('、');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '缺少关键信息：$labels',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB8860B)),
            ),
          ),
        ],
      ),
    );
  }

  /// 可编辑字段列表 —— 每个字段显示中文标签，点击可编辑
  Widget _buildInboxFields(
    ThemeData theme,
    bool isDark,
    Map<String, dynamic> entities,
    String intentTag,
    bool isConfirmed,
    int inboxId, {
    Widget? trailingActions,
  }) {
    return _InboxFieldList(
      entities: entities,
      intentTag: intentTag,
      isConfirmed: isConfirmed,
      onFieldEdited: (key, value) {
        final updated = Map<String, dynamic>.from(entities);
        if (value.isEmpty) {
          updated.remove(key);
        } else {
          updated[key] = value;
        }
        _dispatchService.updateInboxExtractedData(inboxId, updated);
        setState(() {});
      },
      fieldLabels: FieldLabels,
      trailingActions: trailingActions,
    );
  }

  /// 多目的地勾选区域
  Widget _buildSyncTargetsCheckboxes(
    ThemeData theme,
    List<String> availableTargets,
    String intentTag,
  ) {
    // 用 state 记录用户勾选的额外目标
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '同时写入',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availableTargets.map((target) {
                  final isChecked = _selectedSyncTargets.contains(target);
                  final label = _syncTargetLabel(target);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _selectedSyncTargets.remove(target);
                        } else {
                          _selectedSyncTargets.add(target);
                        }
                      });
                      setLocalState(() {});
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFFFF6B6B).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isChecked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: isChecked
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChecked
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _syncTargetLabel(String table) {
    switch (table) {
      case 'crm_customers':
        return '同时创建客户';
      case 'ledger_entries':
        return '同时写入记账';
      case 'todo_schedules':
        return '同时创建待办';
      default:
        return table;
    }
  }

  /// 用户当前选中的额外同步目标
  final Set<String> _selectedSyncTargets = {};

  /// 获取当前 payload 的所有 pending/confirmed 收件箱列表
  Stream<List<DispatchInboxData>> _watchPendingInboxList() {
    return _repo.watchActiveDispatchInbox(widget.payload.id);
  }

  Future<void> _refreshPreviewAndRequeue() async {
    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final leadText = blocks.isEmpty ? '' : blocks.first.content.trim();
    final preview = leadText.length > 200
        ? '${leadText.substring(0, 200)}...'
        : leadText;
    await _repo.update(widget.payload.id, preview, widget.payload.intentTag);
    if (preview.isEmpty) return;
    _pipeline.enqueue(widget.payload.id);
    if (preview.isEmpty) return;
  }

  Widget _buildFieldsPreview(ThemeData theme, Map<String, dynamic> entities) {
    final displayable = entities.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    if (displayable.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: displayable.map((e) {
          final label = _fieldLabel(e.key);
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                TextSpan(
                  text: e.value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInboxActions(DispatchInboxData inbox) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 已拒绝：编辑后重新规则化
        OutlinedButton.icon(
          onPressed: () => _reOpenAndRetry(inbox),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('编辑后重新规则化', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            visualDensity: VisualDensity.compact,
            foregroundColor: const Color(0xFFFF6B6B),
            side: const BorderSide(color: Color(0xFFFF6B6B)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDispatch(DispatchInboxData inbox) async {
    final mainTarget = _targetTableForIntent(inbox.intentTag);
    // 构建完整目标列表：主目标 + 用户勾选的额外目标
    final targets = <String>[mainTarget];
    targets.addAll(_selectedSyncTargets);

    final results = await _dispatchService.executeDispatch(
      inbox.id,
      syncTargets: targets,
    );

    _selectedSyncTargets.clear();

    if (mounted) {
      final successCount = results.where((r) => r.success).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已分发到 $successCount 个目标模块'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectInbox(DispatchInboxData inbox) async {
    await _dispatchService.rejectDispatch(inbox.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已拒绝分发'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _undoDispatch(DispatchInboxData inbox) async {
    await _dispatchService.undoDispatch(inbox.payloadId);
    if (mounted) {
      // 刷新 dispatchedRef
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已撤销分发'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 拒绝后重新规则化：重置收件箱状态并重新提交处理
  Future<void> _reOpenAndRetry(DispatchInboxData inbox) async {
    await _dispatchService.reopenInbox(inbox.id);
    _pipeline.enqueue(inbox.payloadId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已重新提交规则化处理'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 编辑已确认收件箱的数据（提示用户先撤销分发）
  Future<void> _editInboxData(DispatchInboxData inbox) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑已确认数据'),
        content: const Text('此记录已确认分发。编辑字段后需撤销分发并重新规则化。\n\n是否继续编辑？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('继续编辑', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请直接点击字段进行编辑，编辑完成后可撤销分发并重新规则化'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _regenerateDispatch(DispatchInboxData inbox) async {
    await _dispatchService.rejectDispatch(inbox.id);
    await _repo.resetToSyncedLocal(inbox.payloadId);
    _pipeline.enqueue(inbox.payloadId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已重新提交处理'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, dynamic> _parseEntities(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _fieldLabel(String key) {
    const labels = {
      'person_name': '客户名',
      'company': '公司',
      'contact': '联系方式',
      'amount': '金额',
      'ledger_category': '分类',
      'type': '收支',
      'title': '标题',
      'priority': '优先级',
      'notes': '备注',
      'description': '描述',
      'due_date': '截止日期',
    };
    return labels[key] ?? key;
  }

  Color _intentColor(String tag) {
    switch (tag) {
      case 'CRM':
        return const Color(0xFF4ECDC4);
      case 'LEDGER':
        return const Color(0xFFFF6B6B);
      case 'TODO':
        return const Color(0xFF45B7D1);
      default:
        return const Color(0xFF888888);
    }
  }

  IconData _intentIcon(String tag) {
    switch (tag) {
      case 'CRM':
        return Icons.person_outline;
      case 'LEDGER':
        return Icons.account_balance_wallet_outlined;
      case 'TODO':
        return Icons.check_circle_outline;
      default:
        return Icons.push_pin_outlined;
    }
  }

  static const Map<String, String> _tagLabels = {
    'NOTE': '普通笔记',
    'TODO': '待办清单',
    'CRM': '客户关系',
    'LEDGER': '记账',
    'INVENTORY': '库存管理',
    'HABIT': '习惯打卡',
  };

  void _showArchiveSubMenu(bool isDark) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 100, 1000, 200),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      items: _tagLabels.entries.map((entry) {
        final isCurrent = widget.payload.intentTag == entry.key;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                  ),
                ),
              Text(entry.value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    ).then((selectedTag) {
      if (selectedTag != null && mounted) {
        _repo.update(widget.payload.id, widget.payload.rawText, selectedTag);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已归档到 ${_tagLabels[selectedTag]}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// v16: @ 模板选择器回调 — 用户通过 @ 选择了规则化模板后执行
  Future<void> _onRuleTemplateSelected(AiTemplate template) async {
    // 显示加载状态
    setState(() => _isAiWorking = true);

    try {
      // 收集内容块文本
      final blocks = await _repo.watchBlocks(widget.payload.id).first;
      final contentText = blocks.isEmpty
          ? widget.payload.rawText
          : blocks.map((b) => b.content).join('\n---\n');

      if (contentText.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无内容可进行规则化'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 调用 AI 执行模板的 prompt
      final response = await _ai.chat(
        template.prompt,
        '请根据以下内容提取结构化信息：\n\n$contentText',
      );

      // 解析 AI 返回的 JSON
      Map<String, dynamic> extracted;
      try {
        String jsonStr = response.trim();
        final jsonMatch = RegExp(
          r'```(?:json)?\s*\n?([\s\S]*?)\n?```',
        ).firstMatch(jsonStr);
        if (jsonMatch != null) {
          jsonStr = jsonMatch.group(1)!.trim();
        }
        extracted = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        extracted = {'description': response};
      }

      // 推断意图标签
      final intentTag = _inferIntentFromTemplate(template.name, extracted);

      // 创建或更新收件箱
      final routingResult = RoutingResult(
        intentTag: intentTag,
        entities: extracted,
        isEphemeral: false,
      );

      await _dispatchService.stageForReview(widget.payload.id, routingResult);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('规则化完成，已送入收件箱'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('规则化失败：${e.toString()}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiWorking = false);
    }
  }

  /// 从模板名称推断意图标签
  String _inferIntentFromTemplate(
    String templateName,
    Map<String, dynamic> entities,
  ) {
    final lower = templateName.toLowerCase();
    if (lower.contains('客户') || lower.contains('crm') || lower.contains('联系人'))
      return 'CRM';
    if (lower.contains('记账') ||
        lower.contains('账单') ||
        lower.contains('ledger') ||
        lower.contains('花费'))
      return 'LEDGER';
    if (lower.contains('待办') ||
        lower.contains('任务') ||
        lower.contains('todo') ||
        lower.contains('计划'))
      return 'TODO';
    // 从 entities 中推断
    if (entities.containsKey('person_name') || entities.containsKey('company'))
      return 'CRM';
    if (entities.containsKey('amount') ||
        entities.containsKey('ledger_category'))
      return 'LEDGER';
    if (entities.containsKey('title') || entities.containsKey('priority'))
      return 'TODO';
    return 'NOTE';
  }

  Future<void> _showExportSheet(bool isDark) async {
    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final exportContent = blocks.isEmpty
        ? widget.payload.rawText
        : blocks.map((b) => b.content).join('\n\n---\n\n');

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportBottomSheet(content: exportContent),
    );
  }

  void _copyBlockContent(ContentBlock block) {
    Clipboard.setData(ClipboardData(text: block.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportBlockContent(ContentBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportBottomSheet(content: block.content),
    );
  }

  @override
  void dispose() {
    _statusBannerTimer?.cancel();
    _aiInputController.dispose();
    _aiInputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== 内容块操作 ====================

  Future<void> _openBlockEditor({int? blockId}) async {
    final result = await Navigator.push<BlockEditResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const FullBlockEditor(),
      ),
    );

    if (result != null &&
        (result.content.isNotEmpty || result.mediaPaths.isNotEmpty)) {
      await _repo.addBlock(
        widget.payload.id,
        result.blockType,
        result.content,
        result.mediaPaths,
      );
      await _refreshPreviewAndRequeue();
    }
  }

  void _deleteBlock(ContentBlock block) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除此内容块'),
        content: Text(
          '确定删除此块？\n"${block.content.length > 40 ? '${block.content.substring(0, 40)}...' : block.content}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _repo.removeBlock(block.id);
      await _refreshPreviewAndRequeue();
    }
  }

  void _polishBlock(ContentBlock block) async {
    setState(() {
      _isAiWorking = true;
      _activeAiAction = '润色中...';
    });
    final polished = await _ai.polishText(block.content);
    if (mounted) {
      if (!polished.startsWith('[AI离线]')) {
        await _repo.updateBlockContent(
          block.id,
          polished,
          _parseMediaPaths(block.mediaPaths),
        );
        await _repo.markBlockPolished(block.id);
        await _refreshPreviewAndRequeue();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 暂不可用，已标记待处理'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _isAiWorking = false;
        _activeAiAction = '';
      });
    }
  }

  // ==================== AI 对话 ====================

  Future<void> _sendAiMessage() async {
    final text = _aiInputController.text.trim();
    if (text.isEmpty) return;
    _aiInputController.clear();
    _aiInputFocus.unfocus();
    await _sendPromptToAi(text);
  }

  /// 核心发送逻辑：模板网格、@ 选择、输入框发送共用
  Future<void> _sendPromptToAi(String prompt) async {
    // 编辑模式：先删除旧对话
    if (_editingUserConvId != null) {
      await _repo.deleteConversation(_editingUserConvId!);
      if (_editingPairedAiConvId != null) {
        await _repo.deleteConversation(_editingPairedAiConvId!);
      }
      _editingUserConvId = null;
      _editingPairedAiConvId = null;
    }

    await _repo.addConversation(widget.payload.id, 'user', prompt);
    setState(() => _isAiWorking = true);

    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final contextText = blocks.map((b) => b.content).join('\n---\n');

    final response = await _ai.chat(
      '用户正在查看一条笔记，内容如下：\n$contextText\n\n请根据用户的问题提供帮助。简洁回答。',
      prompt,
    );

    if (mounted) {
      await _repo.addConversation(widget.payload.id, 'assistant', response);
      setState(() => _isAiWorking = false);
      _scrollToBottom();
    }
  }

  /// 处理对话模板选择：直接发送给AI，结果以内容块展示
  Future<void> _handleChatTemplateSelected(AiTemplate template) async {
    setState(() => _isAiWorking = true);

    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final contextText = blocks.map((b) => b.content).join('\n---\n');

    final response = await _ai.chat(
      '用户正在查看一条笔记，内容如下：\n$contextText\n\n请根据用户的问题提供帮助。简洁回答。',
      template.prompt,
    );

    if (mounted && response.isNotEmpty) {
      await _repo.addBlock(widget.payload.id, 'text', response, [], 'ai');
      setState(() => _isAiWorking = false);
    } else if (mounted) {
      setState(() => _isAiWorking = false);
    }
  }

  /// 平滑滚动到页面底部
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 处理附件选择：将选中的文件保存为内容块
  void _handleAttachmentPicked(List<String> paths) async {
    for (final path in paths) {
      // 根据扩展名判断内容块类型
      final ext = path.split('.').last.toLowerCase();
      String blockType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'webp':
        case 'bmp':
          blockType = 'image';
          break;
        case 'mp3':
        case 'wav':
        case 'aac':
        case 'm4a':
        case 'ogg':
          blockType = 'voice';
          break;
        case 'mp4':
        case 'mov':
        case 'avi':
        case 'mkv':
          blockType = 'video';
          break;
        case 'pdf':
        case 'doc':
        case 'docx':
        case 'txt':
        case 'md':
          blockType = 'file';
          break;
        default:
          blockType = 'file';
      }
      await _repo.addBlock(widget.payload.id, blockType, '', [path], 'manual');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加 ${paths.length} 个附件'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 查找用户消息配对的 AI 回复 ID
  Future<int?> _findPairedAiResponse(int userConvId) async {
    final conversations = await _conversationsStream.first;
    final userIndex = conversations.indexWhere((c) => c.id == userConvId);
    if (userIndex < 0 || userIndex >= conversations.length - 1) return null;
    final next = conversations[userIndex + 1];
    return next.role == 'assistant' ? next.id : null;
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportAiContent(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportBottomSheet(content: content),
    );
  }

  /// 用户消息长按菜单
  void _showUserMessageMenu(AiConversation conv) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                '删除',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (result == 'edit') {
      _aiInputController.text = conv.content;
      _editingUserConvId = conv.id;
      _editingPairedAiConvId = await _findPairedAiResponse(conv.id);
      _aiInputFocus.requestFocus();
    } else if (result == 'copy') {
      _copyText(conv.content);
    } else if (result == 'delete') {
      _confirmDeleteConversation(conv);
    }
  }

  /// 确认删除用户消息（含配对的 AI 回复）
  void _confirmDeleteConversation(AiConversation userConv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定删除此提问及 AI 回复？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deleteConversation(userConv.id);
      final pairedAiId = await _findPairedAiResponse(userConv.id);
      if (pairedAiId != null) {
        await _repo.deleteConversation(pairedAiId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// AI 回复"更多"菜单
  void _showAiMoreMenu(AiConversation conv) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('重新生成'),
              onTap: () => Navigator.pop(ctx, 'regenerate'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                '删除',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (result == 'regenerate') {
      await _regenerateAiResponse(conv);
    } else if (result == 'delete') {
      await _repo.deleteConversation(conv.id);
    }
  }

  /// 重新生成 AI 回复
  Future<void> _regenerateAiResponse(AiConversation aiConv) async {
    final conversations = await _conversationsStream.first;
    final aiIndex = conversations.indexWhere((c) => c.id == aiConv.id);
    if (aiIndex <= 0) return;

    final userConv = conversations[aiIndex - 1];
    if (userConv.role != 'user') return;

    await _repo.deleteConversation(aiConv.id);
    setState(() => _isAiWorking = true);

    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final contextText = blocks.map((b) => b.content).join('\n---\n');

    final response = await _ai.chat(
      '用户正在查看一条笔记，内容如下：\n$contextText\n\n请根据用户的问题提供帮助。简洁回答。',
      userConv.content,
    );

    if (mounted) {
      await _repo.addConversation(widget.payload.id, 'assistant', response);
      setState(() => _isAiWorking = false);
    }
  }

  // ==================== 构建内容块 ====================

  Widget _buildContentBlock(ContentBlock block, ThemeData theme, bool isDark) {
    final mediaPaths = _parseMediaPaths(block.mediaPaths);
    final isVoice = block.sourceType == 'voice';
    final dateStr = _formatBlockTime(block.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 块头部：来源图标 + 时间 + 操作按钮
          Row(
            children: [
              Icon(
                isVoice ? Icons.mic_rounded : Icons.text_snippet_rounded,
                size: 14,
                color: isVoice
                    ? Colors.orangeAccent.withValues(alpha: 0.7)
                    : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              _BlockIconButton(
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: () => _openBlockEditorForEdit(block),
              ),
              if (isVoice)
                _BlockIconButton(
                  icon: Icons.play_arrow_rounded,
                  label: '播放',
                  onTap: () {},
                ),
              _BlockIconButton(
                icon: Icons.delete_outline_rounded,
                label: null,
                color: Colors.grey[500],
                onTap: () => _deleteBlock(block),
              ),
            ],
          ),
          if (block.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectionArea(child: _renderMarkdownPreview(block.content, isDark)),
          ],
          // 媒体预览
          if (mediaPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mediaPaths.map((path) {
                final isImage =
                    path.toLowerCase().endsWith('.jpg') ||
                    path.toLowerCase().endsWith('.png') ||
                    path.toLowerCase().endsWith('.jpeg');
                return GestureDetector(
                  onTap: isImage ? () => _showFullScreenImage(path) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: (MediaQuery.of(context).size.width - 84) / 3,
                      height: 90,
                      child: isImage
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F0F0),
                              child: const Center(
                                child: Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // ===== 标签 + AI 润色 + 复制导出（同行） =====
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧：AI润色 + 标签
              Expanded(child: _buildBlockBottomLeft(block, theme, isDark)),
              const SizedBox(width: 24),
              // 右侧：复制 + 导出
              _BlockIconButton(
                icon: Icons.copy_rounded,
                label: '复制',
                onTap: () => _copyBlockContent(block),
              ),
              const SizedBox(width: 4),
              _BlockIconButton(
                icon: Icons.ios_share_rounded,
                label: '导出',
                onTap: () => _exportBlockContent(block),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openBlockEditorForEdit(ContentBlock block) async {
    final result = await Navigator.push<BlockEditResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullBlockEditor(
          initialContent: block.content,
          initialMediaPaths: _parseMediaPaths(block.mediaPaths),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      await _repo.updateBlockContent(
        block.id,
        result.content,
        result.mediaPaths,
      );
      await _refreshPreviewAndRequeue();
    }
  }

  // ==================== 块底栏（AI润色 + 标签 + 添加标签） ====================

  Widget _buildBlockBottomLeft(
    ContentBlock block,
    ThemeData theme,
    bool isDark,
  ) {
    final tags = _parseTags(block.tags);
    final isExpanded = _expandedTags.contains(block.id);
    final hasTags = tags.isNotEmpty;

    // 估算单个标签的大致宽度：区分 CJK 宽字符与拉丁窄字符
    double estimateTagWidth(String tag) {
      final display = tag.startsWith('#') ? tag : '#$tag';
      double textWidth = 0;
      for (final codeUnit in display.codeUnits) {
        textWidth += codeUnit > 0x7F ? 11 : 7;
      }
      return (12 + textWidth + 4) * 1.08;
    }

    bool calcNeedsExpand(double availableWidth) {
      final totalWidth = tags.fold<double>(
        0,
        (sum, t) => sum + estimateTagWidth(t),
      );
      return totalWidth > availableWidth;
    }

    Widget buildTagChip(String tag, {VoidCallback? onToggleExpand}) {
      final displayTag = tag.startsWith('#') ? tag : '#$tag';
      final colorPair = _tagPalette[tag.hashCode.abs() % _tagPalette.length];
      return GestureDetector(
        onTap: onToggleExpand,
        onLongPress: () {
          HapticFeedback.lightImpact();
          _showBlockTagDialog(block, tags);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorPair.bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            displayTag,
            style: TextStyle(
              color: colorPair.fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    Widget buildTagRow(double availableWidth) {
      final tagAreaWidth = availableWidth - 20 - 32;
      final needsExpand = hasTags && calcNeedsExpand(tagAreaWidth);
      final showExpandBtn = needsExpand;
      final actualWidth = showExpandBtn ? tagAreaWidth - 20 : tagAreaWidth;
      final reallyNeedsExpand = hasTags && calcNeedsExpand(actualWidth);
      const collapsedHeight = 22.0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AI 润色按钮
          if (!block.aiPolished)
            GestureDetector(
              onTap: _isAiWorking ? null : () => _polishBlock(block),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.auto_fix_high_rounded,
                  size: 14,
                  color: _isAiWorking ? Colors.grey[500] : Colors.amber,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: Colors.green[400],
              ),
            ),
          // 标签区域
          Flexible(
            child: ConstrainedBox(
              constraints: (!isExpanded && reallyNeedsExpand)
                  ? const BoxConstraints(maxHeight: collapsedHeight)
                  : const BoxConstraints(),
              child: hasTags
                  ? Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      clipBehavior: Clip.antiAlias,
                      children: tags
                          .map(
                            (tag) => buildTagChip(
                              tag,
                              onToggleExpand: reallyNeedsExpand
                                  ? () => setState(() {
                                      if (isExpanded) {
                                        _expandedTags.remove(block.id);
                                      } else {
                                        _expandedTags.add(block.id);
                                      }
                                    })
                                  : null,
                            ),
                          )
                          .toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // 展开/折叠按钮（仅多行时显示）
          if (showExpandBtn)
            GestureDetector(
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedTags.remove(block.id);
                } else {
                  _expandedTags.add(block.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
          // 添加标签按钮
          ActionChip(
            label: const Text('+', style: TextStyle(fontSize: 11)),
            onPressed: () => _showBlockTagDialog(block, tags),
            backgroundColor: isDark
                ? const Color(0xFF262626)
                : const Color(0xFFF1F3F5),
            side: BorderSide.none,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        ],
      );
    }

    // 计算标签可用宽度：
    // 屏幕宽 - 页面padding(16*2) - 块padding(14*2) - 右侧gap(24) - 复制(~20) - gap(4) - 导出(~20)
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32 - 28 - 24 - 20 - 4 - 20;

    return buildTagRow(availableWidth);
  }

  void _showBlockTagDialog(ContentBlock block, List<String> currentTags) {
    final controller = TextEditingController(text: '#');
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (ctx) => _TagDialog(
        controller: controller,
        currentTags: currentTags,
        repo: _repo,
        onConfirm: (List<String> finalTags) {
          _repo.updateBlockTags(block.id, finalTags);
        },
      ),
    );
  }

  // ==================== 主构建 ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 46,
        centerTitle: true,
        title: Text(
          _currentTitle.isEmpty ? '未命名' : _currentTitle,
          style: AppTypography.h3.copyWith(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            onPressed: () => _showExportSheet(isDark),
            tooltip: '导出',
          ),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit_title',
                child: Text('修改标题', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Text('归档', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'hide',
                child: Text('隐藏', style: TextStyle(fontSize: 13)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  '删除此条',
                  style: TextStyle(fontSize: 13, color: Colors.redAccent),
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'edit_title') {
                _showEditTitleDialog(isDark);
              } else if (val == 'archive') {
                _showArchiveSubMenu(isDark);
              } else if (val == 'hide') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('功能开发中，敬请期待'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (val == 'delete') {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _confirmDelete(),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 处理状态横幅
          if (_showStatusBanner) _buildStatusBanner(theme, isDark),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 内容块区域 =====
                  StreamBuilder<List<ContentBlock>>(
                    stream: _blocksStream,
                    builder: (context, snapshot) {
                      final blocks = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (blocks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '内容记录',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ...blocks.map(
                            (block) => _buildContentBlock(block, theme, isDark),
                          ),
                          const SizedBox(height: 6),
                          _buildAddBlockButton(isDark, theme),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSupplementaryArea(theme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StreamBuilder<List<AiTemplate>>(
        stream: _templatesStream,
        builder: (context, snapshot) {
          final allTemplates = snapshot.data ?? [];
          return AiChatInputBox(
            textController: _aiInputController,
            focusNode: _aiInputFocus,
            isAiWorking: _isAiWorking,
            selectedModel: _selectedModel,
            templates: allTemplates,
            onSend: _sendAiMessage,
            onModelChanged: (model) {
              _ai.setModel(model.id);
              setState(() => _selectedModel = model.id);
            },
            onAttachmentPicked: _handleAttachmentPicked,
            onTemplateManage: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateManagementPage()),
            ),
            onRuleTemplateSelected: (template) =>
                _onRuleTemplateSelected(template),
            onChatTemplateSelected: (template) =>
                _handleChatTemplateSelected(template),
          );
        },
      ),
    );
  }

  // ==================== 追加按钮 ====================

  Widget _buildAddBlockButton(bool isDark, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: GestureDetector(
          onTap: _openBlockEditor,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '追加内容',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 处理状态横幅 ====================

  Widget _buildStatusBanner(ThemeData theme, bool isDark) {
    final status = ProcessingStatus.fromString(widget.payload.processingStatus);

    // synced_local 和 dispatched 不显示横幅
    if (status == ProcessingStatus.syncedLocal ||
        status == ProcessingStatus.dispatched) {
      // dispatched 时如果有衰减标记，显示衰减提示
      if (widget.payload.isEphemeral && status == ProcessingStatus.dispatched) {
        return _buildEphemeralBanner(isDark);
      }
      return const SizedBox.shrink();
    }

    IconData icon;
    String text;
    Color color;

    switch (status) {
      case ProcessingStatus.vectorChecking:
        icon = Icons.search_rounded;
        text = '正在查重对比...';
        color = const Color(0xFF42A5F5);
        break;
      case ProcessingStatus.aiRouting:
        icon = Icons.auto_awesome_rounded;
        text = 'AI 正在分析归类...';
        color = Colors.amber;
        break;
      case ProcessingStatus.textCleaned:
        icon = Icons.manage_search_rounded;
        text = '文本已清洗，等待 AI 分析...';
        color = const Color(0xFF42A5F5);
        break;
      case ProcessingStatus.dispatching:
        icon = Icons.call_split_rounded;
        text = '正在分发到业务表...';
        color = const Color(0xFF66BB6A);
        break;
      case ProcessingStatus.pendingReview:
        icon = Icons.inbox_rounded;
        text = '已进入收件箱，等待你确认分发...';
        color = const Color(0xFF7E57C2);
        break;
      case ProcessingStatus.failedRetry:
        icon = Icons.hourglass_empty_rounded;
        text = '处理暂停，等待网络恢复...';
        color = const Color(0xFFFFA726);
        break;
      case ProcessingStatus.offlineSaved:
        icon = Icons.cloud_off_rounded;
        text = '离线已保存，等待网络恢复...';
        color = const Color(0xFFFFA726);
        break;
      case ProcessingStatus.decayed:
        icon = Icons.auto_delete_rounded;
        text = '内容已衰减折叠';
        color = const Color(0xFF90A4AE);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildEphemeralBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withValues(alpha: isDark ? 0.15 : 0.08),
      child: Row(
        children: [
          const Icon(Icons.auto_delete_rounded, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '此内容将在 48 小时后自动归档',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ==================== 分发链接 ====================

  Widget _buildDispatchedLink(bool isDark) {
    final ref = widget.payload.dispatchedRef!;
    final parts = ref.split(':');
    if (parts.length != 2) return const SizedBox.shrink();

    final table = parts[0];
    final id = parts[1];
    String label;

    switch (table) {
      case 'crm_customers':
        label = '查看关联客户';
        break;
      case 'ledger_entries':
        label = '查看记账流水';
        break;
      case 'todo_schedules':
        label = '查看待办日程';
        break;
      default:
        label = '查看关联记录';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label ($table #$id) — 详情页开发中'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              await _repo.clearDispatchedRef(widget.payload.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已撤销分发'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.undo_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 收件箱卡片内的已分发链接行（仅显示链接信息，不含撤销按钮）
  Widget _buildInboxDispatchedLinkRow(String dispatchedRef) {
    final parts = dispatchedRef.split(':');
    if (parts.length != 2) return const SizedBox.shrink();

    final table = parts[0];
    String label;
    switch (table) {
      case 'crm_customers':
        label = '查看关联客户';
        break;
      case 'ledger_entries':
        label = '查看记账流水';
        break;
      case 'todo_schedules':
        label = '查看待办日程';
        break;
      default:
        label = '查看关联记录';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 14, color: Colors.blue[400]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[400],
              decoration: TextDecoration.underline,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[500]),
        ],
      ),
    );
  }

  // ==================== 补充区域（AI 交流 + 收件箱） ====================

  Widget _buildSupplementaryArea(ThemeData theme, bool isDark) {
    return StreamBuilder<List<DispatchInboxData>>(
      stream: _watchPendingInboxList(),
      builder: (context, inboxSnapshot) {
        final inboxItems = inboxSnapshot.data ?? [];

        return StreamBuilder<List<AiConversation>>(
          stream: _conversationsStream,
          builder: (context, convSnapshot) {
            final conversations = convSnapshot.data ?? [];
            final hasConversations = conversations.isNotEmpty;

            // 合并收件箱和对话并按 createdAt 升序排列
            final merged = <Object>[...inboxItems, ...conversations];
            merged.sort((a, b) {
              final aTime = a is DispatchInboxData
                  ? a.createdAt
                  : (a as AiConversation).createdAt;
              final bTime = b is DispatchInboxData
                  ? b.createdAt
                  : (b as AiConversation).createdAt;
              return aTime.compareTo(bTime);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "AI 交流" 标题行：仅在有对话时显示
                if (hasConversations) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI 交流',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // 对话为空时显示空状态提示 + 模板网格
                if (conversations.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '所有内容块已作为上下文提供给 AI，开始提问吧',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  if (!_hasActiveInbox) _buildTemplateGrid(isDark),
                ],

                // 合并列表
                ...merged.map((item) {
                  if (item is DispatchInboxData) {
                    return _buildDispatchInboxCard(
                      theme,
                      isDark,
                      item,
                      dispatchedRef: widget.payload.dispatchedRef,
                    );
                  } else {
                    return _buildConversationBubble(
                      item as AiConversation,
                      theme,
                      isDark,
                    );
                  }
                }),

                // 加载指示器
                if (_isAiWorking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '思考中...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== AI 对话区域 ====================

  Widget _buildAiSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 区域标题
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'AI 交流',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 对话列表
        StreamBuilder<List<AiConversation>>(
          stream: _conversationsStream,
          builder: (context, snapshot) {
            final conversations = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 空状态 + 模板网格
                if (conversations.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '所有内容块已作为上下文提供给 AI，开始提问吧',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  if (!_hasActiveInbox) _buildTemplateGrid(isDark),
                ],

                // 对话列表（inbox + conversations 合并区）
                ...conversations.map(
                  (conv) => _buildConversationBubble(conv, theme, isDark),
                ),

                // 加载指示器
                if (_isAiWorking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '思考中...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationBubble(
    AiConversation conv,
    ThemeData theme,
    bool isDark,
  ) {
    final isUser = conv.role == 'user';
    const bubbleMaxWidth = 0.75;

    final bubbleRow = Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(
                  0xFFFF6B6B,
                ).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * bubbleMaxWidth,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF6B6B)
                    : isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: isUser
                  ? Text(
                      conv.content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : SelectableText(
                      conv.content,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? Colors.grey[200]
                            : const Color(0xFF333333),
                      ),
                    ),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(
                  0xFFFF6B6B,
                ).withValues(alpha: 0.15),
                child: const Text(
                  '我',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // AI 消息：气泡行 + 底部按钮行
    if (!isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubbleRow,
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 2),
            child: Row(
              children: [
                _BlockIconButton(
                  icon: Icons.copy_outlined,
                  onTap: () => _copyText(conv.content),
                ),
                _BlockIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _exportAiContent(conv.content),
                ),
                _BlockIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () => _showAiMoreMenu(conv),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 用户消息：包裹长按手势
    return GestureDetector(
      onLongPress: () => _showUserMessageMenu(conv),
      child: bubbleRow,
    );
  }

  /// 模板网格：无对话时在 AI 区域展示
  Widget _buildTemplateGrid(bool isDark) {
    return StreamBuilder<List<AiTemplate>>(
      stream: _templatesStream,
      builder: (context, snapshot) {
        final templates = snapshot.data ?? [];
        if (templates.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((t) {
              return GestureDetector(
                onTap: () => _sendPromptToAi(t.prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE0E0E0),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ==================== 工具方法 ====================

  void _showFullScreenImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  /// 渲染 Markdown 预览（复用自 FullBlockEditor 的预览逻辑）
  Widget _renderMarkdownPreview(String text, bool isDark) {
    final lines = text.split('\n');
    final spans = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trimRight() == '---' || line.trimRight() == '***') {
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              height: 1,
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('# ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 3),
            child: Text(
              line.substring(2),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              line.substring(3),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
        continue;
      }
      if (line.startsWith('### ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 2),
            child: Text(
              line.substring(4),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isDark ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('> ')) {
        spans.add(
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                  width: 3,
                ),
              ),
            ),
            child: _parseInlineMD(
              line.substring(2),
              TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              isDark,
            ),
          ),
        );
        continue;
      }

      if (line.trimLeft().startsWith('- ')) {
        final indent = line.length - line.trimLeft().length;
        final content = line.trimLeft().substring(2);
        spans.add(
          Padding(
            padding: EdgeInsets.only(left: indent + 14.0, top: 1, bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 13, color: Color(0xFFFF6B6B)),
                ),
                Expanded(
                  child: _parseInlineMD(
                    content,
                    TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color(0xFF444444),
                    ),
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      final olMatch = RegExp(r'^\d+\.\s').firstMatch(line);
      if (olMatch != null) {
        final content = line.substring(olMatch.end);
        spans.add(
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 1, bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.substring(0, olMatch.end - 2)}. ',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: _parseInlineMD(
                    content,
                    TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color(0xFF444444),
                    ),
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (line.trim().isEmpty) {
        spans.add(const SizedBox(height: 6));
        continue;
      }

      spans.add(
        Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 3),
          child: _parseInlineMD(
            line,
            TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.grey[200] : const Color(0xFF333333),
            ),
            isDark,
          ),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(
        '暂无内容',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spans,
    );
  }

  /// 解析行内 Markdown：**粗体**、_斜体_、`代码`
  Widget _parseInlineMD(String text, TextStyle baseStyle, bool isDark) {
    final segments = <InlineSpan>[];
    final regex = RegExp(r'(\*\*(.+?)\*\*|_(.+?)_|`(.+?)`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      if (match.group(2) != null) {
        segments.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(3) != null) {
        segments.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(4) != null) {
        segments.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: (baseStyle.fontSize ?? 13) - 1,
              backgroundColor: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF0F0F0),
              color: const Color(0xFFFF6B6B),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return Text.rich(TextSpan(children: segments));
  }

  List<String> _parseMediaPaths(String mediaPathsJson) {
    try {
      final decoded = jsonDecode(mediaPathsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  List<String> _parseTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  String _formatBlockTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 6) return '${diff.inHours}小时前';
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday)
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 标签管理弹窗（增删改查集中操作）
class _TagDialog extends StatefulWidget {
  final TextEditingController controller;
  final List<String> currentTags;
  final IdeaRepository repo;
  final void Function(List<String> finalTags) onConfirm;

  const _TagDialog({
    required this.controller,
    required this.currentTags,
    required this.repo,
    required this.onConfirm,
  });

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  List<String> _allTags = [];
  bool _loaded = false;

  /// 当前活跃的标签状态：true = 彩色保留，false = 灰色删除
  late Map<String, bool> _activeTagStates;

  @override
  void initState() {
    super.initState();
    _activeTagStates = {for (final t in widget.currentTags) t: true};
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await widget.repo.getAllBlockTags();
    if (mounted) {
      setState(() {
        _allTags = tags;
        _loaded = true;
      });
    }
  }

  List<String> get _activeTags => _activeTagStates.keys.toList();

  /// 历史标签中尚未使用的
  List<String> get _inactiveHistoryTags =>
      _allTags.where((t) => !_activeTagStates.containsKey(t)).toList();

  /// 点击已使用标签：切换彩色/灰色状态
  void _toggleActiveTag(String tag) {
    setState(() {
      _activeTagStates[tag] = !_activeTagStates[tag]!;
    });
  }

  /// 点击历史标签：添加到活跃标签
  void _addFromHistory(String tag) {
    if (!_activeTagStates.containsKey(tag)) {
      setState(() {
        _activeTagStates[tag] = true;
      });
    }
  }

  void _confirmSave() {
    // 保留彩色状态的标签
    final keptTags = _activeTagStates.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // 解析输入框中的新标签
    final inputVal = widget.controller.text.trim();
    if (inputVal.isNotEmpty && inputVal != '#') {
      final parts = inputVal
          .split('#')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      for (final part in parts) {
        final cleanTag = '#$part';
        if (!keptTags.contains(cleanTag)) {
          keptTags.add(cleanTag);
        }
      }
    }

    widget.onConfirm(keptTags);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActive = _activeTags.isNotEmpty;
    final historyTags = _inactiveHistoryTags;

    return AlertDialog(
      title: const Text('管理标签'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入框
            TextField(
              controller: widget.controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '用 # 分隔可一次添加多个',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFF1F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _confirmSave(),
            ),
            // 已使用标签区域
            if (hasActive) ...[
              const SizedBox(height: 12),
              Text(
                '已使用标签',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _activeTags.map((tag) {
                  final isColored = _activeTagStates[tag] ?? true;
                  final colorPair =
                      _tagPalette[tag.hashCode.abs() % _tagPalette.length];
                  return GestureDetector(
                    onTap: () => _toggleActiveTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isColored
                            ? colorPair.bg
                            : (isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isColored
                              ? colorPair.bg
                              : Colors.grey.shade400,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: isColored ? colorPair.fg : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // 历史标签区域（未使用的）
            if (_loaded && historyTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '历史标签',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: historyTags.map((tag) {
                  final colorPair =
                      _tagPalette[tag.hashCode.abs() % _tagPalette.length];
                  return GestureDetector(
                    onTap: () => _addFromHistory(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorPair.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorPair.bg, width: 0.5),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorPair.fg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // 空状态
            if (_loaded && _allTags.isEmpty && !hasActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '暂无历史标签',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _confirmSave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
          ),
          child: const Text('确定', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// 内容块的操作图标按钮
class _BlockIconButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const _BlockIconButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[500]!;
    final effectiveOnTap = onTap;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: effectiveOnTap == null ? Colors.grey[700] : c,
            ),
            if (!isSmallScreen && label != null) ...[
              const SizedBox(width: 2),
              Text(label!, style: TextStyle(fontSize: 10, color: c)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 收件箱可编辑字段列表组件
class _InboxFieldList extends StatelessWidget {
  final Map<String, dynamic> entities;
  final String intentTag;
  final bool isConfirmed;
  final void Function(String key, String value) onFieldEdited;
  final Type fieldLabels; // FieldLabels type
  final Widget? trailingActions;

  const _InboxFieldList({
    required this.entities,
    required this.intentTag,
    required this.isConfirmed,
    required this.onFieldEdited,
    required this.fieldLabels,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 渲染意图对应的全部已知字段（含空值字段）
    final allKeys = FieldLabels.fieldKeys(intentTag);
    if (allKeys.isEmpty) {
      // 兜底：无已知字段时回退到只渲染已有字段
      final displayable = entities.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .toList();
      if (displayable.isEmpty) return const SizedBox.shrink();
      return _buildFieldWrap(displayable, theme, entities);
    }

    // 构建完整字段列表（包含空值）
    final entries = <MapEntry<String, dynamic>>[];
    for (final key in allKeys) {
      final value = entities[key];
      entries.add(MapEntry(key, value));
    }

    return _buildFieldWrap(entries, theme, entities);
  }

  Widget _buildFieldWrap(
    List<MapEntry<String, dynamic>> entries,
    ThemeData theme,
    Map<String, dynamic> entities,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (!isMobile) {
          return _buildPcLayout(entries, theme, entities, trailingActions);
        } else {
          return _buildMobileLayout(
            context,
            entries,
            theme,
            entities,
            trailingActions,
          );
        }
      },
    );
  }

  Widget _buildPcLayout(
    List<MapEntry<String, dynamic>> entries,
    ThemeData theme,
    Map<String, dynamic> entities,
    Widget? trailingActions,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: entries.map((e) {
              final label = FieldLabels.label(intentTag, e.key);
              final hasValue = e.value != null && e.value.toString().isNotEmpty;
              final value = hasValue ? e.value.toString() : '未识别';
              return _InboxFieldChip(
                label: label,
                keyName: e.key,
                value: value,
                isEmpty: !hasValue,
                isConfirmed: isConfirmed,
                onEdit: (newValue) => onFieldEdited(e.key, newValue),
                isMobile: false,
              );
            }).toList(),
          ),
          if (trailingActions != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: trailingActions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<MapEntry<String, dynamic>> entries,
    ThemeData theme,
    Map<String, dynamic> entities,
    Widget? trailingActions,
  ) {
    const maxVisible = 4;
    final displayEntries = entries.take(maxVisible).toList();
    final hasMore = entries.length > maxVisible;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...displayEntries.map((e) {
            final label = FieldLabels.label(intentTag, e.key);
            final hasValue = e.value != null && e.value.toString().isNotEmpty;
            final value = hasValue ? e.value.toString() : '未识别';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _InboxFieldChip(
                label: label,
                keyName: e.key,
                value: value,
                isEmpty: !hasValue,
                isConfirmed: isConfirmed,
                onEdit: (newValue) => onFieldEdited(e.key, newValue),
                isMobile: true,
              ),
            );
          }),
          if (hasMore || trailingActions != null)
            Container(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (hasMore)
                    InkWell(
                      onTap: () {
                        _showAllFieldsSheet(context, entries, theme, entities);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '查看全部 (${entries.length})',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (trailingActions != null) trailingActions!,
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAllFieldsSheet(
    BuildContext context,
    List<MapEntry<String, dynamic>> entries,
    ThemeData theme,
    Map<String, dynamic> entities,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '全部字段',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((e) {
                final label = FieldLabels.label(intentTag, e.key);
                final hasValue =
                    e.value != null && e.value.toString().isNotEmpty;
                final value = hasValue ? e.value.toString() : '未识别';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InboxFieldChip(
                    label: label,
                    keyName: e.key,
                    value: value,
                    isEmpty: !hasValue,
                    isConfirmed: isConfirmed,
                    onEdit: (newValue) => onFieldEdited(e.key, newValue),
                    isMobile: true,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个收件箱字段 Chip，点击可编辑
class _InboxFieldChip extends StatelessWidget {
  final String label;
  final String keyName;
  final String value;
  final bool isEmpty;
  final bool isConfirmed;
  final bool isMobile;
  final void Function(String newValue) onEdit;

  const _InboxFieldChip({
    required this.label,
    required this.keyName,
    required this.value,
    required this.isEmpty,
    required this.isConfirmed,
    required this.onEdit,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMobile) {
      return InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEmpty
                    ? '未识别'
                    : (value.length > 50
                          ? '${value.substring(0, 50)}...'
                          : value),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: isEmpty ? FontStyle.italic : null,
                  color: isEmpty ? Colors.grey : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              isEmpty
                  ? '未识别'
                  : (value.length > 30
                        ? '${value.substring(0, 30)}...'
                        : value),
              style: TextStyle(
                fontSize: 12,
                fontStyle: isEmpty ? FontStyle.italic : null,
                color: isEmpty ? Colors.grey : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: isEmpty ? '' : value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑 $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEmpty ? '补全$label...' : '修改$label',
            filled: true,
            fillColor: isDark
                ? const Color(0xFF262626)
                : const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            onEdit(val.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          if (isEmpty)
            FilledButton(
              onPressed: () {
                onEdit(controller.text.trim());
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
              child: const Text('补全', style: TextStyle(color: Colors.white)),
            )
          else
            FilledButton(
              onPressed: () {
                onEdit(controller.text.trim());
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
              child: const Text('确定', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/ai_engine.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/idea_repository.dart';
import '../widgets/content_block_editor.dart';
import '../widgets/full_block_editor.dart';

class IdeaDetailPage extends StatefulWidget {
  final HubPayload payload;

  const IdeaDetailPage({super.key, required this.payload});

  @override
  State<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends State<IdeaDetailPage> {
  final _repo = getIt<IdeaRepository>();
  final _ai = getIt<AiEngine>();

  final TextEditingController _newTaskController = TextEditingController();
  bool _isEnteringTask = false;

  // AI 对话输入
  final TextEditingController _aiInputController = TextEditingController();
  bool _isAiWorking = false;
  String _activeAiAction = '';

  late String _currentTitle;

  late final Stream<List<ContentBlock>> _blocksStream;
  late final Stream<List<AiConversation>> _conversationsStream;
  late final Stream<List<IdeaTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _blocksStream = _repo.watchBlocks(widget.payload.id);
    _conversationsStream = _repo.watchConversations(widget.payload.id);
    _tasksStream = _repo.watchTasks(widget.payload.id);
    _initContentBlocks();
    _initAiConversations();
    _initTitle();
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
            final cleanTitle =
                firstLine.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
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

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这条闪念吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: Colors.redAccent))),
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
          decoration: const InputDecoration(hintText: '输入标题'),
          maxLength: 100,
          onSubmitted: (val) {
            final newTitle = val.trim();
            _currentTitle = newTitle.isEmpty ? '' : newTitle;
            _repo.updateTitle(
                widget.payload.id, newTitle.isEmpty ? null : newTitle);
            setState(() {});
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              _currentTitle = newTitle.isEmpty ? '' : newTitle;
              _repo.updateTitle(
                  widget.payload.id, newTitle.isEmpty ? null : newTitle);
              setState(() {});
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _aiInputController.dispose();
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
      // 不再覆盖摘要 — 保持首块生成的摘要不变
    }
  }

  void _deleteBlock(ContentBlock block) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除此内容块'),
        content: Text(
            '确定删除此块？\n"${block.content.length > 40 ? '${block.content.substring(0, 40)}...' : block.content}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _repo.removeBlock(block.id);
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
            block.id, polished, _parseMediaPaths(block.mediaPaths));
        await _repo.markBlockPolished(block.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('AI 暂不可用，已标记待处理'), duration: Duration(seconds: 2)),
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

    // 保存用户消息
    await _repo.addConversation(widget.payload.id, 'user', text);
    _aiInputController.clear();
    setState(() => _isAiWorking = true);

    // 构建上下文：所有内容块的内容
    final blocks = await _repo.watchBlocks(widget.payload.id).first;
    final contextText = blocks.map((b) => b.content).join('\n---\n');

    // 发送 AI 请求
    final response = await _ai.chat(
      '用户正在查看一条笔记，内容如下：\n$contextText\n\n请根据用户的问题提供帮助。简洁回答。',
      text,
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

    return GestureDetector(
      onTap: () => _openBlockEditorForEdit(block),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBFBFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.06), width: 1),
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
                Text(dateStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const Spacer(),
                if (isVoice)
                  _BlockIconButton(
                    icon: Icons.play_arrow_rounded,
                    label: '播放',
                    onTap: () {},
                  ),
                if (!block.aiPolished)
                  _BlockIconButton(
                    icon: Icons.auto_fix_high_rounded,
                    label: '润色',
                    color: Colors.amber,
                    onTap: _isAiWorking ? null : () => _polishBlock(block),
                  ),
                if (block.aiPolished)
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Colors.green[400]),
                const SizedBox(width: 4),
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
              Text(
                block.content,
                style: const TextStyle(fontSize: 14, height: 1.55),
              ),
            ],
            // 媒体预览
            if (mediaPaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mediaPaths.take(6).map((path) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: (MediaQuery.of(context).size.width - 84) / 3,
                      height: 90,
                      child: path.toLowerCase().endsWith('.jpg') ||
                              path.toLowerCase().endsWith('.png') ||
                              path.toLowerCase().endsWith('.jpeg')
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F0F0),
                              child: const Center(
                                  child: Icon(Icons.insert_drive_file,
                                      color: Colors.grey, size: 24)),
                            ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // ===== 每块独立标签区域 =====
            _buildBlockTagSection(block, theme, isDark),
          ],
        ),
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
          block.id, result.content, result.mediaPaths);
      // 仅当编辑的是首块（sortOrder 最小）时同步更新卡片摘要
      final blocks = await _repo.watchBlocks(widget.payload.id).first;
      if (blocks.isNotEmpty && blocks.first.id == block.id) {
        final preview = result.content.length > 200
            ? '${result.content.substring(0, 200)}...'
            : result.content;
        _repo.update(widget.payload.id, preview, widget.payload.intentTag);
      }
    }
  }

  // ==================== 块内标签 ====================

  Widget _buildBlockTagSection(
      ContentBlock block, ThemeData theme, bool isDark) {
    final tags = _parseTags(block.tags);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...tags.map((tag) {
              final displayTag = tag.startsWith('#') ? tag : '#$tag';
              return InputChip(
                label: Text(displayTag, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.grey),
                onDeleted: () {
                  final updated = List<String>.from(tags)..remove(tag);
                  _repo.updateBlockTags(block.id, updated);
                },
                backgroundColor:
                    const Color(0xFFFF6B6B).withValues(alpha: 0.06),
                labelStyle: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
            ActionChip(
              label: const Text('+ 标签', style: TextStyle(fontSize: 11)),
              onPressed: () => _showBlockTagDialog(block, tags),
              backgroundColor:
                  isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        ),
      ],
    );
  }

  void _showBlockTagDialog(ContentBlock block, List<String> currentTags) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入标签名'),
          onSubmitted: (val) {
            final tag = val.trim();
            if (tag.isNotEmpty) {
              final cleanTag = tag.startsWith('#') ? tag : '#$tag';
              final updated = List<String>.from(currentTags);
              if (!updated.contains(cleanTag)) {
                updated.add(cleanTag);
              }
              _repo.updateBlockTags(block.id, updated);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                final cleanTag = tag.startsWith('#') ? tag : '#$tag';
                final updated = List<String>.from(currentTags);
                if (!updated.contains(cleanTag)) {
                  updated.add(cleanTag);
                }
                _repo.updateBlockTags(block.id, updated);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== 主构建 ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 46,
        centerTitle: true,
        title: Text(_currentTitle.isEmpty ? '未命名' : _currentTitle,
            style: AppTypography.h3
                .copyWith(color: theme.textTheme.bodyMedium?.color)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'edit_title',
                  child: Text('修改标题', style: TextStyle(fontSize: 13))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除此条',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent))),
            ],
            onSelected: (val) {
              if (val == 'edit_title') {
                _showEditTitleDialog(isDark);
              } else if (val == 'delete') {
                _confirmDelete();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
                    // 块标题
                    if (blocks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('内容记录',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500])),
                      ),

                    // 渲染所有内容块
                    ...blocks.map(
                        (block) => _buildContentBlock(block, theme, isDark)),

                    // 追加内容按钮（始终在最后一个块之后）
                    const SizedBox(height: 6),
                    _buildAddBlockButton(isDark, theme),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ===== AI 对话区域 =====
            _buildAiSection(theme, isDark),

            const SizedBox(height: 20),

            // ===== 任务清单 =====
            _buildTaskSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  // ==================== 追加按钮 ====================

  Widget _buildAddBlockButton(bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openBlockEditor(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 6),
            const Text('追加内容',
                style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ==================== AI 对话区域 ====================

  Widget _buildAiSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Text('AI 交流',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500])),
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
                // 空状态提示
                if (conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('所有内容块已作为上下文提供给 AI，开始提问吧',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),

                // 对话列表
                ...conversations.map(
                    (conv) => _buildConversationBubble(conv, theme, isDark)),

                // 加载指示器
                if (_isAiWorking &&
                    conversations.isNotEmpty &&
                    conversations.last.role == 'user')
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('AI 正在思考...',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                // 输入框
                const SizedBox(height: 10),
                _buildAiInput(isDark),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildConversationBubble(
      AiConversation conv, ThemeData theme, bool isDark) {
    final isUser = conv.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 角色标签
          Text(
            isUser ? '你' : 'AI',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUser
                    ? const Color(0xFFFF6B6B)
                    : Colors.amber.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          // 内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.06)
                  : (isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(12),
              border: isUser
                  ? Border.all(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      width: 1)
                  : null,
            ),
            child: Text(conv.content,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiInputController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: '基于所有内容块进行AI交流...',
                hintStyle: TextStyle(fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _sendAiMessage(),
            ),
          ),
          GestureDetector(
            onTap: _isAiWorking ? null : _sendAiMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 任务清单 ====================

  Widget _buildTaskSection(ThemeData theme, bool isDark) {
    return StreamBuilder<List<IdeaTask>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final doneCount = tasks.where((t) => t.isDone).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        size: 14, color: Color(0xFFFF6B6B)),
                    const SizedBox(width: 6),
                    Text('转化执行清单 ($doneCount/${tasks.length})',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400])),
                  ],
                ),
                if (tasks.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 60,
                      height: 3,
                      child: LinearProgressIndicator(
                        value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                        backgroundColor: isDark
                            ? const Color(0xFF333333)
                            : const Color(0xFFE0E0E0),
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                if (!_isEnteringTask)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 16, color: Color(0xFFFF6B6B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _isEnteringTask = true),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isEnteringTask)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTaskController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: '输入需要派生执行的步骤...',
                          border: UnderlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _repo.addTask(
                                widget.payload.id, val.trim(), tasks.length);
                            _newTaskController.clear();
                            setState(() => _isEnteringTask = false);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() => _isEnteringTask = false),
                    ),
                  ],
                ),
              ),
            if (tasks.isEmpty && !_isEnteringTask)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('暂无任务，点击 + 或使用 AI 派生',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: task.isDone,
                          activeColor: const Color(0xFFFF6B6B),
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.grey[500]!, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) =>
                              _repo.toggleTask(task.id, val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.content,
                          style: TextStyle(
                            fontSize: 13,
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? theme.hintColor : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 14, color: Colors.grey[600]),
                        onPressed: () => _repo.removeTask(task.id),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // ==================== 工具方法 ====================

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

    return GestureDetector(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: effectiveOnTap == null ? Colors.grey[700] : c),
            if (label != null) ...[
              const SizedBox(width: 2),
              Text(label!, style: TextStyle(fontSize: 10, color: c)),
            ],
          ],
        ),
      ),
    );
  }
}

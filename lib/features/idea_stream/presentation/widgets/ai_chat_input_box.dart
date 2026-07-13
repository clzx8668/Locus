import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/ai_engine.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/design_system.dart';
import '../pages/template_management_page.dart';

// ==========================================
// 语音输入处理器预留接口
// ==========================================

/// 语音输入处理器抽象接口（预留后续 STT 集成）
abstract class VoiceInputHandler {
  Future<String> startRecording();
  Future<void> stopRecording();
  Future<String> transcribe(String audioPath);
  Future<bool> autoSubmit(Future<void> Function(String text) onSend);
}

/// 默认语音处理器（占位实现）
class DefaultVoiceInputHandler implements VoiceInputHandler {
  @override
  Future<String> startRecording() async => '';

  @override
  Future<void> stopRecording() async {}

  @override
  Future<String> transcribe(String audioPath) async {
    throw UnimplementedError('语音转写功能暂未集成');
  }

  @override
  Future<bool> autoSubmit(Future<void> Function(String text) onSend) async {
    return false;
  }
}

// ==========================================
// 输入框配置
// ==========================================

/// 输入框模式
enum AiInputMode {
  /// 模板模式（默认）：第二个按钮为 @ 模板选择
  template,

  /// 知识库模式：第二个按钮为知识库选择，无 @ 模板功能
  knowledge,
}

/// AI 输入框可选配置
class AiInputConfig {
  /// 输入模式，默认 template
  final AiInputMode mode;

  /// 知识库模式：可用的知识库文件列表
  final List<KnowledgeFile>? knowledgeFiles;

  /// 知识库模式：当前已选的知识库文件 ID 集合
  final Set<int> selectedKnowledgeIds;

  /// 知识库模式：选择变更回调
  final ValueChanged<Set<int>>? onKnowledgeChanged;

  /// 知识库模式：网页搜索是否启用
  final bool isWebSearchEnabled;

  /// 知识库模式：网页搜索开关变更回调
  final ValueChanged<bool>? onWebSearchChanged;

  /// 知识库模式：管理知识库入口回调
  final VoidCallback? onManageKnowledge;

  const AiInputConfig({
    this.mode = AiInputMode.template,
    this.knowledgeFiles,
    this.selectedKnowledgeIds = const {},
    this.onKnowledgeChanged,
    this.isWebSearchEnabled = false,
    this.onWebSearchChanged,
    this.onManageKnowledge,
  });
}

// ==========================================
// AiChatInputBox 组件
// ==========================================

class AiChatInputBox extends StatefulWidget {
  final TextEditingController textController;
  final FocusNode? focusNode;
  final bool isAiWorking;

  /// 当前选中的模型 ID
  final String selectedModel;

  /// 已启用的模板列表（template 模式使用）
  final List<AiTemplate> templates;

  /// 输入框配置（可选，控制模式与知识库等行为）
  final AiInputConfig? inputConfig;

  // ==================== Callbacks ====================

  final VoidCallback onSend;
  final ValueChanged<ModelInfo> onModelChanged;
  final ValueChanged<AiTemplate>? onTemplateSelected;
  final ValueChanged<List<String>>? onAttachmentPicked;
  final VoidCallback? onTemplateManage;

  const AiChatInputBox({
    super.key,
    required this.textController,
    this.focusNode,
    this.isAiWorking = false,
    required this.selectedModel,
    required this.templates,
    required this.onSend,
    required this.onModelChanged,
    this.onTemplateSelected,
    this.onAttachmentPicked,
    this.onTemplateManage,
    this.inputConfig,
  });

  @override
  State<AiChatInputBox> createState() => _AiChatInputBoxState();
}

class _AiChatInputBoxState extends State<AiChatInputBox> {
  bool _isVoiceMode = false;
  bool _textNotEmpty = false;
  // ignore: unused_field — 预留后续 STT 集成
  final VoiceInputHandler _voiceHandler = DefaultVoiceInputHandler();

  @override
  void initState() {
    super.initState();
    _textNotEmpty = widget.textController.text.trim().isNotEmpty;
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _textNotEmpty) {
      setState(() => _textNotEmpty = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: _bottomBarBg(isDark),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 第一行：文本输入区 / 语音录音按钮
                  if (!_isVoiceMode) _buildTextInputArea(isDark),
                  if (_isVoiceMode) _buildVoiceRecordButton(isDark),
                  const SizedBox(height: 4),
                  // 第二行：功能按钮区
                  _buildFunctionRow(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 第一行：文本输入区 ====================

  Widget _buildTextInputArea(bool isDark) {
    final maxHeight = MediaQuery.of(context).size.height * 0.33;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: TextField(
        controller: widget.textController,
        focusNode: widget.focusNode,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: _isVoiceMode ? '点击录音...' : '等待文字输入',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  // ==================== 语音录音按钮 ====================

  Widget _buildVoiceRecordButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('录音功能开发中，后续将通过 STT 自动转写提交'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_rounded,
              size: 22,
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              '点击录音',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 第二行：功能按钮区 ====================

  bool get _isKnowledgeMode =>
      widget.inputConfig?.mode == AiInputMode.knowledge;

  Widget _buildFunctionRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModelButton(isDark),
            const SizedBox(width: 8),
            if (_isKnowledgeMode) ...[
              _buildKnowledgeButton(isDark),
              const SizedBox(width: 8),
              _buildWebSearchToggle(isDark),
            ] else
              _buildAtButton(isDark),
          ],
        ),
        // 右侧按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文本输入模式下：有内容 → 隐藏切换按钮；无内容 → 显示切换按钮
            if (!_isVoiceMode && !_textNotEmpty) ...[
              _buildToggleButton(isDark),
              const SizedBox(width: 8),
            ],
            // 语音模式：始终显示切换按钮
            if (_isVoiceMode) ...[
              _buildToggleButton(isDark),
              const SizedBox(width: 8),
            ],
            _buildAttachButton(isDark),
            // 文本模式 + 有内容 → 显示发送按钮
            if (!_isVoiceMode && _textNotEmpty) ...[
              const SizedBox(width: 8),
              _buildSendButton(isDark),
            ],
            // 语音模式 → 显示提交按钮
            if (_isVoiceMode) ...[
              const SizedBox(width: 8),
              _buildVoiceSubmitButton(isDark),
            ],
          ],
        ),
      ],
    );
  }

  // ==================== 模型选择按钮 ====================

  Widget _buildModelButton(bool isDark) {
    final currentModel = AiEngine.availableModels.firstWhere(
      (m) => m.id == widget.selectedModel,
      orElse: () => AiEngine.availableModels.first,
    );

    return GestureDetector(
      onTap: () => _showModelPicker(isDark),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.memory_rounded,
              size: 16,
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              currentModel.name.length > 10
                  ? '${currentModel.name.substring(0, 10)}…'
                  : currentModel.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '选择 AI 模型',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const Divider(),
                ...AiEngine.availableModels.map((model) {
                  final isSelected = widget.selectedModel == model.id;
                  return ListTile(
                    leading: Icon(
                      Icons.memory_rounded,
                      size: 22,
                      color: isSelected
                          ? const Color(0xFFFF6B6B)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    title: Text(
                      model.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    subtitle: Text(
                      model.provider,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFFFF6B6B), size: 20)
                        : null,
                    onTap: () {
                      widget.onModelChanged(model);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== @ 模板按钮 ====================

  Widget _buildAtButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showTemplatePicker(isDark),
      onLongPress: () {
        HapticFeedback.lightImpact();
        if (widget.onTemplateManage != null) {
          widget.onTemplateManage!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TemplateManagementPage(),
            ),
          );
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          '@',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showTemplatePicker(bool isDark) {
    final templates = widget.templates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可用模板，长按 @ 可进入模板管理创建'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择模板',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TemplateManagementPage(),
                            ),
                          );
                        },
                        child: Text(
                          '管理',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...templates.map((t) {
                  return ListTile(
                    leading: Text(
                      t.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      t.prompt.length > 40
                          ? '${t.prompt.substring(0, 40)}…'
                          : t.prompt,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    onTap: () {
                      // 插入模板 prompt 到光标位置
                      final controller = widget.textController;
                      final text = controller.text;
                      final selection = controller.selection;
                      final cursorPos = selection.isValid
                          ? selection.start
                          : text.length;
                      final newText =
                          '${text.substring(0, cursorPos)}${t.prompt}${text.substring(cursorPos)}';
                      controller.text = newText;
                      controller.selection = TextSelection.collapsed(
                        offset: cursorPos + t.prompt.length,
                      );
                      widget.focusNode?.requestFocus();
                      if (widget.onTemplateSelected != null) {
                        widget.onTemplateSelected!(t);
                      }
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== 知识库选择按钮 ====================

  Widget _buildKnowledgeButton(bool isDark) {
    final config = widget.inputConfig!;
    final selectedCount = config.selectedKnowledgeIds.length;

    return GestureDetector(
      onTap: () => _showKnowledgePicker(isDark),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selectedCount > 0
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dns_rounded,
              size: 16,
              color: selectedCount > 0
                  ? const Color(0xFFFF6B6B)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 4),
            Text(
              selectedCount > 0 ? '知识库($selectedCount)' : '知识库',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selectedCount > 0
                    ? const Color(0xFFFF6B6B)
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKnowledgePicker(bool isDark) {
    final config = widget.inputConfig!;
    final files = config.knowledgeFiles ?? [];
    final selected = Set<int>.from(config.selectedKnowledgeIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '选择知识库',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (config.onManageKnowledge != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                config.onManageKnowledge!();
                              },
                              child: Text(
                                '管理',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (files.isEmpty)
                      _buildEmptyKnowledgeState(isDark, config, ctx)
                    else ...[
                      ...files.map((file) {
                        final isChecked = selected.contains(file.id);
                        return ListTile(
                          leading: Icon(
                            _fileIcon(file.extension),
                            size: 22,
                            color: isChecked
                                ? const Color(0xFFFF6B6B)
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                          title: Text(
                            file.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isChecked
                                  ? const Color(0xFFFF6B6B)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          subtitle: Text(
                            '${_formatBytes(file.size)} · '
                            '${file.isActive ? '已激活' : '未激活'}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          trailing: Checkbox(
                            value: isChecked,
                            activeColor: const Color(0xFFFF6B6B),
                            onChanged: file.isActive
                                ? (v) {
                                    setSheetState(() {
                                      if (v == true) {
                                        selected.add(file.id);
                                      } else {
                                        selected.remove(file.id);
                                      }
                                    });
                                  }
                                : null,
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '已选 ${selected.length} 个知识库',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              config.onKnowledgeChanged?.call(selected);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('确认选择'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyKnowledgeState(
    bool isDark,
    AiInputConfig config,
    BuildContext ctx,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded,
              size: 48, color: isDark ? Colors.grey[700] : Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '暂无知识库文件',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请在长期记忆页面挂载文档',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
          if (config.onManageKnowledge != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                config.onManageKnowledge!();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('去挂载文档'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'txt':
      case 'md':
        return Icons.article_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ==================== 网页搜索开关 ====================

  Widget _buildWebSearchToggle(bool isDark) {
    final enabled = widget.inputConfig?.isWebSearchEnabled ?? false;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.inputConfig?.onWebSearchChanged?.call(!enabled);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFFF6B6B).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.public_rounded,
          size: 18,
          color: enabled
              ? const Color(0xFFFF6B6B)
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    );
  }

  // ==================== 语音 / 键盘切换按钮 ====================

  Widget _buildToggleButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isVoiceMode = !_isVoiceMode);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          _isVoiceMode ? Icons.keyboard_rounded : Icons.mic_none_rounded,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  // ==================== 加号附件按钮 ====================

  Widget _buildAttachButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showAttachmentPicker(isDark),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add_rounded,
          size: 22,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  void _showAttachmentPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '添加附件',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const Divider(),
                _buildAttachmentOption(
                  ctx: ctx,
                  icon: Icons.image_outlined,
                  label: '添加图片',
                  isDark: isDark,
                  onTap: () => _pickImages(ctx),
                ),
                _buildAttachmentOption(
                  ctx: ctx,
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF 文档',
                  isDark: isDark,
                  onTap: () => _pickFiles(ctx, FileType.custom, ['pdf']),
                ),
                _buildAttachmentOption(
                  ctx: ctx,
                  icon: Icons.audio_file_outlined,
                  label: '音频文件',
                  isDark: isDark,
                  onTap: () => _pickFiles(ctx, FileType.audio),
                ),
                _buildAttachmentOption(
                  ctx: ctx,
                  icon: Icons.video_file_outlined,
                  label: '视频文件',
                  isDark: isDark,
                  onTap: () => _pickFiles(ctx, FileType.video),
                ),
                _buildAttachmentOption(
                  ctx: ctx,
                  icon: Icons.description_outlined,
                  label: '参考文档',
                  isDark: isDark,
                  onTap: () => _pickFiles(ctx, FileType.any),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  Future<void> _pickImages(BuildContext ctx) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty && widget.onAttachmentPicked != null) {
        widget.onAttachmentPicked!(images.map((i) => i.path).toList());
      }
    } catch (e) {
      _showErrorSnackbar('选择图片失败: $e');
    }
  }

  Future<void> _pickFiles(
      BuildContext ctx, FileType type, [List<String>? allowedExtensions]) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );
      if (result != null && result.paths.isNotEmpty && widget.onAttachmentPicked != null) {
        widget.onAttachmentPicked!(result.paths.whereType<String>().toList());
      }
    } catch (e) {
      _showErrorSnackbar('选择文件失败: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== 发送按钮 ====================

  Widget _buildSendButton(bool isDark) {
    return GestureDetector(
      onTap: widget.isAiWorking ? null : widget.onSend,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: widget.isAiWorking
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                size: 16,
                color: Colors.white,
              ),
      ),
    );
  }

  // ==================== 语音提交按钮 ====================

  Widget _buildVoiceSubmitButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('语音转写功能开发中，请切换回文字模式输入'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.send_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // ==================== 工具方法 ====================

  Color _bottomBarBg(bool isDark) {
    return isDark ? const Color(0xFF1A1A1A) : Colors.white;
  }
}

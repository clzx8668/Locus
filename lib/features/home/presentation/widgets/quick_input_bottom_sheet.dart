import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/intent_router.dart';
import '../../../../core/services/processing_pipeline.dart';
import '../../../idea_stream/data/idea_repository.dart';
import '../../../idea_stream/presentation/widgets/ai_chat_input_box.dart';

class QuickInputBottomSheet extends StatefulWidget {
  const QuickInputBottomSheet({super.key});

  @override
  State<QuickInputBottomSheet> createState() => _QuickInputBottomSheetState();
}

class _QuickInputBottomSheetState extends State<QuickInputBottomSheet> {
  final _repo = getIt<IdeaRepository>();
  final _pipeline = getIt<ProcessingPipeline>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSendRecord(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final dynamicTag = IntentRouter.parseTag(trimmed);

    final entry = HubPayloadsCompanion(
      rawText: d.Value(trimmed),
      intentTag: d.Value(dynamicTag),
      mediaPaths: const d.Value('[]'),
    );

    final payloadId = await _repo.insert(entry);

    // 触发后台异步处理管线（不阻塞 UI）
    _pipeline.enqueue(payloadId);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶层小把手
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AiChatInputBox(
          key: const Key('fab_quick_input'),
          textController: _textController,
          focusNode: _focusNode,
          selectedModel: '',
          templates: const [],
          onSend: () {}, // record 模式不使用
          onModelChanged: (_) {}, // record 模式不使用
          inputConfig: const AiInputConfig(
            mode: AiInputMode.record,
            applyKeyboardPadding: false,
          ),
          onSendRecord: _onSendRecord,
        ),
      ],
      ),
    );
  }
}

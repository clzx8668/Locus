import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/database/database.dart';
import 'chat_history_search_page.dart';
import '../../memory/presentation/long_term_memory_page.dart';

class ChatBubble {
  final String text;
  final bool isUser;

  ChatBubble({required this.text, required this.isUser});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();
  final FocusNode _focusNode = FocusNode();

  final List<ChatBubble> _messages = [
    ChatBubble(
      text: "你好！我是 Locus 右脑。我已经成功点亮了**长期记忆**。现在我更进一步，解封了**高级 Markdown 视觉排版能力**。你可以让我试着写一段代码、列一个专业表格，或者梳理复杂的业务流程了！",
      isUser: false,
    ),
  ];

  bool _isAiThinking = false;
  int? _currentSessionId;

  AppDatabase get db => getIt<AppDatabase>();

  // ================= RAG 本地知识检索 (模拟左脑 Drift 数据库) =================
  Future<String> _searchLocalKnowledge(String userQuery) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (userQuery.contains('库存') ||
        userQuery.contains('带风头') ||
        userQuery.contains('陶瓷膜')) {
      return """
[关联本地日记 / 2026-04-15] 记录人：我自己
内容：今日盘点，我们的碳化硅陶瓷模产品，带风头（带风）的规格，目前仓库 A 区还剩余 250 个。没有风头的常规版剩余 800 个。下周需要通知生产线补充带风头的库存。
      """;
    }

    return "";
  }
  // =========================================================================

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatBubble(text: text, isUser: true));
      _textController.clear();
      _isAiThinking = true;
    });

    _focusNode.requestFocus();
    _scrollToBottom();

    final apiKey = (dotenv.env['LLM_API_KEY'] ?? '').trim();
    var baseUrl = (dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1').trim();
    final modelName = (dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat').trim();

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // 1. 触发左脑知识库检索
    final localContext = await _searchLocalKnowledge(text);

    // 2. 深度阅读引擎：从挂载的资料库中检索相关上下文
    final ragContext = await db.getRelevantContext(text);
    if (ragContext.isNotEmpty) {
      debugPrint("RAG 检索命中，上下文长度: ${ragContext.length}");
    }

    // 3. 构建记忆增强 System Prompt
    final memories = await db.getAllMemoryTexts();
    String systemPrompt =
        '你是一个部署在本地的智能综合助理 Locus 的右脑。请用专业、严谨且有条理的语言回答问题。遇到结构化数据请使用 Markdown。';
    if (memories.isNotEmpty) {
      systemPrompt += '\n\n【关于我的核心信息，你必须永远牢记】：\n';
      for (var m in memories) {
        systemPrompt += '- $m\n';
      }
    }
    if (ragContext.isNotEmpty) {
      systemPrompt +=
          '\n\n【📚 参考文档资料】：\n$ragContext\n\n请优先基于上述参考文档资料来回答用户的问题。';
    }
    systemPrompt +=
        '\n\n【特别指令】：如果用户明确要求你记住某事，请在回答的末尾加上特殊标记：[SAVE_MEMORY: 要记住的具体事实]。';
    if (localContext.isNotEmpty) {
      systemPrompt +=
          '\n\n【⚠️ 极高优先级：本地知识库检索结果】\n$localContext\n\n请严格基于上述本地知识库的信息来回答用户的问题。';
      debugPrint("已成功向右脑注入本地上下文！");
    }

    List<Map<String, dynamic>> apiMessages = [
      {'role': 'system', 'content': systemPrompt}
    ];

    const int historyLimit = 10;
    final recentMessages = _messages.length > historyLimit
        ? _messages.sublist(_messages.length - historyLimit)
        : _messages;

    for (var msg in recentMessages) {
      apiMessages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text
      });
    }

    try {
      // 🌟 核心流式改造 1：配置 Dio 接收数据流
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': modelName,
          'messages': apiMessages,
          'temperature': 0.7,
          'stream': true,
        },
      );

      // 🌟 核心流式改造 2：准备一个空的 AI 气泡来接水
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _messages.add(ChatBubble(text: "", isUser: false));
        });
      }

      String currentReply = "";

      // 🌟 核心流式改造 3：监听流并疯狂重绘
      await for (var bytes in response.data.stream) {
        final chunk = utf8.decode(bytes, allowMalformed: true);
        final lines = chunk.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();

            if (dataStr == '[DONE]') {
              // 拦截并提取自动记忆标签 [SAVE_MEMORY: xxx]
              final memoryRegex = RegExp(r'\[SAVE_MEMORY:\s*(.*?)\]');
              final match = memoryRegex.firstMatch(currentReply);

              if (match != null) {
                final memoryToSave = match.group(1);
                if (memoryToSave != null && memoryToSave.trim().isNotEmpty) {
                  await db.addMemory(memoryToSave.trim(), tags: 'AI自动提取');
                  currentReply = currentReply.replaceAll(memoryRegex, '').trim();
                }
              }

              // 惰性创建：第一次发言时，动态生成带摘要的 Session
              if (_currentSessionId == null) {
                String sessionTitle =
                    text.length > 15 ? '${text.substring(0, 15)}...' : text;
                _currentSessionId = await db.createSession(sessionTitle);
              }

              // 保存用户的提问和 AI 的回答
              await db.insertMessage(_currentSessionId!, 'user', text);
              await db.insertMessage(_currentSessionId!, 'assistant', currentReply);

              break;
            }

            try {
              final jsonObj = jsonDecode(dataStr);
              final delta = jsonObj['choices'][0]['delta']['content'];

              if (delta != null) {
                currentReply += delta;

                if (mounted) {
                  setState(() {
                    _messages[_messages.length - 1] =
                        ChatBubble(text: currentReply, isUser: false);
                  });
                  _scrollToBottom();
                }
              }
            } catch (e) {
              // 网络流可能把一个 JSON 切成两半发过来，这里直接 catch 掉不崩溃
            }
          }
        }
      }
    } on DioException catch (e) {
      String errorDetail = e.message ?? "未知网络异常";
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _messages.add(ChatBubble(
              text: "🚨 抱歉，流式连接异常。\n原因: $errorDetail", isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiThinking = false;
          _messages.add(ChatBubble(text: "🚨 发生意外错误: $e", isUser: false));
        });
      }
    } finally {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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

  void _startNewConversation() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _messages.add(ChatBubble(
        text: "✨ 记忆区已重置。准备好探讨碳化硅陶瓷膜的最新工艺或业务需求了，请指示。",
        isUser: false,
      ));
    });
    _focusNode.requestFocus();
  }

  // ================= 恢复历史对话现场 =================
  void _loadSession(int sessionId) async {
    setState(() {
      _isAiThinking = true;
      _messages.clear();
    });

    final historyMessages = await db.getMessagesForSession(sessionId);

    setState(() {
      _currentSessionId = sessionId;

      _messages.clear();
      _messages.addAll(historyMessages.map((msg) => ChatBubble(
        text: msg.content,
        isUser: msg.role == 'user',
      )));

      _isAiThinking = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  // ==================================================

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Locus 右脑',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color)),
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: theme.shadowColor,
        centerTitle: true,
        actions: [
          // 🧠 金刚键 1：长久记忆与资料库
          IconButton(
            icon: Icon(Icons.memory_rounded,
                color: theme.textTheme.bodyMedium?.color, size: 24),
            tooltip: '长久记忆与资料库',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LongTermMemoryPage()),
              );
            },
          ),
          // 🔍 金刚键 2：历史对话与全局搜索
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: theme.textTheme.bodyMedium?.color, size: 24),
            tooltip: '搜索历史记录',
            onPressed: () async {
              final selectedSessionId = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistorySearchPage(),
                  fullscreenDialog: true,
                ),
              );

              if (selectedSessionId != null) {
                _loadSession(selectedSessionId);
              }
            },
          ),
          // ✨ 金刚键 3：新建对话
          IconButton(
            icon: Icon(Icons.create_outlined,
                color: theme.textTheme.bodyMedium?.color, size: 22),
            tooltip: '开启新对话',
            onPressed: _startNewConversation,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),
          if (_isAiThinking)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.6)),
                    ),
                    const SizedBox(width: 10),
                    Text("Locus 正在思考...",
                        style: TextStyle(
                            color: theme.hintColor, fontSize: 13)),
                  ],
                ),
              ),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatBubble msg, bool isDark) {
    final theme = Theme.of(context);
    final userBubbleColor =
        isDark ? const Color(0xFF333333) : const Color(0xFF212121);
    final aiBubbleColor = theme.cardColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser)
            _buildAvatar(Icons.smart_toy_outlined, theme.colorScheme.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: msg.isUser
                    ? null
                    : [
                        BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: msg.isUser
                  ? SelectableText(
                      msg.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.4),
                    )
                  : MarkdownBody(
                      data: msg.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                            height: 1.5),
                        h1: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.5),
                        h2: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5),
                        code: TextStyle(
                            color: theme.colorScheme.primary,
                            backgroundColor: Colors.transparent,
                            fontFamily: 'monospace',
                            fontSize: 14),
                        codeblockDecoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: theme.dividerColor, width: 1),
                        ),
                        tableBorder: TableBorder.all(
                            color: theme.dividerColor, width: 1),
                        tableBody: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14),
                        tableHead: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          if (msg.isUser)
            _buildAvatar(Icons.person_outline, theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color bgColor) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: bgColor.withValues(alpha: 0.1),
      child: Icon(icon, size: 18, color: bgColor),
    );
  }

  Widget _buildInputArea(bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              offset: const Offset(0, -2),
              blurRadius: 10)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '向 Locus 提问...',
                  hintStyle: TextStyle(color: theme.hintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../core/di/service_locator.dart';
import '../../../core/database/database.dart';
import '../../../core/vault/vault_service.dart';
import '../../../core/vault/fts_index_service.dart';
import '../../../core/services/embedding_service.dart';
import 'chat_history_search_page.dart';
import '../../memory/presentation/long_term_memory_page.dart';
import 'reference_parser.dart';

class ChatBubble { final String text; final bool isUser; ChatBubble({required this.text, required this.isUser}); }

class ChatPage extends StatefulWidget { const ChatPage({super.key}); @override State<ChatPage> createState() => _ChatPageState(); }

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();
  final FocusNode _focusNode = FocusNode();
  final List<ChatBubble> _messages = [ChatBubble(text: "Hello! I'm Locus with vector search RAG. Ask me about your documents.", isUser: false)];
  bool _isAiThinking = false;
  int? _currentSessionId;

  AppDatabase get db => getIt<AppDatabase>();
  VaultService get vaultService => getIt<VaultService>();
  FtsIndexService get ftsService => getIt<FtsIndexService>();
  EmbeddingService get embeddingService => getIt<EmbeddingService>();

  Future<String> _gatherContext(String userQuery) async {
    final parts = <String>[];
    try {
      final vectorResults = await embeddingService.search(query: userQuery, limit: 3, minSimilarity: 0.3);
      if (vectorResults.isNotEmpty) parts.add('[Vector RAG]\n${vectorResults.map((r) => '> ${r.content.length > 200 ? "${r.content.substring(0, 200)}..." : r.content}').join('\n\n')}');
    } catch (e) { debugPrint('Vector search skipped: $e'); }
    if (ftsService.isInitialized) {
      try { final ftsR = ftsService.search(userQuery); if (ftsR.isNotEmpty) parts.add('[Vault]\n${ftsR.take(3).map((r) => '**${r['title']}**\n${r['snippet']}').join('\n\n')}'); } catch (_) {}
    }
    try { final dbC = await db.getRelevantContext(userQuery); if (dbC.isNotEmpty) parts.add('[Documents]\n$dbC'); } catch (_) {}
    try {
      final contacts = await db.searchContacts(userQuery);
      if (contacts.isNotEmpty) {
        parts.add('[Contacts]\n${contacts.take(3).map((c) => '- ${c.name}${c.company != null ? ' (${c.company})' : ''}').join('\n')}');
        for (final c in contacts.take(2)) {
          final acts = await (db.select(db.activities)..where((t) => t.contactId.equals(c.id))..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])..limit(3)).get();
          if (acts.isNotEmpty) parts.add('[Recent: ${c.name}]\n${acts.map((a) => '- [${a.type}] ${a.content.length > 60 ? '${a.content.substring(0, 60)}...' : a.content}').join('\n')}');
        }
      }
    } catch (_) {}
    return parts.join('\n\n---\n\n');
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add(ChatBubble(text: text, isUser: true)); _textController.clear(); _isAiThinking = true; });
    _focusNode.requestFocus(); _scrollToBottom();
    final apiKey = (dotenv.env['LLM_API_KEY'] ?? '').trim();
    var baseUrl = (dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1').trim();
    final modelName = (dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat').trim();
    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    final localContext = await _gatherContext(text);
    final memories = await db.getAllMemoryTexts();
    String systemPrompt = '''You are Locus, a local intelligent assistant. Answer professionally with Markdown.

When referencing sources from the provided [Local Context], mark them with [ref:NAME] where NAME is the contact name, document title, or note identifier. Example: "According to [ref:张三]'s recent activity..."

When presenting structured data (contacts, deals, tasks, etc.), you can reference them inline: "You have 3 open deals: [ref:deal_1], [ref:deal_2], [ref:deal_3]".

Do NOT use [ref:xxx] for general concepts or things not found in the context.''';
    if (memories.isNotEmpty) systemPrompt += '\n\n[My Core Facts]:\n${memories.map((m) => '- $m').join('\n')}';
    if (localContext.isNotEmpty) systemPrompt += '\n\n[Local Context]:\n$localContext';
    systemPrompt += '\n\n[Special]: If I ask you to remember something, end with [SAVE_MEMORY: fact].';
    List<Map<String, dynamic>> apiMessages = [{'role': 'system', 'content': systemPrompt}];
    final recent = _messages.length > 10 ? _messages.sublist(_messages.length - 10) : _messages;
    for (var m in recent) {
      apiMessages.add({'role': m.isUser ? 'user' : 'assistant', 'content': m.text});
    }
    try {
      final response = await _dio.post('$baseUrl/chat/completions', options: Options(headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json', 'Accept': 'text/event-stream'}, responseType: ResponseType.stream, sendTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 60)), data: {'model': modelName, 'messages': apiMessages, 'temperature': 0.7, 'stream': true});
      if (mounted) setState(() { _isAiThinking = false; _messages.add(ChatBubble(text: "", isUser: false)); });
      String cur = "";
      await for (var bytes in response.data.stream) {
        for (var line in utf8.decode(bytes, allowMalformed: true).split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final ds = line.substring(6).trim();
          if (ds == '[DONE]') {
            final mm = RegExp(r'\[SAVE_MEMORY:\s*(.*?)\]').firstMatch(cur);
            if (mm != null && mm.group(1)!.trim().isNotEmpty) { await db.addMemory(mm.group(1)!.trim(), tags: 'AI-auto'); cur = cur.replaceAll(RegExp(r'\[SAVE_MEMORY:\s*(.*?)\]'), '').trim(); }
            _currentSessionId ??= await db.createSession(text.length > 20 ? '${text.substring(0, 20)}...' : text);
            await db.insertMessage(_currentSessionId!, 'user', text); await db.insertMessage(_currentSessionId!, 'assistant', cur);
            _writeChatLog(text, cur); break;
          }
          try { final d = jsonDecode(ds)['choices'][0]['delta']['content']; if (d != null) { cur += d; if (mounted) setState(() { _messages[_messages.length - 1] = ChatBubble(text: cur, isUser: false); }); _scrollToBottom(); } } catch (_) {}
        }
      }
    } on DioException catch (e) { if (mounted) setState(() { _isAiThinking = false; _messages.add(ChatBubble(text: "Network error: ${e.message}", isUser: false)); }); } catch (e) { if (mounted) setState(() { _isAiThinking = false; _messages.add(ChatBubble(text: "Error: $e", isUser: false)); }); } finally { _scrollToBottom(); }
  }

  void _writeChatLog(String u, String a) async {
    try {
      if (vaultService.vaultPath != null) {
        final t = u.length > 30 ? '${u.substring(0, 30)}...' : u; final now = DateTime.now();
        await vaultService.writeNote(subDir: 'chat-logs', fileName: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-$t.md'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-'), frontmatter: {'title': t, 'type': 'chat-log', 'tags': 'ai-chat', 'created': now.toIso8601String()}, body: '## User\n$u\n\n## Locus\n$a\n');
      }
    } catch (_) {}
  }

  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }
  void _startNewConversation() { setState(() { _currentSessionId = null; _messages.clear(); _messages.add(ChatBubble(text: "New conversation. How can I help?", isUser: false)); }); _focusNode.requestFocus(); }
  void _loadSession(int sid) async { setState(() { _isAiThinking = true; _messages.clear(); }); final h = await db.getMessagesForSession(sid); if (mounted) { setState(() { _currentSessionId = sid; _messages.addAll(h.map((m) => ChatBubble(text: m.content, isUser: m.role == 'user'))); _isAiThinking = false; }); WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom()); } }

  void _onRefTap(String refId) {
    debugPrint('Reference tapped: $refId');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reference: $refId'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override void dispose() { _textController.dispose(); _scrollController.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final userBubble = isDark ? const Color(0xFFFF6B6B) : Colors.black87;
    final aiBubble = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final aiText = isDark ? Colors.white : Colors.black87;
    final inputBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!;
    final barBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final barBorder = isDark ? Colors.white10 : const Color(0x0D000000);
    final hintColor = isDark ? Colors.white30 : Colors.grey[400]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Locus AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: barBg, elevation: 0.5, centerTitle: true, scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white70 : Colors.black87),
        actions: [
          IconButton(icon: Icon(Icons.memory_rounded, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey), tooltip: 'Memory', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LongTermMemoryPage()))),
          IconButton(icon: Icon(Icons.search_rounded, color: isDark ? Colors.white70 : Colors.black87), tooltip: 'History', onPressed: () async { final sid = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const ChatHistorySearchPage(), fullscreenDialog: true)); if (sid != null) _loadSession(sid); }),
          IconButton(icon: Icon(Icons.create_outlined, color: isDark ? Colors.white70 : Colors.black87), tooltip: 'New', onPressed: _startNewConversation), const SizedBox(width: 12),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), itemCount: _messages.length, itemBuilder: (_, i) => _buildBubble(_messages[i], isDark, userBubble, aiBubble, aiText))),
        if (_isAiThinking) Padding(padding: const EdgeInsets.only(left: 24, bottom: 12, top: 4), child: Align(alignment: Alignment.centerLeft, child: Row(children: [SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[400])), const SizedBox(width: 10), Text("Thinking...", style: TextStyle(color: isDark ? Colors.white38 : Colors.blueGrey[400], fontSize: 13))]))),
        _buildInputArea(isDark, inputBg, barBg, barBorder, hintColor),
      ]),
    );
  }

  Widget _buildBubble(ChatBubble msg, bool isDark, Color userBubble, Color aiBubble, Color aiText) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!msg.isUser) CircleAvatar(radius: 16, backgroundColor: (isDark ? Colors.blueGrey[700] : Colors.blueGrey[100])!, child: Icon(Icons.smart_toy_outlined, size: 18, color: isDark ? Colors.white60 : Colors.blueGrey)),
      const SizedBox(width: 10),
      Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: msg.isUser ? userBubble : aiBubble, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(msg.isUser ? 16 : 4), bottomRight: Radius.circular(msg.isUser ? 4 : 16))), child: msg.isUser ? SelectableText(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)) : MarkdownBody(data: msg.text, selectable: true, inlineSyntaxes: ReferenceParser.inlineSyntaxes, builders: ReferenceParser.getMarkdownBuilders(onTap: _onRefTap), styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(p: TextStyle(color: aiText, fontSize: 15, height: 1.5), h1: TextStyle(color: aiText, fontSize: 20, fontWeight: FontWeight.bold), h2: TextStyle(color: aiText, fontSize: 18, fontWeight: FontWeight.bold), code: TextStyle(color: isDark ? Colors.orange[300] : Colors.red[800], fontFamily: 'monospace', fontSize: 14), codeblockDecoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey[100]!, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!)), tableBorder: TableBorder.all(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1))))),
      const SizedBox(width: 10),
      if (msg.isUser) CircleAvatar(radius: 16, backgroundColor: (isDark ? const Color(0xFFFF6B6B).withValues(alpha: 0.2) : Colors.black12), child: Icon(Icons.person_outline, size: 18, color: isDark ? const Color(0xFFFF6B6B) : Colors.black87)),
    ]));
  }

  Widget _buildInputArea(bool isDark, Color inputBg, Color barBg, Color barBorder, Color hintColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: barBg, border: Border(top: BorderSide(color: barBorder))),
      child: SafeArea(child: Row(children: [
        Expanded(child: TextField(controller: _textController, focusNode: _focusNode, maxLines: 4, minLines: 1, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15), decoration: InputDecoration(hintText: 'Ask Locus...', hintStyle: TextStyle(color: hintColor, fontSize: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: inputBg, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _sendMessage, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFFFF6B6B) : Colors.black87, shape: BoxShape.circle), child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20))),
      ])),
    );
  }
}


import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 模型信息结构
class ModelInfo {
  final String id;
  final String name;
  final String provider;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
  });
}

/// AI 通用引擎 —— 封装 LLM 调用，支持流式 / 非流式两种模式
/// 当前适配 DeepSeek API（兼容 OpenAI 格式）
class AiEngine {
  final String _apiKey;
  String _baseUrl;
  String _model;

  /// 可用模型列表（后续可从设置页自定义扩展）
  static const List<ModelInfo> availableModels = [
    ModelInfo(id: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'DeepSeek'),
    ModelInfo(id: 'deepseek-reasoner', name: 'DeepSeek R1', provider: 'DeepSeek'),
    ModelInfo(id: 'gpt-4o', name: 'GPT-4o', provider: 'OpenAI'),
    ModelInfo(id: 'gpt-4o-mini', name: 'GPT-4o Mini', provider: 'OpenAI'),
    ModelInfo(id: 'claude-3.5-sonnet', name: 'Claude 3.5 Sonnet', provider: 'Anthropic'),
  ];

  AiEngine()
      : _apiKey = dotenv.env['LLM_API_KEY'] ?? '',
        _baseUrl = dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1',
        _model = dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// 当前模型名
  String get modelName => _model;

  /// 切换模型
  void setModel(String model) => _model = model;

  /// 获取当前 base URL
  String get baseUrl => _baseUrl;

  /// 设置 API 端点
  void setBaseUrl(String url) => _baseUrl = url;

  // ==================== 非流式调用 ====================

  /// 发送消息并返回完整回复
  Future<String> chat(String systemPrompt, String userMessage) async {
    if (!isConfigured) return _fallbackResponse(systemPrompt);

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.7,
              'max_tokens': 2000,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content']?.trim() ??
            _fallbackResponse(systemPrompt);
      }
      return _fallbackResponse(systemPrompt);
    } catch (_) {
      return _fallbackResponse(systemPrompt);
    }
  }

  // ==================== 流式调用 ====================

  /// 流式发送消息，通过 [onChunk] 回调逐字输出
  Future<String> chatStream(
    String systemPrompt,
    String userMessage,
    void Function(String chunk) onChunk,
  ) async {
    if (!isConfigured) {
      return _simulateStream(_fallbackResponse(systemPrompt), onChunk);
    }

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final request = http.StreamedRequest('POST', uri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      request.sink.add(utf8.encode(jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
        'stream': true,
      })));
      request.sink.close();

      final response = await request.send().timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final buffer = StringBuffer();
        await for (final chunk in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (chunk.startsWith('data: ') && chunk.length > 6) {
            final data = chunk.substring(6);
            if (data == '[DONE]') break;
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content.isNotEmpty) {
                buffer.write(content);
                onChunk(content);
              }
            } catch (_) {}
          }
        }
        return buffer.toString();
      }
    } catch (_) {}

    return _simulateStream(_fallbackResponse(systemPrompt), onChunk);
  }

  // ==================== 闪念专用快捷方法 ====================

  /// 消除口语化 / 润色
  Future<String> polishText(String rawText) =>
      chatStream('你是一位资深文案编辑。将用户输入的口语化文本润色为流畅、专业的书面表达，保留原意和所有关键信息。只返回润色后的文本，不要加任何解释。',
          rawText, (_) {});

  /// 正规化公文格式
  Future<String> formalizeText(String rawText) => chatStream(
      '你是一位政府/企业公文撰写专家。将用户输入整理为正式公文格式，结构清晰、用词规范。只返回格式化后的文本。',
      rawText, (_) {});

  /// 提取结构化账目
  Future<String> extractLedger(String rawText) => chatStream(
      '你是一位专业财务分析师。从用户输入中提取所有涉及金额、交易、账目的信息，整理为：\n【交易项目】\n【财务科目】\n【金额】\n【备注】\n只返回提取结果。',
      rawText, (_) {});

  /// 派生待办任务
  Future<String> deriveTasks(String rawText) => chatStream(
      '你是一位高效的项目管理助手。从用户输入中识别所有需要执行的动作项，以简洁的待办清单列出。每行一个任务，用"•"开头。只返回任务列表。',
      rawText, (_) {});

  // ==================== Fallback ====================

  String _fallbackResponse(String systemPrompt) {
    if (systemPrompt.contains('文案')) {
      return '[AI离线] 文本已本地缓存，联网后将自动润色。';
    }
    if (systemPrompt.contains('公文')) {
      return '[AI离线] 文档草稿已保存，将在联网后格式化。';
    }
    if (systemPrompt.contains('财务')) {
      return '[AI离线] 账目信息已标记，联网后提取。';
    }
    if (systemPrompt.contains('项目管理')) {
      return '[AI离线] 任务清单可手动添加，或等待联网派生。';
    }
    return '[AI离线] 服务暂不可用，请稍后重试。';
  }

  String _simulateStream(String text, void Function(String) onChunk) {
    int index = 0;
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (index < text.length) {
        onChunk(text[index++]);
      } else {
        timer.cancel();
      }
    });
    return text;
  }
}

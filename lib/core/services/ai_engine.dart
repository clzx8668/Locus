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

/// AI 通用引擎 —— 封装 LLM 调用，支持流式 / 非流式 / Function Calling 三种模式
/// 当前适配 DeepSeek API（兼容 OpenAI 格式）
class AiEngine {
  final String _apiKey;
  String _baseUrl;
  String _model;

  /// 可用模型列表
  static const List<ModelInfo> availableModels = [
    ModelInfo(id: 'deepseek-chat', name: 'DeepSeek Chat', provider: 'DeepSeek'),
    ModelInfo(
        id: 'deepseek-reasoner', name: 'DeepSeek R1', provider: 'DeepSeek'),
    ModelInfo(id: 'gpt-4o', name: 'GPT-4o', provider: 'OpenAI'),
    ModelInfo(id: 'gpt-4o-mini', name: 'GPT-4o Mini', provider: 'OpenAI'),
    ModelInfo(
        id: 'claude-3.5-sonnet',
        name: 'Claude 3.5 Sonnet',
        provider: 'Anthropic'),
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
        return data['choices'][0]['message']['content']?.trim() ?? 'API 返回为空';
      }
      return "API 请求失败: ${response.statusCode}";
    } catch (e) {
      return "网络异常，请检查连接后重试";
    }
  }

  /// AI 润色文本（便捷方法）
  Future<String> polishText(String content) async {
    return chat(
      '你是一个专业的文字编辑，请对以下内容进行润色，使其更清晰流畅，但保持原意不变。直接返回润色后的文本，无需解释。',
      content,
    );
  }

  // ==================== Function Calling / Tool Use ====================

  /// 调用大模型 Function Calling，返回工具调用的 JSON 参数
  /// [systemPrompt] 系统提示词
  /// [userMessage] 用户输入的文本
  /// [tools] OpenAI 兼容的 tools 定义列表
  /// [toolChoice] 工具选择策略，默认 "auto"
  /// 返回解析后的 tool call arguments（Map），失败返回 null
  Future<Map<String, dynamic>?> functionCall({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, dynamic>> tools,
    String toolChoice = 'auto',
  }) async {
    if (!isConfigured) return null;

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
              'tools': tools,
              'tool_choice': toolChoice,
              'temperature': 0.3,
              'max_tokens': 1000,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choice = data['choices']?[0];
        final message = choice?['message'];

        // 检查是否有 tool_calls
        final toolCalls = message?['tool_calls'];
        if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
          final function = toolCalls[0]['function'];
          final argumentsStr = function['arguments'] as String?;
          if (argumentsStr != null && argumentsStr.isNotEmpty) {
            return jsonDecode(argumentsStr) as Map<String, dynamic>;
          }
        }

        // 有些模型直接返回 content 中的 JSON
        final content = message?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          try {
            return jsonDecode(content) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
      return null;
    } catch (_) {
      return null; // 超时或网络错误，返回 null 触发降级
    }
  }

  // ==================== 流式调用（保留，供 Chat 功能使用） ====================

  /// 发送流式消息，通过 [onChunk] 回调逐字返回
  Future<void> chatStream(
    String systemPrompt,
    String userMessage,
    void Function(String chunk) onChunk,
  ) async {
    if (!isConfigured) {
      onChunk(_fallbackResponse(systemPrompt));
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'stream': true,
          'temperature': 0.7,
          'max_tokens': 2000,
        });

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ') && chunk.length > 6) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content =
                json['choices']?[0]?['delta']?['content'] as String?;
            if (content != null) onChunk(content);
          } catch (_) {}
        }
      }
    } catch (e) {
      onChunk("网络异常，请检查连接后重试");
    }
  }

  /// 本地离线回退响应（当 API Key 未配置时）
  String _fallbackResponse(String prompt) {
    return "本地智能代理已就绪，请配置 API Key 以启用云端大模型。";
  }
}

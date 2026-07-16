import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'settings_service.dart';
import '../utils/data_anonymizer.dart';

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
/// 兼容 OpenAI 格式，支持 DeepSeek、Ollama 等后端
class AiEngine {
  String _apiKey;
  String _baseUrl;
  String _model;
  final SecureStorageService? _secureStorage;
  final SettingsService? _settings;

  /// 可用模型列表（云端）
  static const List<ModelInfo> availableCloudModels = [
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

  /// Ollama 默认本地模型
  static const ModelInfo defaultOllamaModel = ModelInfo(
    id: 'llama3:8b',
    name: 'Llama 3 (8B)',
    provider: 'Ollama',
  );

  AiEngine({
    SecureStorageService? secureStorage,
    SettingsService? settings,
  })  : _secureStorage = secureStorage,
        _settings = settings,
        _apiKey = dotenv.env['LLM_API_KEY'] ?? '',
        _baseUrl = dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1',
        _model = dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat';

  bool get isConfigured => _apiKey.isNotEmpty;

  String get apiKey => _apiKey;

  /// 异步初始化：优先从 SecureStorage 加载配置，不存在则 fallback 到 .env
  Future<void> init() async {
    if (_secureStorage == null) return;

    final storedKey = await _secureStorage!.getApiKey();
    if (storedKey != null && storedKey.isNotEmpty) {
      _apiKey = storedKey;
    }

    final storedUrl = await _secureStorage!.getBaseUrl();
    if (storedUrl != null && storedUrl.isNotEmpty) {
      _baseUrl = storedUrl;
    }

    final storedModel = await _secureStorage!.getModelName();
    if (storedModel != null && storedModel.isNotEmpty) {
      _model = storedModel;
    }
  }

  /// 当前模型名
  String get modelName => _model;

  /// 切换模型
  void setModel(String model) => _model = model;

  /// 获取当前 base URL
  String get baseUrl => _baseUrl;

  /// 设置 API 端点
  void setBaseUrl(String url) => _baseUrl = url;

  /// 切换为 Ollama 本地模式
  void setOllamaMode({String? model}) {
    _baseUrl = 'http://localhost:11434/v1';
    _model = model ?? 'llama3:8b';
  }

  /// 切换为云端模式
  void setCloudMode({
    String? url,
    String? model,
  }) {
    _baseUrl = url ?? dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1';
    _model = model ?? dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat';
  }

  /// 检查是否需要脱敏处理
  bool get _shouldAnonymize =>
      _settings != null && _settings!.anonymizeData;

  /// 对用户消息做预处理（脱敏等）
  String _preprocessMessage(String message) {
    if (_shouldAnonymize) {
      return DataAnonymizer.anonymize(message);
    }
    return message;
  }

  // ==================== 非流式调用 ====================

  /// 发送消息并返回完整回复
  Future<String> chat(String systemPrompt, String userMessage) async {
    if (!isConfigured) return _fallbackResponse(systemPrompt);

    final processedMessage = _preprocessMessage(userMessage);

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
                {'role': 'user', 'content': processedMessage},
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
  Future<Map<String, dynamic>?> functionCall({
    required String systemPrompt,
    required String userMessage,
    required List<Map<String, dynamic>> tools,
    String toolChoice = 'auto',
  }) async {
    if (!isConfigured) return null;

    final processedMessage = _preprocessMessage(userMessage);

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
                {'role': 'user', 'content': processedMessage},
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

    final processedMessage = _preprocessMessage(userMessage);

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
            {'role': 'user', 'content': processedMessage},
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

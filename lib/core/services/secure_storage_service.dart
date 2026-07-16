
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储服务 —— 保护 API Key、数据库密钥等敏感信息
/// 使用 FlutterSecureStorage，底层依赖 iOS Keychain / Android EncryptedSharedPreferences
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage();

  // ==================== API 密钥 ====================

  Future<void> saveApiKey(String key) =>
      _storage.write(key: 'api_key', value: key);

  Future<String?> getApiKey() => _storage.read(key: 'api_key');

  Future<void> deleteApiKey() => _storage.delete(key: 'api_key');

  // ==================== Base URL ====================

  Future<void> saveBaseUrl(String url) =>
      _storage.write(key: 'base_url', value: url);

  Future<String?> getBaseUrl() => _storage.read(key: 'base_url');

  // ==================== 模型名 ====================

  Future<void> saveModelName(String name) =>
      _storage.write(key: 'model', value: name);

  Future<String?> getModelName() => _storage.read(key: 'model');

  // ==================== Ollama 开关 ====================

  Future<void> saveOllamaEnabled(bool enabled) =>
      _storage.write(key: 'ollama_enabled', value: enabled.toString());

  Future<bool> getOllamaEnabled() async =>
      (await _storage.read(key: 'ollama_enabled')) == 'true';

  // ==================== 数据库密钥 ====================

  Future<void> saveDbKey(String key) =>
      _storage.write(key: 'db_key', value: key);

  Future<String?> getDbKey() => _storage.read(key: 'db_key');
}

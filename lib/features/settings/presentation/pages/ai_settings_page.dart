
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/ai_engine.dart';
import '../../../../core/theme/design_system.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final SettingsService _settings = getIt<SettingsService>();
  late final SecureStorageService _secureStorage = getIt<SecureStorageService>();
  late final AiEngine _aiEngine = getIt<AiEngine>();

  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();

  bool _apiKeyVisible = false;
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _loadInitialValues();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _loadInitialValues() async {
    // 从 SecureStorage 加载 API 配置
    final apiKey = await _secureStorage.getApiKey();
    final baseUrl = await _secureStorage.getBaseUrl();
    final model = await _secureStorage.getModelName();

    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _baseUrlController.text = baseUrl ?? _aiEngine.baseUrl;
        _modelController.text = model ?? _aiEngine.modelName;
      });
    }
  }

  // ─── Ollama 本地模型列表 ───
  static const List<ModelInfo> _ollamaModels = [
    ModelInfo(id: 'llama3:8b', name: 'Llama 3 (8B)', provider: 'Ollama'),
    ModelInfo(id: 'llama3:70b', name: 'Llama 3 (70B)', provider: 'Ollama'),
    ModelInfo(id: 'mistral:7b', name: 'Mistral (7B)', provider: 'Ollama'),
    ModelInfo(id: 'qwen2:7b', name: 'Qwen 2 (7B)', provider: 'Ollama'),
    ModelInfo(id: 'gemma2:9b', name: 'Gemma 2 (9B)', provider: 'Ollama'),
    ModelInfo(id: 'deepseek-r1:8b', name: 'DeepSeek R1 (8B)', provider: 'Ollama'),
  ];

  // ─── 验证 ───
  String? _validateApiKey(String? value) {
    if (_settings.offlineMode) return null;
    if (!_settings.ollamaEnabled) {
      if (value == null || value.trim().isEmpty) {
        return '云端模式下请输入 API Key';
      }
    }
    return null;
  }

  String? _validateBaseUrl(String? value) {
    if (_settings.offlineMode) return null;
    if (value == null || value.trim().isEmpty) {
      return '请输入 Base URL';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAbsolutePath) {
      return '请输入有效的 URL';
    }
    return null;
  }

  String? _validateModelName(String? value) {
    if (_settings.offlineMode) return null;
    if (value == null || value.trim().isEmpty) {
      return '请输入模型名称';
    }
    return null;
  }

  // ─── 持久化 ───
  Future<void> _persistApiKey(String value) async {
    await _secureStorage.saveApiKey(value.trim());
    if (value.trim().isNotEmpty) {
      _aiEngine.setBaseUrl(_baseUrlController.text.trim().isNotEmpty
          ? _baseUrlController.text.trim()
          : _aiEngine.baseUrl);
    }
  }

  Future<void> _persistBaseUrl(String value) async {
    await _secureStorage.saveBaseUrl(value.trim());
    _aiEngine.setBaseUrl(value.trim());
  }

  Future<void> _persistModelName(String value) async {
    await _secureStorage.saveModelName(value.trim());
    _aiEngine.setModel(value.trim());
  }

  // ─── Ollama 切换 ───
  Future<void> _toggleOllama(bool enabled) async {
    await _settings.setOllamaEnabled(enabled);
    if (enabled) {
      const ollamaUrl = 'http://localhost:11434/v1';
      _baseUrlController.text = ollamaUrl;
      await _secureStorage.saveBaseUrl(ollamaUrl);
      _aiEngine.setOllamaMode(model: _modelController.text.isNotEmpty ? _modelController.text : null);
    } else {
      _baseUrlController.text = _aiEngine.baseUrl;
    }
    if (mounted) setState(() {});
  }

  // ─── 选择 Ollama 模型 ───
  Future<void> _selectOllamaModel(ModelInfo model) async {
    _modelController.text = model.id;
    await _persistModelName(model.id);
    if (_settings.ollamaEnabled) {
      _aiEngine.setOllamaMode(model: model.id);
    }
    if (mounted) setState(() {});
  }

  // ─── 离线模式切换 ───
  Future<void> _toggleOfflineMode(bool enabled) async {
    await _settings.setOfflineMode(enabled);
  }

  // ─── 脱敏切换 ───
  Future<void> _toggleAnonymize(bool enabled) async {
    await _settings.setAnonymizeData(enabled);
  }

  // ──────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final isDark = theme.brightness == Brightness.dark;
    final isOffline = _settings.offlineMode;
    final isOllama = _settings.ollamaEnabled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('AI 服务',
            style: AppTypography.h2.copyWith(color: colors.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── API 基础设置 ──
          _buildSectionHeader('API 基础设置', colors),
          const SizedBox(height: 8),
          _buildApiBaseCard(colors, isDark, isOffline, isOllama),
          const SizedBox(height: 20),

          // ── Ollama 本地模式 ──
          _buildSectionHeader('Ollama 本地模式', colors),
          const SizedBox(height: 8),
          _buildOllamaCard(colors, isDark, isOffline),
          const SizedBox(height: 20),

          // ── 隐私与离线 ──
          _buildSectionHeader('隐私与离线', colors),
          const SizedBox(height: 8),
          _buildPrivacyCard(colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Section Header
  // ──────────────────────────────────────────────
  Widget _buildSectionHeader(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  API 基础设置 Card
  // ──────────────────────────────────────────────
  Widget _buildApiBaseCard(
    AppColorsExtension colors,
    bool isDark,
    bool isOffline,
    bool isOllama,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: colors.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── API Key ──
          _buildInputLabel('API Key', colors, required: !isOffline && !isOllama),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKeyController,
            obscureText: !_apiKeyVisible,
            enabled: !isOffline,
            style: AppTypography.body1.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: isOllama ? 'Ollama 模式无需 API Key' : '输入你的 API Key',
              hintStyle: AppTypography.body2.copyWith(
                  color: colors.textTertiary),
              suffixIcon: IconButton(
                icon: Icon(
                  _apiKeyVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
                onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
              ),
            ),
            onChanged: _persistApiKey,
          ),
          const SizedBox(height: AppDimensions.spaceMD),

          // ── Base URL ──
          _buildInputLabel('Base URL', colors, required: !isOffline),
          const SizedBox(height: 6),
          TextField(
            controller: _baseUrlController,
            enabled: !isOffline && !isOllama,
            style: AppTypography.body1.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: isOllama ? 'http://localhost:11434/v1' : 'https://api.deepseek.com/v1',
              hintStyle: AppTypography.body2.copyWith(
                  color: colors.textTertiary),
            ),
            onChanged: _persistBaseUrl,
          ),
          if (isOllama)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: colors.warning),
                  const SizedBox(width: 4),
                  Text('Ollama 模式下自动使用本地地址',
                      style: AppTypography.caption
                          .copyWith(color: colors.warning)),
                ],
              ),
            ),
          const SizedBox(height: AppDimensions.spaceMD),

          // ── Model Name ──
          _buildInputLabel('模型名称', colors, required: !isOffline),
          const SizedBox(height: 6),
          TextField(
            controller: _modelController,
            enabled: !isOffline,
            style: AppTypography.body1.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: isOllama ? 'llama3:8b' : 'deepseek-chat',
              hintStyle: AppTypography.body2.copyWith(
                  color: colors.textTertiary),
            ),
            onChanged: _persistModelName,
          ),
          const SizedBox(height: AppDimensions.spaceSM),

          // ── 云端模型快捷选择 ──
          if (!isOllama && !isOffline) ...[
            const SizedBox(height: AppDimensions.spaceXS),
            _buildCloudModelChips(colors),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  输入标签
  // ──────────────────────────────────────────────
  Widget _buildInputLabel(String label, AppColorsExtension colors,
      {bool required = false}) {
    return Row(
      children: [
        Text(label,
            style: AppTypography.label.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            )),
        if (required)
          Text(' *',
              style: AppTypography.label.copyWith(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.w500,
              )),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  云端模型快捷选择 Chip 组
  // ──────────────────────────────────────────────
  Widget _buildCloudModelChips(AppColorsExtension colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: AiEngine.availableCloudModels.map((model) {
        final isSelected = _modelController.text == model.id;
        return GestureDetector(
          onTap: () {
            _modelController.text = model.id;
            _persistModelName(model.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                  : colors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6B6B)
                    : colors.textTertiary.withValues(alpha: 0.3),
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model.provider,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textTertiary,
                    fontSize: 9,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  model.name,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_rounded,
                        size: 14, color: Color(0xFFFF6B6B)),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  //  Ollama 本地模式 Card
  // ──────────────────────────────────────────────
  Widget _buildOllamaCard(
    AppColorsExtension colors,
    bool isDark,
    bool isOffline,
  ) {
    final isOllama = _settings.ollamaEnabled;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: colors.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG, vertical: 2),
            title: Text('启用 Ollama 本地模式',
                style: AppTypography.body1.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text(
              '使用本地大模型，数据不出本机',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            value: !isOffline && isOllama,
            activeColor: const Color(0xFFFF6B6B),
            onChanged: isOffline
                ? null
                : (val) => _toggleOllama(val),
          ),
          if (isOllama && !isOffline) ...[
            Divider(
                color: colors.textTertiary.withValues(alpha: 0.12), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceLG, AppDimensions.spaceSM,
                  AppDimensions.spaceLG, AppDimensions.spaceSM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('本地可用模型',
                          style: AppTypography.label.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          setState(() => _loadingModels = true);
                          // 模拟刷新延迟
                          await Future.delayed(const Duration(milliseconds: 800));
                          if (mounted) setState(() => _loadingModels = false);
                        },
                        child: _loadingModels
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: const Color(0xFFFF6B6B),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      size: 14,
                                      color: const Color(0xFFFF6B6B)),
                                  const SizedBox(width: 4),
                                  Text('刷新',
                                      style: AppTypography.caption.copyWith(
                                          color: const Color(0xFFFF6B6B),
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildOllamaModelGrid(colors),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Ollama 模型网格
  // ──────────────────────────────────────────────
  Widget _buildOllamaModelGrid(AppColorsExtension colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ollamaModels.map((model) {
        final isSelected = _modelController.text == model.id;
        return GestureDetector(
          onTap: () => _selectOllamaModel(model),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B6B).withValues(alpha: 0.12)
                  : colors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6B6B)
                    : colors.textTertiary.withValues(alpha: 0.25),
                width: isSelected ? 1.2 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory_rounded,
                        size: 12,
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : colors.textTertiary),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: Color(0xFFFF6B6B)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  model.name,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                Text(
                  model.id,
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  //  隐私与离线 Card
  // ──────────────────────────────────────────────
  Widget _buildPrivacyCard(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: colors.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // ── 数据脱敏 ──
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG, vertical: 2),
            title: Text('发送前数据脱敏',
                style: AppTypography.body1.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text(
              '自动隐藏姓名、手机号、身份证号等敏感信息',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            value: _settings.anonymizeData,
            activeColor: const Color(0xFFFF6B6B),
            onChanged: _toggleAnonymize,
          ),
          Divider(
              color: colors.textTertiary.withValues(alpha: 0.12), height: 1),

          // ── 离线模式 ──
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceLG, vertical: 2),
            title: Text('离线模式',
                style: AppTypography.body1.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text(
              '阻断所有云端 AI 请求，仅使用本地 IntentRouter 处理',
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            value: _settings.offlineMode,
            activeColor: colors.warning,
            onChanged: _toggleOfflineMode,
          ),
          if (_settings.offlineMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(AppDimensions.spaceLG, 0,
                  AppDimensions.spaceLG, AppDimensions.spaceMD),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXS),
                  border: Border.all(
                      color: colors.warning.withValues(alpha: 0.3),
                      width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.offline_bolt_rounded,
                        size: 14, color: colors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('离线模式已启用，当前仅使用本地 IntentRouter 解析',
                          style: AppTypography.caption.copyWith(
                              color: colors.warning, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

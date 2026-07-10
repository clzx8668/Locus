import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/design_system.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsService _settings = getIt<SettingsService>();
  bool _appearanceExpanded = false;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('设置',
            style: AppTypography.h2.copyWith(color: colors.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildGroupHeader('通用', colors),
          const SizedBox(height: 8),
          _buildAppearanceTile(colors),
          const SizedBox(height: 24),
          _buildGroupHeader('数据', colors),
          const SizedBox(height: 8),
          _buildSimpleTile(
            icon: Icons.storage_outlined,
            title: '本地数据库管理',
            subtitle: '基于 Drift 的本地存储数据流控制',
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildGroupHeader('AI 服务', colors),
          const SizedBox(height: 8),
          _buildSimpleTile(
            icon: Icons.key,
            title: 'API Keys / 模型配置',
            subtitle: '本地 Ollama / 线上大模型对接',
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildGroupHeader('账户', colors),
          const SizedBox(height: 8),
          _buildSimpleTile(
            icon: Icons.account_circle_outlined,
            title: '私人助理档案',
            subtitle: '个人偏好与 AI 角色设定',
            colors: colors,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ============================================================
  // 分组标题
  // ============================================================
  Widget _buildGroupHeader(String title, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ============================================================
  // 普通设置项（不可展开）
  // ============================================================
  Widget _buildSimpleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorsExtension colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: colors.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B6B), size: 22),
        ),
        title: Text(title,
            style: AppTypography.body1.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: AppTypography.caption.copyWith(color: colors.textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: colors.textTertiary, size: 20),
      ),
    );
  }

  // ============================================================
  // 可展开设置项：主题与外观
  // ============================================================
  Widget _buildAppearanceTile(AppColorsExtension colors) {
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
          // 折叠标题行
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: const Icon(Icons.palette_outlined,
                  color: Color(0xFFFF6B6B), size: 22),
            ),
            title: Text('主题与外观',
                style: AppTypography.body1.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text(
              '${_settings.fontScaleLabel} · ${_settings.themeModeLabel} · ${_settings.colorThemeLabel(_settings.effectiveColorTheme)}',
              style:
                  AppTypography.caption.copyWith(color: colors.textSecondary),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _appearanceExpanded ? 0.5 : 0.0,
              child: Icon(Icons.expand_more_rounded,
                  color: colors.textTertiary, size: 18),
            ),
            onTap: () =>
                setState(() => _appearanceExpanded = !_appearanceExpanded),
          ),

          // 展开内容
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _appearanceExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.spaceLG, 0,
                  AppDimensions.spaceLG, AppDimensions.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                      color: colors.textTertiary.withValues(alpha: 0.15),
                      height: 1),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // ── 字体大小 ──
                  _buildSubHeader('字体大小', colors, subtitle: '调整全局文字显示比例'),
                  const SizedBox(height: 10),
                  _buildFontScaleSelector(colors),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ── 主题明暗 ──
                  _buildSubHeader('主题明暗', colors, subtitle: '控制应用整体的深浅色模式'),
                  const SizedBox(height: 10),
                  _buildThemeModeSelector(colors),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ── 深色模式配色 ──
                  _buildSubHeader('深色模式配色', colors, subtitle: '深色模式下使用的色彩方案'),
                  const SizedBox(height: 10),
                  _buildColorThemeSelector(isDarkMode: true, colors: colors),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ── 浅色模式配色 ──
                  _buildSubHeader('浅色模式配色', colors, subtitle: '浅色模式下使用的色彩方案'),
                  const SizedBox(height: 10),
                  _buildColorThemeSelector(isDarkMode: false, colors: colors),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 子标题
  // ============================================================
  Widget _buildSubHeader(String title, AppColorsExtension colors,
      {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.h3.copyWith(
                color: colors.textPrimary, fontWeight: FontWeight.w700)),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle,
                style:
                    AppTypography.body2.copyWith(color: colors.textSecondary)),
          ),
      ],
    );
  }

  // ============================================================
  // 字体大小选择器（刻度滑动条）
  // ============================================================
  Widget _buildFontScaleSelector(AppColorsExtension colors) {
    const scales = [0.85, 1.0, 1.15, 1.3];
    const labels = ['小', '默认', '大', '特大'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前值预览
          Row(
            children: [
              Text('预览',
                  style: AppTypography.caption
                      .copyWith(color: colors.textTertiary)),
              const Spacer(),
              Text(
                  '${(_settings.fontScale * 100).toInt()}% · ${_settings.fontScaleLabel}',
                  style: AppTypography.caption.copyWith(
                      color: const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // 滑块
          Row(
            children: [
              Text('A',
                  style: AppTypography.caption
                      .copyWith(color: colors.textTertiary, fontSize: 11)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xFFFF6B6B),
                    inactiveTrackColor:
                        colors.textTertiary.withValues(alpha: 0.3),
                    thumbColor: const Color(0xFFFF6B6B),
                    overlayColor:
                        const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    tickMarkShape:
                        const RoundSliderTickMarkShape(tickMarkRadius: 3),
                    activeTickMarkColor: Colors.white,
                    inactiveTickMarkColor:
                        colors.textTertiary.withValues(alpha: 0.5),
                    valueIndicatorColor: const Color(0xFFFF6B6B),
                    valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    showValueIndicator: ShowValueIndicator.onlyForDiscrete,
                  ),
                  child: Slider(
                    value: _settings.fontScale.clamp(0.85, 1.3),
                    min: 0.85,
                    max: 1.3,
                    divisions: 3,
                    label: '${(_settings.fontScale * 100).toInt()}%',
                    onChanged: (v) => _settings.setFontScale(v),
                  ),
                ),
              ),
              Text('A',
                  style: AppTypography.body1.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          // 刻度标签
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(labels.length, (i) {
                final isActive = (_settings.fontScale - scales[i]).abs() < 0.03;
                return Text(
                  labels[i],
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: isActive
                        ? const Color(0xFFFF6B6B)
                        : colors.textTertiary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 主题明暗选择器
  // ============================================================
  Widget _buildThemeModeSelector(AppColorsExtension colors) {
    final modes = [
      {
        'label': '跟随系统',
        'value': ThemeMode.system,
        'icon': Icons.brightness_auto
      },
      {
        'label': '浅色',
        'value': ThemeMode.light,
        'icon': Icons.light_mode_rounded
      },
      {'label': '深色', 'value': ThemeMode.dark, 'icon': Icons.dark_mode_rounded},
    ];

    return Row(
      children: modes.map((m) {
        final mode = m['value'] as ThemeMode;
        final isSelected = _settings.themeMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: m == modes.first ? 0 : 6, right: m == modes.last ? 0 : 6),
            child: GestureDetector(
              onTap: () => _settings.setThemeMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                      : colors.surface2,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textTertiary.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(m['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : colors.textSecondary),
                    const SizedBox(height: 3),
                    Text(m['label'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? const Color(0xFFFF6B6B)
                              : colors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 10,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // 色彩主题选择器
  // ============================================================
  Widget _buildColorThemeSelector({
    required bool isDarkMode,
    required AppColorsExtension colors,
  }) {
    final themes = isDarkMode
        ? [
            {
              'style': AppThemeStyle.dark,
              'label': '经典暗黑',
              'primary': const Color(0xFFFF6B6B),
              'bg': const Color(0xFF1A1A1A),
              'text': const Color(0xFFE0E0E0),
            }
          ]
        : [
            {
              'style': AppThemeStyle.light,
              'label': '经典明亮',
              'primary': const Color(0xFF212121),
              'bg': const Color(0xFFFFFFFF),
              'text': const Color(0xFF1A1A1A),
            },
            {
              'style': AppThemeStyle.celadonGreen,
              'label': '青瓷绿',
              'primary': const Color(0xFF5C8D73),
              'bg': const Color(0xFFE8EFEA),
              'text': const Color(0xFF2C3E35),
            },
            {
              'style': AppThemeStyle.nordicBlue,
              'label': '极地灰蓝',
              'primary': const Color(0xFF4A6FA5),
              'bg': const Color(0xFFE2E8F0),
              'text': const Color(0xFF1E293B),
            },
            {
              'style': AppThemeStyle.warmOatmeal,
              'label': '燕麦暖沙',
              'primary': const Color(0xFFD4A373),
              'bg': const Color(0xFFEAE4D9),
              'text': const Color(0xFF4A4036),
            },
            {
              'style': AppThemeStyle.roseBlush,
              'label': '玫瑰绯',
              'primary': const Color(0xFFE89598),
              'bg': const Color(0xFFF9ECEA),
              'text': const Color(0xFF3D2F2F),
            },
            {
              'style': AppThemeStyle.lavenderPurple,
              'label': '薰衣草紫',
              'primary': const Color(0xFF9B7EC4),
              'bg': const Color(0xFFEFECF7),
              'text': const Color(0xFF2F2E3D),
            },
            {
              'style': AppThemeStyle.matchaGreen,
              'label': '抹茶绿',
              'primary': const Color(0xFF7DAA7A),
              'bg': const Color(0xFFECF1EA),
              'text': const Color(0xFF2E3A2D),
            },
          ];

    final currentStyle =
        isDarkMode ? _settings.darkColorTheme : _settings.lightColorTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: themes.map((t) {
        final style = t['style'] as AppThemeStyle;
        final isSelected = currentStyle == style;
        final primary = t['primary'] as Color;
        final bg = t['bg'] as Color;
        final text = t['text'] as Color;

        return GestureDetector(
          onTap: () => _settings.setColorTheme(style, isDark: isDarkMode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 1))
                    ]
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1))
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  t['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: text,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

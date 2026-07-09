import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/design_system.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late final SettingsService _settings = getIt<SettingsService>();

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
        title: Text('主题与外观',
            style: AppTypography.h2.copyWith(color: colors.textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── 字体大小 ──
          _buildSectionHeader('字体大小', colors),
          const SizedBox(height: 4),
          Text(
            '调整全局文字显示比例',
            style: AppTypography.body2.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildFontScaleSelector(colors),
          const SizedBox(height: 28),

          // ── 主题明暗 ──
          _buildSectionHeader('主题明暗', colors),
          const SizedBox(height: 4),
          Text(
            '控制应用整体的深浅色模式',
            style: AppTypography.body2.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildThemeModeSelector(colors),
          const SizedBox(height: 28),

          // ── 深色模式配色 ──
          _buildSectionHeader('深色模式配色', colors),
          const SizedBox(height: 4),
          Text(
            '深色模式下使用的色彩方案',
            style: AppTypography.body2.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildColorThemeSelector(isDarkMode: true, colors: colors),
          const SizedBox(height: 28),

          // ── 浅色模式配色 ──
          _buildSectionHeader('浅色模式配色', colors),
          const SizedBox(height: 4),
          Text(
            '浅色模式下使用的色彩方案',
            style: AppTypography.body2.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildColorThemeSelector(isDarkMode: false, colors: colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ────────────────────────
  // 字体大小选择器
  // ────────────────────────
  Widget _buildFontScaleSelector(AppColorsExtension colors) {
    const options = [
      {'label': '小', 'scale': 0.85},
      {'label': '默认', 'scale': 1.0},
      {'label': '大', 'scale': 1.15},
      {'label': '特大', 'scale': 1.3},
    ];

    return Row(
      children: options.map((opt) {
        final scale = opt['scale'] as double;
        final isSelected = (_settings.fontScale - scale).abs() < 0.01;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: opt == options.first ? 0 : 6,
                right: opt == options.last ? 0 : 6),
            child: GestureDetector(
              onTap: () => _settings.setFontScale(scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                      : colors.surface1,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textTertiary.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      opt['label'] as String,
                      style: AppTypography.body1.copyWith(
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : colors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(scale * 100).toInt()}%',
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? const Color(0xFFFF6B6B).withValues(alpha: 0.7)
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ────────────────────────
  // 主题明暗选择器
  // ────────────────────────
  Widget _buildThemeModeSelector(AppColorsExtension colors) {
    final modes = [
      {
        'label': '跟随系统',
        'value': ThemeMode.system,
        'icon': Icons.brightness_auto
      },
      {'label': '浅色', 'value': ThemeMode.light, 'icon': Icons.light_mode},
      {'label': '深色', 'value': ThemeMode.dark, 'icon': Icons.dark_mode},
    ];

    return Row(
      children: modes.map((m) {
        final mode = m['value'] as ThemeMode;
        final isSelected = _settings.themeMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: m == modes.first ? 0 : 6,
                right: m == modes.last ? 0 : 6),
            child: GestureDetector(
              onTap: () => _settings.setThemeMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                      : colors.surface1,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF6B6B)
                        : colors.textTertiary.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      m['icon'] as IconData,
                      size: 22,
                      color: isSelected
                          ? const Color(0xFFFF6B6B)
                          : colors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m['label'] as String,
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? const Color(0xFFFF6B6B)
                            : colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ────────────────────────
  // 色彩主题选择器
  // ────────────────────────
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
          ];

    final currentStyle =
        isDarkMode ? _settings.darkColorTheme : _settings.lightColorTheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
            width: 88,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              border: Border.all(
                color: isSelected ? primary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1))
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(height: 6),
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

  Widget _buildSectionHeader(String title, AppColorsExtension colors) {
    return Text(
      title,
      style: AppTypography.h3.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

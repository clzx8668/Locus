import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/design_system.dart';

class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;

  static const _keyThemeMode = 'theme_mode';
  static const _keyLightColorTheme = 'light_color_theme';
  static const _keyDarkColorTheme = 'dark_color_theme';
  static const _keyFontScale = 'font_scale';

  // --- 状态 ---
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _lightColorTheme = AppThemeStyle.light;
  AppThemeStyle _darkColorTheme = AppThemeStyle.dark;
  double _fontScale = 1.0;

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get lightColorTheme => _lightColorTheme;
  AppThemeStyle get darkColorTheme => _darkColorTheme;
  double get fontScale => _fontScale;

  /// 当前激活的主题色系（根据当前明暗模式）
  AppThemeStyle get effectiveColorTheme {
    switch (_themeMode) {
      case ThemeMode.dark:
        return _darkColorTheme;
      case ThemeMode.light:
        return _lightColorTheme;
      case ThemeMode.system:
        // 系统模式下返回 dark 的色系用于 darkTheme，light 的用于 theme
        return _lightColorTheme;
    }
  }

  /// 字体缩放标签
  String get fontScaleLabel {
    if (_fontScale <= 0.85) return '小';
    if (_fontScale <= 1.0) return '默认';
    if (_fontScale <= 1.15) return '大';
    return '特大';
  }

  /// 主题模式标签
  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  /// 色系标签
  String colorThemeLabel(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.dark:
        return '经典暗黑';
      case AppThemeStyle.light:
        return '经典明亮';
      case AppThemeStyle.celadonGreen:
        return '青瓷绿';
      case AppThemeStyle.nordicBlue:
        return '极地灰蓝';
      case AppThemeStyle.warmOatmeal:
        return '燕麦暖沙';
    }
  }

  // --- 初始化 ---
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _parseThemeMode(_prefs!.getString(_keyThemeMode));
    _lightColorTheme =
        _parseColorTheme(_prefs!.getString(_keyLightColorTheme), false);
    _darkColorTheme =
        _parseColorTheme(_prefs!.getString(_keyDarkColorTheme), true);
    _fontScale = _prefs!.getDouble(_keyFontScale) ?? 1.0;
    notifyListeners();
  }

  // --- 设置方法 ---
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs?.setString(_keyThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setColorTheme(AppThemeStyle style,
      {required bool isDark}) async {
    if (isDark) {
      if (_darkColorTheme == style) return;
      _darkColorTheme = style;
      await _prefs?.setString(_keyDarkColorTheme, style.name);
    } else {
      if (_lightColorTheme == style) return;
      _lightColorTheme = style;
      await _prefs?.setString(_keyLightColorTheme, style.name);
    }
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    if ((_fontScale - scale).abs() < 0.01) return;
    _fontScale = scale;
    await _prefs?.setDouble(_keyFontScale, scale);
    notifyListeners();
  }

  // --- 解析 ---
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppThemeStyle _parseColorTheme(String? value, bool isDark) {
    if (value == null) return isDark ? AppThemeStyle.dark : AppThemeStyle.light;
    try {
      return AppThemeStyle.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return isDark ? AppThemeStyle.dark : AppThemeStyle.light;
    }
  }
}

import 'package:flutter/material.dart';

/// Runtime theme configuration that notifies listeners on change
class ThemeConfig extends ChangeNotifier {
  Color _primaryColor = const Color(0xFFFF6B6B);
  double _fontScale = 1.0;
  ThemeMode _themeMode = ThemeMode.system;

  Color get primaryColor => _primaryColor;
  double get fontScale => _fontScale;
  ThemeMode get themeMode => _themeMode;

  void update({Color? primaryColor, double? fontScale, ThemeMode? themeMode}) {
    bool changed = false;
    if (primaryColor != null && primaryColor != _primaryColor) { _primaryColor = primaryColor; changed = true; }
    if (fontScale != null && fontScale != _fontScale) { _fontScale = fontScale; changed = true; }
    if (themeMode != null && themeMode != _themeMode) { _themeMode = themeMode; changed = true; }
    if (changed) notifyListeners();
  }

  static const Map<String, Color> colorOptions = {
    'coral': Color(0xFFFF6B6B),
    'blue': Color(0xFF4A90D9),
    'green': Color(0xFF34C759),
    'purple': Color(0xFFAF52DE),
    'amber': Color(0xFFFF9500),
    'teal': Color(0xFF5AC8FA),
  };

  static const Map<String, String> colorNames = {
    'coral': 'Coral', 'blue': 'Ocean', 'green': 'Forest',
    'purple': 'Lavender', 'amber': 'Amber', 'teal': 'Teal',
  };

  static const Map<String, double> fontScales = {
    'small': 0.85, 'medium': 1.0, 'large': 1.15, 'xlarge': 1.3,
  };

  static const Map<String, String> fontScaleNames = {
    'small': 'Small', 'medium': 'Medium', 'large': 'Large', 'xlarge': 'X-Large',
  };
}

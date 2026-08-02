import 'package:flutter/material.dart';

class ThemeConfig extends ChangeNotifier {
  Color _primaryColor = TwentyTokens.coral;
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
    'coral': TwentyTokens.coral,
    'blue': TwentyTokens.blue,
    'green': TwentyTokens.green,
    'purple': TwentyTokens.purple,
    'amber': TwentyTokens.amber,
    'teal': TwentyTokens.teal,
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

// Twenty-inspired design tokens
class TwentyTokens {
  // Brand colors
  static const Color coral = Color(0xFFFF6B6B);
  static const Color blue = Color(0xFF4A90D9);
  static const Color green = Color(0xFF34C759);
  static const Color purple = Color(0xFFAF52DE);
  static const Color amber = Color(0xFFFF9500);
  static const Color teal = Color(0xFF5AC8FA);

  // Light mode surface colors
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPanel = Color(0xFFFCFCFC);
  static const Color lightBorder = Color(0xFFEBEBE8);
  static const Color lightDivider = Color(0xFFEEEEEC);

  // Dark mode surface colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkPanel = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF252525);

  // Text colors - light
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textMutedLight = Color(0xFFA0A0A0);

  // Text colors - dark
  static const Color textPrimaryDark = Color(0xFFF0F0F0);
  static const Color textSecondaryDark = Color(0xFF9A9A9A);
  static const Color textMutedDark = Color(0xFF6B6B6B);

  // Chip tokens
  static const Color chipBgLight = Color(0xFFF5F5F3);
  static const Color chipBorderLight = Color(0xFFDFDFDB);
  static const Color chipBgDark = Color(0xFF2A2A2A);
  static const Color chipBorderDark = Color(0xFF404040);

  // Kanban stage colors
  static const Color stageLead = Color(0xFF9E9E9E);
  static const Color stageContacted = Color(0xFF42A5F5);
  static const Color stageQuoting = Color(0xFFFFA726);
  static const Color stageNegotiation = Color(0xFFAB47BC);
  static const Color stageWon = Color(0xFF66BB6A);
  static const Color stageLost = Color(0xFFEF5350);

  // Spacing
  static const double panelWidth = 320;
  static const double paddingPage = 16;
  static const double paddingCard = 14;
  static const double gapSmall = 8;
  static const double gapMedium = 12;
  static const double gapLarge = 16;
  static const double sectionHeaderHeight = 46;
  static const double fieldRowHeight = 32;
  static const double listItemHeight = 34;

  // Border radius
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusPill = 999;

  // Typography
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;

  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
}

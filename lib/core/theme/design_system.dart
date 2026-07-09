
import 'package:flutter/material.dart';

// ==========================================
// 🔤 轴线一：字号与字体结构规范 (Typography Tokens)
// ==========================================
class AppTypography {
  static const String _fontFamily = 'System'; // 默认使用系统原生高质感字体

  // 1. 标题组 (Headings)
  static const TextStyle h1 = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.3,
      letterSpacing: -0.5,
      fontFamily: _fontFamily);
  static const TextStyle h2 = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.3,
      fontFamily: _fontFamily);
  static const TextStyle h3 = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      fontFamily: _fontFamily);

  // 2. 正文组 (Body - 针对长文本与结构化深度阅读进行行高优化)
  static const TextStyle body1 = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      height: 1.55,
      letterSpacing: 0.2,
      fontFamily: _fontFamily);
  static const TextStyle body2 = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      height: 1.45,
      letterSpacing: 0.1,
      fontFamily: _fontFamily);

  // 3. 辅助组 (Labels & Captions)
  static const TextStyle label = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      fontFamily: _fontFamily);
  static const TextStyle caption = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      height: 1.2,
      letterSpacing: 0.3,
      fontFamily: _fontFamily);
}

// ==========================================
// 📐 轴线二：空间度量与圆角规范 (Layout Tokens)
// ==========================================
class AppDimensions {
  // 圆角阶梯 (Border Radius)
  static const double radiusXS = 4.0; // 小标签、微型徽章
  static const double radiusSM = 8.0; // 嵌套小卡片、输入框、AI命令网格
  static const double radiusMD = 12.0; // 核心主卡片、时间轴卡片、追加按钮
  static const double radiusLG = 20.0; // 底部对话舱、大弹窗

  // 间距阶梯 (Padding & Margin)
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 24.0;
}

// ==========================================
// 🎨 轴线三：语义化多主题拓展 (Theme Extension)
// ==========================================
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color surface1; // 一级面板（普通卡片、弹窗背景）
  final Color surface2; // 二级面板（聚焦核心卡片，如闪念主卡）
  final Color textPrimary; // 一级核心正文（高对比度）
  final Color textSecondary; // 二级副正文（中对比度，摘要描述）
  final Color textTertiary; // 三级弱文本（低对比度，时间戳、边框）
  final Color success; // 业务合规/成功状态
  final Color warning; // 业务卡点/预警状态

  const AppColorsExtension({
    required this.surface1,
    required this.surface2,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? surface1,
    Color? surface2,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
  }) {
    return AppColorsExtension(
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
      ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// ==========================================
// 🏛️ 轴线四：系统主题总线织造 (Theme Factory)
// ==========================================
enum AppThemeStyle { dark, light, celadonGreen, nordicBlue, warmOatmeal }

class AppThemeSpecification {
  static ThemeData generate(AppThemeStyle style, {double fontScale = 1.0}) {
    switch (style) {
      // 1. 经典暗黑（深邃工作台）
      case AppThemeStyle.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFFF6B6B),
          background: const Color(0xFF121212),
          fontScale: fontScale,
          ext: const AppColorsExtension(
            surface1: Color(0xFF1A1A1A),
            surface2: Color(0xFF425A46), // 标志性深绿
            textPrimary: Color(0xFFE0E0E0),
            textSecondary: Color(0xFFA0A0A0),
            textTertiary: Color(0xFF444444),
            success: Color(0xFF34D399),
            warning: Color(0xFFFBBF24),
          ),
        );

      // 2. 经典明亮（高效纯白）
      case AppThemeStyle.light:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF212121),
          background: const Color(0xFFF8F9FA),
          fontScale: fontScale,
          ext: const AppColorsExtension(
            surface1: Color(0xFFFFFFFF),
            surface2: Color(0xFFF1F3F5),
            textPrimary: Color(0xFF1A1A1A),
            textSecondary: Color(0xFF666666),
            textTertiary: Color(0xFFDCDCDC),
            success: Color(0xFF10B981),
            warning: Color(0xFFF59E0B),
          ),
        );

      // 3. 青瓷绿（深度阅读、技术文档沉淀）
      case AppThemeStyle.celadonGreen:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF5C8D73),
          background: const Color(0xFFF4F7F4),
          fontScale: fontScale,
          ext: const AppColorsExtension(
            surface1: Color(0xFFFFFFFF),
            surface2: Color(0xFFE8EFEA),
            textPrimary: Color(0xFF2C3E35),
            textSecondary: Color(0xFF6B8074),
            textTertiary: Color(0xFFCCD7D0),
            success: Color(0xFF43A047),
            warning: Color(0xFFFB8C00),
          ),
        );

      // 4. 极地灰蓝（适合敏捷CRM、严谨合同与账目流转）
      case AppThemeStyle.nordicBlue:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF4A6FA5),
          background: const Color(0xFFF0F3F6),
          fontScale: fontScale,
          ext: const AppColorsExtension(
            surface1: Color(0xFFFFFFFF),
            surface2: Color(0xFFE2E8F0),
            textPrimary: Color(0xFF1E293B),
            textSecondary: Color(0xFF64748B),
            textTertiary: Color(0xFFCBD5E1),
            success: Color(0xFF2563EB),
            warning: Color(0xFFD97706),
          ),
        );

      // 5. 燕麦暖沙（温润人文、多模态随笔）
      case AppThemeStyle.warmOatmeal:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFFD4A373),
          background: const Color(0xFFFDFBF7),
          fontScale: fontScale,
          ext: const AppColorsExtension(
            surface1: Color(0xFFF5F2EB),
            surface2: Color(0xFFEAE4D9),
            textPrimary: Color(0xFF4A4036),
            textSecondary: Color(0xFF8C7E6D),
            textTertiary: Color(0xFFD1C7BD),
            success: Color(0xFF8B9A46),
            warning: Color(0xFFB35416),
          ),
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required AppColorsExtension ext,
    required double fontScale,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      extensions: [ext], // 🚀 将自定义拓展颜色注入系统管道

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: ext.surface1,
      ),

      // 统一导航栏规范
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ext.textPrimary, size: 20 * fontScale),
        titleTextStyle:
            AppTypography.h2.copyWith(color: ext.textPrimary).scale(fontScale),
      ),

      // 统一标准组件全局映射（应用字号缩放）
      textTheme: TextTheme(
        displayMedium:
            AppTypography.h1.copyWith(color: ext.textPrimary).scale(fontScale),
        titleMedium:
            AppTypography.h3.copyWith(color: ext.textPrimary).scale(fontScale),
        bodyLarge:
            AppTypography.body1.copyWith(color: ext.textPrimary).scale(fontScale),
        bodyMedium:
            AppTypography.body2.copyWith(color: ext.textPrimary).scale(fontScale),
        labelLarge:
            AppTypography.label.copyWith(color: ext.textPrimary).scale(fontScale),
      ),

      // 卡片通用规范
      cardTheme: CardThemeData(
        color: ext.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          side: BorderSide(
              color: ext.textTertiary.withValues(alpha: 0.3), width: 0.8),
        ),
      ),
    );
  }
}

// ==========================================
// 🔧 工具扩展：TextStyle 缩放
// ==========================================
extension TextStyleScale on TextStyle {
  TextStyle scale(double factor) {
    if (factor == 1.0) return this;
    return copyWith(
      fontSize: fontSize != null ? fontSize! * factor : null,
    );
  }
}

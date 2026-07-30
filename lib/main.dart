import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'core/database/database.dart';
import 'core/theme/theme_config.dart';
import 'features/home/presentation/locus_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setupLocator();

  final db = getIt<AppDatabase>();
  final config = getIt<ThemeConfig>();

  final colorKey = await db.getConfig('theme_color') ?? 'coral';
  final fontKey = await db.getConfig('font_scale') ?? 'medium';
  final modeKey = await db.getConfig('theme_mode') ?? 'system';

  config.update(
    primaryColor: ThemeConfig.colorOptions[colorKey],
    fontScale: ThemeConfig.fontScales[fontKey] ?? 1.0,
    themeMode: modeKey == 'light' ? ThemeMode.light : modeKey == 'dark' ? ThemeMode.dark : ThemeMode.system,
  );

  runApp(const LocusApp());
}

class LocusApp extends StatelessWidget {
  const LocusApp({super.key});

  static ThemeData _buildTheme(Brightness brightness, Color primary) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: brightness),
      hintColor: isDark ? Colors.white54 : Colors.black45,
      shadowColor: isDark ? Colors.transparent : Colors.black12,
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: isDark ? Colors.white70 : Colors.black87), titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemeConfig>(),
      builder: (context, _) {
        final config = getIt<ThemeConfig>();
        return MaterialApp(
          title: 'Locus',
          debugShowCheckedModeBanner: false,
          themeMode: config.themeMode,
          theme: _buildTheme(Brightness.light, config.primaryColor),
          darkTheme: _buildTheme(Brightness.dark, config.primaryColor),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(config.fontScale)),
              child: child!,
            );
          },
          home: const LocusHomePage(),
        );
      },
    );
  }
}

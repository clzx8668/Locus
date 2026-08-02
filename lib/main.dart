import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'core/database/database.dart';
import 'core/sync/sync_service.dart';
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

class LocusApp extends StatefulWidget {
  const LocusApp({super.key});

  @override
  State<LocusApp> createState() => _LocusAppState();
}

class _LocusAppState extends State<LocusApp> with WidgetsBindingObserver {
  static ThemeData _theme(Brightness b, Color primary) {
    bool d = b == Brightness.dark;
    return ThemeData(
      brightness: b,
      primaryColor: primary,
      scaffoldBackgroundColor: d ? TwentyTokens.darkBg : TwentyTokens.lightBg,
      cardColor: d ? TwentyTokens.darkCard : TwentyTokens.lightCard,
      dividerColor: d ? TwentyTokens.darkDivider : TwentyTokens.lightDivider,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: b),
      appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, iconTheme: IconThemeData(color: d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight), titleTextStyle: TextStyle(color: d ? TwentyTokens.textPrimaryDark : TwentyTokens.textPrimaryLight, fontSize: TwentyTokens.fontSizeLg, fontWeight: TwentyTokens.weightSemibold)),
      cardTheme: CardThemeData(elevation: 0, color: d ? TwentyTokens.darkCard : TwentyTokens.lightCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TwentyTokens.radiusLg), side: BorderSide(color: d ? TwentyTokens.darkBorder : TwentyTokens.lightBorder))),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(TwentyTokens.radiusMd)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), filled: true, fillColor: d ? TwentyTokens.darkPanel : TwentyTokens.lightCard),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize SyncService and restore persisted sync mode
    getIt<SyncService>().init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ss = getIt<SyncService>();
    if (ss.pbSyncMode != PbSyncMode.smart) return;

    if (state == AppLifecycleState.resumed && ss.autoConfig.syncOnResume) {
      // App came back to foreground — trigger sync
      ss.triggerPbSync();
    } else if (state == AppLifecycleState.paused && ss.autoConfig.syncOnPause) {
      // App going to background — best-effort quick push
      ss.triggerPbSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemeConfig>(),
      builder: (context, _) {
        final c = getIt<ThemeConfig>();
        return MaterialApp(
          title: 'Locus',
          debugShowCheckedModeBanner: false,
          themeMode: c.themeMode,
          theme: _theme(Brightness.light, c.primaryColor),
          darkTheme: _theme(Brightness.dark, c.primaryColor),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.fontScale)), child: child!),
          home: const LocusHomePage(),
        );
      },
    );
  }
}

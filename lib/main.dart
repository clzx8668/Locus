import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'core/theme/design_system.dart';
import 'core/services/settings_service.dart';
import 'features/home/presentation/locus_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量文件
  await dotenv.load(fileName: ".env");

  // 启动依赖注入中枢
  await setupLocator();

  runApp(const LocusApp());
}

class LocusApp extends StatefulWidget {
  const LocusApp({super.key});

  @override
  State<LocusApp> createState() => _LocusAppState();
}

class _LocusAppState extends State<LocusApp> {
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
    final s = _settings;
    return MaterialApp(
      title: 'Locus Hub',
      debugShowCheckedModeBanner: false,
      themeMode: s.themeMode,
      darkTheme: AppThemeSpecification.generate(s.darkColorTheme,
          fontScale: s.fontScale),
      theme: AppThemeSpecification.generate(s.lightColorTheme,
          fontScale: s.fontScale),
      home: const LocusHomePage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'features/timeline/presentation/timeline_page.dart';
import 'features/chat/presentation/chat_page.dart';
import 'features/home/presentation/locus_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量文件
  await dotenv.load(fileName: ".env");

  // 启动依赖注入中枢
  await setupLocator();

  runApp(const LocusApp());
}

class LocusApp extends StatelessWidget {
  const LocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus Hub',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2C2C2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B6B),
          surface: Color(0xFF2C2C2C),
        ),
        hintColor: Colors.white54,
        shadowColor: Colors.transparent,
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B6B),
          surface: Colors.white,
        ),
        hintColor: Colors.black45,
        shadowColor: Colors.black12,
      ),
      home: const LocusHomePage(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 这里的列表可以随时扩展，比如加上 FinancePage, CrmPage
  final List<Widget> _pages = const [
    TimelinePage(),
    ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locus', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_currentIndex], // 根据索引切换页面，无滑动冲突
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.stream),
            selectedIcon: Icon(Icons.stream, color: Colors.blueGrey),
            label: '闪念流',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI 枢纽',
          ),
          // 未来只需在这里加一行代码，就能增加新的底部 Tab
          // NavigationDestination(icon: Icon(Icons.pie_chart), label: '业务看板'),
        ],
      ),
    );
  }
}
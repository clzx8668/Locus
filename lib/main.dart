import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/service_locator.dart';
import 'features/timeline/presentation/timeline_page.dart';
import 'features/chat/presentation/chat_page.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
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
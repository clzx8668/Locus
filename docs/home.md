Locus 智能助理 - 首页多端自适应 UI 设计与重构需求文档
一、 整体视觉与响应式风格 (Overall & Responsive Style)
主题模式：支持浅色模式 (Light Theme)、深色模式 (Dark Theme) 及跟随系统。

自适应断点 (Breakpoint)：

移动端/竖屏模式 (Mobile/Portrait)：屏幕宽度 < 800px。采用上导航栏 + 下导航栏结构，便于单手大拇指操作。

桌面端/大屏横屏模式 (PC/Tablet/Landscape)：屏幕宽度 ≥ 800px。取消下导航栏，改用左侧固定导航菜单栏，释放垂直空间，适配鼠标点击。

视觉一致性：不论在何种模式下，卡片圆角（16）、品牌色（珊瑚红 Color(0xFFFF6B6B)）、字体层级和暗黑/明亮规则必须保持绝对统一。

二、 核心组件设计拆解 (Component Breakdown)
1. 竖屏模式 (Width < 800px) 组件布局
顶部导航栏：圆角矩形，包含：Logo、弹性搜索框("搜索或向AI提问")、AI图标、待办、列表切换、更多。

主体内容区：动态问候语 + 智能卡片滚动列表。

底部主导航栏：带有中央圆形凹槽（Notch）的 BottomAppBar，悬浮正中央的圆形加号键（FAB）。

2. 横屏/大屏模式 (Width ≥ 800px) 组件布局
左侧固定导航菜单 (Left Sidebar)：

形态：垂直长条侧边栏，宽度固定（如 72px 或 200px 展开态，本例采用精致的 80px 紧凑图文态）。背景色与卡片色一致（自适应主题）。

元素排列（从上至下）：

顶部：项目 Logo。

中间：垂直排列的导航项（首页、日历、消息、设置）。选中的项目使用品牌色高亮，并带有微弱的背景底色。

核心行动点（加号）：不再悬浮于底部，而是作为侧边栏的一个固定圆形大按钮，置于导航项之间或底部。

右侧主体内容区：

页面自动划分为左右结构。

顶部：搜索控制栏不再是独立的胶囊，而是拉伸自适应，或者作为右侧内容区的固定头部。

下方：动态问候语与卡片列表自动变为双列或更宽的网格/流式布局，完美利用屏幕宽度。

三、 Flutter 可直接运行的自适应代码
你可以直接用以下完整代码替换你的测试页面，它通过 LayoutBuilder 实时监听屏幕尺寸。你可以自由拉伸模拟器窗口或旋转手机屏幕，UI 会在瞬间平滑切换模式。

Dart
import 'package:flutter/material.dart';

void main() {
  runApp(const LocusAppTest());
}

class LocusAppTest extends StatefulWidget {
  const LocusAppTest({super.key});

  @override
  State<LocusAppTest> createState() => _LocusAppTestState();
}

class _LocusAppTestState extends State<LocusAppTest> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus AI',
      debugShowCheckedModeBanner: false,
      // 🌙 深色主题
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2C2C2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B6B),
          surface: Color(0xFF2C2C2C),
        ),
        hintColor: Colors.white54,
      ),
      // ☀️ 浅色主题
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
      themeMode: _themeMode,
      home: LocusHomePage(
        onThemeChanged: (ThemeMode mode) {
          setState(() {
            _themeMode = mode;
          });
        },
      ),
    );
  }
}

class LocusHomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const LocusHomePage({super.key, required this.onThemeChanged});

  @override
  State<LocusHomePage> createState() => _LocusHomePageState();
}

class _LocusHomePageState extends State<LocusHomePage> {
  int _currentNavIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '早上好';
    if (hour >= 12 && hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🌟 核心：使用 LayoutBuilder 获取当前窗口的最大宽度，实现多端感知
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth >= 800;

        return Scaffold(
          // 📱 只有在手机竖屏模式下，才激活底部的 FAB 悬浮加号按钮
          floatingActionButton: isLargeScreen
              ? null
              : FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFFFF6B6B),
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          // 📱 只有在手机竖屏模式下，才激活底部导航栏
          bottomNavigationBar: isLargeScreen
              ? null
              : BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8.0,
                  color: theme.cardColor,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem(0, Icons.home, '首页', theme),
                        _buildBottomNavItem(1, Icons.calendar_month, '日历', theme),
                        const SizedBox(width: 40), // 留给中央加号
                        _buildBottomNavItem(2, Icons.chat_bubble_outline, '消息', theme),
                        _buildBottomNavItem(3, Icons.settings, '设置', theme),
                      ],
                    ),
                  ),
                ),

          // 🧩 根据屏幕宽度，动态拼装整体 Body 架构
          body: SafeArea(
            child: Row(
              children: [
                // 💻 PC/大屏横屏模式：展示左侧固定侧边导航菜单
                if (isLargeScreen) _buildLeftSidebar(theme, isDark),

                // 主体内容区（无论是手机还是PC，这部分采用自适应拉伸）
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // 1. 顶部导航/搜索栏
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: theme.shadowColor,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                // 如果是小屏显示Logo，大屏由于左侧已有Logo，这里可以隐藏或变更为区域标题
                                Text(
                                  isLargeScreen ? '工作台' : 'Locus',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '搜索或向AI提问...',
                                    style: TextStyle(color: theme.hintColor, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.auto_awesome, color: Color(0xFFFF6B6B)),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.task_alt, color: theme.hintColor),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.format_list_bulleted, color: theme.hintColor),
                                  onPressed: () {},
                                ),
                                PopupMenuButton<ThemeMode>(
                                  icon: Icon(Icons.more_vert, color: theme.hintColor),
                                  onSelected: widget.onThemeChanged,
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: ThemeMode.light, child: Text('☀️ 浅色模式')),
                                    const PopupMenuItem(value: ThemeMode.dark, child: Text('🌙 深色模式')),
                                    const PopupMenuItem(value: ThemeMode.system, child: Text('💻 跟随系统')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. 问候语
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      // 3. 智能卡片列表（在大屏下自动变为双列网格，体验极佳）
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        sliver: isLargeScreen
                            ? SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // PC端一排显示2个卡片，充分利用横向空间
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 2.5,
                                ),
                                delegate: _buildCardSliverDelegate(),
                              )
                            : SliverList(
                                delegate: _buildCardSliverDelegate(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 💻 核心组件：PC端左侧固定侧边导航菜单栏
  Widget _buildLeftSidebar(ThemeData theme, bool isDark) {
    return Container(
      width: 80,
      color: theme.cardColor, // 与卡片颜色一致，形成良好的视觉块
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 顶部应用 Logo
          const CircleAvatar(
            backgroundColor: Color(0xFFFF6B6B),
            radius: 20,
            child: Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 32),
          
          // PC端的加号行动按钮，直接融入左侧栏
          FloatingActionButton(
            mini: true,
            onPressed: () {},
            backgroundColor: const Color(0xFFFF6B6B),
            elevation: 2,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 32),

          // 导航菜单项列表
          Expanded(
            child: Column(
              children: [
                _buildLeftSidebarItem(0, Icons.home, '首页'),
                _buildLeftSidebarItem(1, Icons.calendar_month, '日历'),
                _buildLeftSidebarItem(2, Icons.chat_bubble_outline, '消息'),
                _buildLeftSidebarItem(3, Icons.settings, '设置'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建左侧菜单单项
  Widget _buildLeftSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    final activeColor = const Color(0xFFFF6B6B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => setState(() => _currentNavIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            // 选中项有一个轻微的底色背景
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? activeColor : Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // 📱 构建手机端底部导航单项
  Widget _buildBottomNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _currentNavIndex == index;
    final activeColor = const Color(0xFFFF6B6B);

    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : theme.hintColor, size: 24),
          Text(label, style: TextStyle(fontSize: 11, color: isSelected ? activeColor : theme.hintColor)),
        ],
      ),
    );
  }

  // 数据卡片代理提取（复用给 ListView 和 GridView）
  SliverChildBuilderDelegate _buildCardSliverDelegate() {
    return SliverChildBuilderDelegate(
      (context, index) {
        final titles = ['测试哦', '测试一下', '碳化硅平板膜技术参数验证', '日常开销记账流水'];
        final contents = ['测试内容摘要叙述...', '主页样式重构与数据对齐测试...', '耐强酸强碱、结构科学，下午已完成第一批切片入库...', '完成今日财务流水严谨性对账...'];
        final times = ['6月18日 13:12', '6月18日 12:56', '6月21日 20:15', '6月21日 21:00'];
        final colors = [Colors.green, Colors.teal, Colors.orange, Colors.blue];
        final itemIndex = index % titles.length;
        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: theme.brightness == Brightness.dark
                ? null
                : [BoxShadow(color: theme.shadowColor, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(color: colors[itemIndex], borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(times[itemIndex], style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(titles[itemIndex], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  contents[itemIndex],
                  style: TextStyle(fontSize: 14, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
      childCount: 8,
    );
  }
}
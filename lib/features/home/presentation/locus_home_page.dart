import 'package:flutter/material.dart';
import 'widgets/quick_input_bottom_sheet.dart';
import '../../idea_stream/presentation/pages/idea_stream_page.dart';
import '../../calendar/presentation/pages/calendar_page.dart';
import '../../ai_hub/presentation/pages/ai_hub_page.dart';
import '../../settings/presentation/pages/settings_page.dart';

class LocusHomePage extends StatefulWidget {
  const LocusHomePage({super.key});

  @override
  State<LocusHomePage> createState() => _LocusHomePageState();
}

class _LocusHomePageState extends State<LocusHomePage> {
  int _currentIndex = 0;

  // 核心四大页面分发
  final List<Widget> _pages = [
    const IdeaStreamPage(),
    const CalendarPage(),
    const AiHubPage(),
    const SettingsPage(),
  ];

  // --- 🪐 悬浮按钮核心状态机 ---
  bool _isRightSide = true;
  bool _isCollapsed = false;
  double? _dragX;
  bool _isDragging = false;

  final double _buttonSize = 56.0;
  final double _collapsedVisibleWidth = 14.0;
  final double _bottomOffset = 100.0; // 小屏悬浮按钮距离底部的高度

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 获取当前屏幕总宽度，据此判断大小屏方案
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth >= 800; // 宽屏/PC端断点

    // 侧边栏固定宽度
    const double sidebarWidth = 220.0;
    // 动态计算悬浮按钮的可用活动宽度边界
    final double contentAreaWidth =
        isLargeScreen ? screenWidth - sidebarWidth : screenWidth;

    // 计算悬浮按钮在其父容器内部的 Left 坐标
    double leftPosition;
    if (_isDragging && _dragX != null) {
      leftPosition = _dragX!.clamp(0.0, contentAreaWidth - _buttonSize);
    } else {
      if (_isRightSide) {
        leftPosition = _isCollapsed
            ? contentAreaWidth - _collapsedVisibleWidth
            : contentAreaWidth - _buttonSize - 24.0;
      } else {
        leftPosition = _isCollapsed
            ? -(_buttonSize - _collapsedVisibleWidth)
            : 24.0;
      }
    }

    // 核心工作台 Stack（内容页 + 灵动悬浮按钮）
    Widget mainContentStack = Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),

        // 灵动悬浮按钮控制层
        AnimatedPositioned(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          left: leftPosition,
          bottom: isLargeScreen
              ? 32.0
              : _bottomOffset, // 大屏不需要躲避底栏，可以更靠底
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              setState(() {
                _isDragging = true;
                _dragX = leftPosition;
              });
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragX = (_dragX ?? leftPosition) + details.delta.dx;
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                _isDragging = false;
                final currentCenterX = _dragX! + (_buttonSize / 2);
                final velocityX = details.velocity.pixelsPerSecond.dx;

                if (velocityX > 300) {
                  _isRightSide = true;
                } else if (velocityX < -300) {
                  _isRightSide = false;
                } else {
                  _isRightSide = currentCenterX > (contentAreaWidth / 2);
                }

                if (_isRightSide &&
                    (velocityX > 200 ||
                        _dragX! > (contentAreaWidth - _buttonSize - 5))) {
                  _isCollapsed = true;
                } else if (!_isRightSide &&
                    (velocityX < -200 || _dragX! < 5)) {
                  _isCollapsed = true;
                } else {
                  _isCollapsed = false;
                }
                _dragX = null;
              });
            },
            onTap: () {
              if (_isCollapsed) {
                setState(() => _isCollapsed = false);
              } else {
                _openQuickInputConsole(context);
              }
            },
            child: Opacity(
              opacity: _isCollapsed ? 0.5 : 1.0,
              child: Container(
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns:
                        _isCollapsed ? (_isRightSide ? -0.25 : 0.25) : 0.0,
                    child: Icon(
                      _isCollapsed
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.add_rounded,
                      color: Colors.white,
                      size: _isCollapsed ? 16 : 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // --- 🪐 最终呈现：根据双端环境渲染不同骨架 ---
    if (isLargeScreen) {
      // 💻 PC大屏模式：左右并排分流
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : Colors.grey[100],
        body: Row(
          children: [
            // 1. 左侧独立质感深色导航菜单
            _buildDesktopSidebar(context, sidebarWidth, isDark),
            // 2. 右侧饱满的工作台内容区
            Expanded(
              child: mainContentStack,
            ),
          ],
        ),
      );
    } else {
      // 📱 手机小屏模式：上下堆叠，带底部扁平导航栏
      return Scaffold(
        extendBody: true,
        body: mainContentStack,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Theme(
            data: theme.copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              elevation: 0,
              backgroundColor:
                  isDark ? const Color(0xFF1E1E1E) : Colors.white,
              surfaceTintColor: Colors.transparent,
              height: 66,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.flash_on_outlined),
                    selectedIcon:
                        Icon(Icons.flash_on, color: Color(0xFFFF6B6B)),
                    label: '闪念'),
                NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon:
                        Icon(Icons.calendar_month, color: Color(0xFFFF6B6B)),
                    label: '日历'),
                NavigationDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon:
                        Icon(Icons.hub, color: Color(0xFFFF6B6B)),
                    label: 'AI枢纽'),
                NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon:
                        Icon(Icons.settings, color: Color(0xFFFF6B6B)),
                    label: '设置'),
              ],
            ),
          ),
        ),
      );
    }
  }

  // 🎨 大屏左侧质感侧边栏（极客深灰基调 + L徽标 + 胶囊选中态）
  Widget _buildDesktopSidebar(
      BuildContext context, double width, bool isDark) {
    final sidebarBgColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFF212121);

    final menuItems = [
      {'label': '闪念', 'icon': Icons.flash_on},
      {'label': '日历', 'icon': Icons.calendar_month},
      {'label': 'AI枢纽', 'icon': Icons.hub_outlined},
      {'label': '设置', 'icon': Icons.settings},
    ];

    return Container(
      width: width,
      height: double.infinity,
      color: sidebarBgColor,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 顶部红色极简 L 徽标
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 40, top: 10),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'L',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
          ),

          // 2. 纵向核心菜单列表
          Expanded(
            child: ListView.separated(
              itemCount: menuItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bool isSelected = _currentIndex == index;
                final item = menuItems[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFFFF6B6B)
                              : Colors.grey[400],
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey[300],
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openQuickInputConsole(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickInputBottomSheet(),
    );
  }
}

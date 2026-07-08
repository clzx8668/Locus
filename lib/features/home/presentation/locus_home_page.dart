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

  List<Widget> get _pages => [
        IdeaStreamPage(onNavigate: (index) => setState(() => _currentIndex = index)),
        const CalendarPage(),
        const AiHubPage(),
        const SettingsPage(),
      ];

  bool _isRightSide = true;
  bool _isCollapsed = false;
  double? _dragX;
  bool _isDragging = false;

  final double _buttonSize = 56.0;
  final double _collapsedVisibleWidth = 14.0;
  final double _bottomOffset = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 960;
    final bool isLargeScreen = screenWidth >= 960;

    double sidebarWidth = 0.0;
    if (isLargeScreen) sidebarWidth = 220.0;
    if (isMediumScreen) sidebarWidth = 70.0;

    final double contentAreaWidth = screenWidth - sidebarWidth;

    double leftPosition;
    if (_isDragging && _dragX != null) {
      leftPosition = _dragX!.clamp(0.0, contentAreaWidth - _buttonSize);
    } else {
      if (_isRightSide) {
        leftPosition = _isCollapsed
            ? contentAreaWidth - _collapsedVisibleWidth
            : contentAreaWidth - _buttonSize - 24.0;
      } else {
        leftPosition =
            _isCollapsed ? -(_buttonSize - _collapsedVisibleWidth) : 24.0;
      }
    }

    Widget mainContentStack = Stack(
      children: [
        IndexedStack(index: _currentIndex, children: _pages),
        AnimatedPositioned(
          duration:
              _isDragging ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          left: leftPosition,
          bottom: !isSmallScreen ? 32.0 : _bottomOffset,
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
                } else if (!_isRightSide && (velocityX < -200 || _dragX! < 5)) {
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
                    turns: _isCollapsed ? (_isRightSide ? -0.25 : 0.25) : 0.0,
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

    if (!isSmallScreen) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        body: Row(
          children: [
            _buildSidebarContent(context, sidebarWidth, isDark, isMediumScreen),
            Expanded(child: mainContentStack),
          ],
        ),
      );
    } else {
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
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              surfaceTintColor: Colors.transparent,
              height: 48,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
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
                    selectedIcon: Icon(Icons.hub, color: Color(0xFFFF6B6B)),
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

  Widget _buildSidebarContent(
      BuildContext context, double width, bool isDark, bool isMedium) {
    final sidebarBgColor =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFF212121);

    final menuItems = [
      {'label': '首页', 'icon': Icons.flash_on},
      {'label': '日历', 'icon': Icons.calendar_month},
      {'label': 'AI枢纽', 'icon': Icons.hub},
      {'label': '设置', 'icon': Icons.settings},
    ];

    return Container(
      width: width,
      height: double.infinity,
      color: sidebarBgColor,
      padding:
          EdgeInsets.symmetric(vertical: 24, horizontal: isMedium ? 8 : 16),
      child: Column(
        crossAxisAlignment:
            isMedium ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: isMedium
                ? const EdgeInsets.only(bottom: 32, top: 8)
                : const EdgeInsets.only(left: 12, bottom: 32, top: 8),
            child: Container(
              width: isMedium ? 38 : 46,
              height: isMedium ? 38 : 46,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(isMedium ? 10 : 12),
              ),
              child: const Center(
                child: Text(
                  'L',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bool isSelected = _currentIndex == index;
                final item = menuItems[index];

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMedium ? 0 : 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isMedium
                        ? Center(
                            child: Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.grey[400],
                              size: 22,
                            ),
                          )
                        : Row(
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
                                  fontSize: 14,
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

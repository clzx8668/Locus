import 'package:flutter/material.dart';
import 'widgets/quick_input_bottom_sheet.dart';
import '../../../core/theme/design_system.dart';
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
        IdeaStreamPage(
            onNavigate: (index) => setState(() => _currentIndex = index)),
        const CalendarPage(),
        const AiHubPage(),
        const SettingsPage(),
      ];

  bool _isRightSide = true;
  bool _isCollapsed = false;
  double? _dragX;
  bool _isDragging = false;
  bool _sidebarExpanded = true;

  final double _buttonSize = 56.0;
  final double _collapsedVisibleWidth = 14.0;
  final double _bottomOffset = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.extension<AppColorsExtension>()!;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 960;
    final bool isLargeScreen = screenWidth >= 960;

    final double effectiveSidebarWidth = !isSmallScreen
        ? (isLargeScreen && _sidebarExpanded ? 220.0 : 70.0)
        : 0.0;

    final double contentAreaWidth = screenWidth - effectiveSidebarWidth;

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
      final bool isSidebarCollapsed = isMediumScreen || !_sidebarExpanded;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            if (isLargeScreen || isMediumScreen)
              _buildSidebarContent(
                  context, effectiveSidebarWidth, isSidebarCollapsed,
                  isLargeScreen: isLargeScreen),
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
              backgroundColor:
                  isDark ? const Color(0xFF1E1E1E) : colors.surface1,
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

  Widget _buildSidebarContent(BuildContext context, double width, bool isMedium,
      {required bool isLargeScreen}) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    final menuItems = [
      {'label': '首页', 'icon': Icons.flash_on},
      {'label': '日历', 'icon': Icons.calendar_month},
      {'label': 'AI枢纽', 'icon': Icons.hub},
      {'label': '设置', 'icon': Icons.settings},
    ];

    return Container(
      width: width,
      height: double.infinity,
      color: colors.surface1,
      padding: EdgeInsets.symmetric(
          vertical: AppDimensions.spaceXL,
          horizontal: isMedium ? AppDimensions.spaceSM : AppDimensions.spaceLG),
      child: Column(
        crossAxisAlignment:
            isMedium ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (isLargeScreen && !isMedium)
            // 展开状态：Logo + 收起按钮在同一行
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppDimensions.spaceXL, top: AppDimensions.spaceSM),
              child: Row(
                children: [
                  const SizedBox(width: AppDimensions.spaceMD),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: const Center(
                      child: Text('L',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceSM),
                      child: Icon(Icons.chevron_left_rounded,
                          color: colors.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
            )
          else if (isLargeScreen)
            // 收起状态：Logo + 展开按钮纵向排列
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppDimensions.spaceXL, top: AppDimensions.spaceSM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: const Center(
                      child: Text('L',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS + 2),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceXS),
                      child: Icon(Icons.chevron_right_rounded,
                          color: colors.textSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            )
          else
            // 中屏：仅 Logo 居中
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppDimensions.spaceXL, top: AppDimensions.spaceSM),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: const Center(
                  child: Text('L',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.spaceSM + 2),
              itemBuilder: (context, index) {
                final bool isSelected = _currentIndex == index;
                final item = menuItems[index];

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMedium ? 0 : AppDimensions.spaceLG,
                        vertical: AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: isMedium
                        ? Center(
                            child: Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFFFF6B6B)
                                  : colors.textSecondary,
                              size: 22,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? const Color(0xFFFF6B6B)
                                    : colors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: AppDimensions.spaceLG),
                              Text(
                                item['label'] as String,
                                style: AppTypography.body2.copyWith(
                                  color: isSelected
                                      ? const Color(0xFFFF6B6B)
                                      : colors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
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

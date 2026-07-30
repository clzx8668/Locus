import 'package:flutter/material.dart';
import 'widgets/quick_input_bottom_sheet.dart';
import '../../idea_stream/presentation/pages/idea_stream_page.dart';
import '../../calendar/presentation/pages/calendar_page.dart';
import '../../ai_hub/presentation/pages/ai_hub_page.dart';
import '../../settings/presentation/pages/settings_page.dart';
import '../../contacts/presentation/pages/crm_page.dart';

class LocusHomePage extends StatefulWidget {
  const LocusHomePage({super.key});
  @override
  State<LocusHomePage> createState() => _LocusHomePageState();
}

class _LocusHomePageState extends State<LocusHomePage> {
  int _cur = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      IdeaStreamPage(onNavigate: (i) => setState(() => _cur = i)),
      const CrmPage(),
      const CalendarPage(),
      const AiHubPage(),
      const SettingsPage(),
    ];
  }

  bool _right = true;
  bool _collapsed = false;
  double? _dragX;
  bool _dragging = false;
  final double _sz = 56.0;
  final double _vis = 14.0;
  final double _bot = 100.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sw = MediaQuery.of(context).size.width;
    final bool small = sw < 600;
    final bool med = sw >= 600 && sw < 960;
    final bool large = sw >= 960;
    double sidW = 0;
    if (large) sidW = 220;
    if (med) sidW = 70;
    final caW = sw - sidW;

    double lp;
    if (_dragging && _dragX != null) {
      lp = _dragX!.clamp(0.0, caW - _sz);
    } else {
      if (_right) {
        lp = _collapsed ? caW - _vis : caW - _sz - 24;
      } else {
        lp = _collapsed ? -(_sz - _vis) : 24;
      }
    }

    Widget stack = Stack(children: [
      IndexedStack(index: _cur, children: _pages),
      AnimatedPositioned(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        left: lp,
        bottom: small ? _bot : 32,
        child: GestureDetector(
          onHorizontalDragStart: (_) {
            setState(() { _dragging = true; _dragX = lp; });
          },
          onHorizontalDragUpdate: (d) {
            setState(() => _dragX = (_dragX ?? lp) + d.delta.dx);
          },
          onHorizontalDragEnd: (d) {
            setState(() {
              _dragging = false;
              final cx = _dragX! + _sz / 2;
              final vx = d.velocity.pixelsPerSecond.dx;
              if (vx > 300) {
                _right = true;
              } else if (vx < -300) {
                _right = false;
              } else {
                _right = cx > caW / 2;
              }
              if (_right && (vx > 200 || _dragX! > caW - _sz - 5)) {
                _collapsed = true;
              } else if (!_right && (vx < -200 || _dragX! < 5)) {
                _collapsed = true;
              } else {
                _collapsed = false;
              }
              _dragX = null;
            });
          },
          onTap: () {
            if (_collapsed) {
              setState(() => _collapsed = false);
            } else {
              _openInput(context);
            }
          },
          child: Opacity(
            opacity: _collapsed ? 0.5 : 1.0,
            child: Container(
              width: _sz,
              height: _sz,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _collapsed ? (_right ? -0.25 : 0.25) : 0,
                  child: Icon(
                    _collapsed ? Icons.arrow_back_ios_new_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: _collapsed ? 16 : 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);

    if (!small) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        body: Row(children: [
          _sidebar(isDark, med, sidW),
          Expanded(child: stack),
        ]),
      );
    } else {
      return Scaffold(
        extendBody: true,
        body: stack,
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
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: NavigationBar(
              selectedIndex: _cur,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              surfaceTintColor: Colors.transparent,
              height: 48,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              onDestinationSelected: (i) => setState(() => _cur = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.flash_on_outlined), selectedIcon: Icon(Icons.flash_on, color: Color(0xFFFF6B6B)), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: Color(0xFFFF6B6B)), label: 'CRM'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: Color(0xFFFF6B6B)), label: 'Calendar'),
                NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub, color: Color(0xFFFF6B6B)), label: 'AI'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFFFF6B6B)), label: 'Settings'),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _sidebar(bool isDark, bool med, double w) {
    final p = Theme.of(context).colorScheme.primary;
    final items = [
      {'label': 'Home', 'icon': Icons.flash_on},
      {'label': 'CRM', 'icon': Icons.people},
      {'label': 'Calendar', 'icon': Icons.calendar_month},
      {'label': 'AI Hub', 'icon': Icons.hub},
      {'label': 'Settings', 'icon': Icons.settings},
    ];
    return Container(
      width: w,
      height: double.infinity,
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF212121),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: med ? 8 : 16),
      child: Column(
        crossAxisAlignment: med ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: med ? const EdgeInsets.only(bottom: 32, top: 8) : const EdgeInsets.only(left: 12, bottom: 32, top: 8),
            child: Container(
              width: med ? 38 : 46,
              height: med ? 38 : 46,
              decoration: BoxDecoration(color: p, borderRadius: BorderRadius.circular(med ? 10 : 12)),
              child: const Center(child: Text('L', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
            ),
          ),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final sel = _cur == i;
                final item = items[i];
                return GestureDetector(
                  onTap: () => setState(() => _cur = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(horizontal: med ? 0 : 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? p.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: med
                        ? Center(child: Icon(item['icon'] as IconData, color: sel ? p : Colors.grey[400], size: 22))
                        : Row(children: [
                            Icon(item['icon'] as IconData, color: sel ? p : Colors.grey[400], size: 22),
                            const SizedBox(width: 16),
                            Text(item['label'] as String, style: TextStyle(color: sel ? p : Colors.grey[300], fontSize: 14, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                          ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickInputBottomSheet(),
    );
  }
}

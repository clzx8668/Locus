import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import 'package:locus/features/home/presentation/idea_detail_page.dart';

class IdeaStreamPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const IdeaStreamPage({super.key, this.onNavigate});
  @override
  State<IdeaStreamPage> createState() => _IdeaStreamPageState();
}

class _IdeaStreamPageState extends State<IdeaStreamPage> {
  final db = getIt<AppDatabase>();
  final GlobalKey<ScaffoldState> _sk = GlobalKey();
  String _q = ''; bool _grid = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sw = MediaQuery.of(context).size.width;
    final large = sw >= 960;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      key: _sk,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      drawer: large ? null : _drawer(isDark, primary),
      body: SafeArea(bottom: false, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _topBar(isDark, large),
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 4), child: Text(_greet(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
        // Quick actions
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 4), child: _quickActions(primary, isDark)),
        const SizedBox(height: 8),
        Expanded(child: StreamBuilder<List<HubPayload>>(stream: db.watchAllPayloads(), builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var items = snap.data!.where((i) => i.rawText.toLowerCase().contains(_q.toLowerCase()) || i.intentTag.toLowerCase().contains(_q.toLowerCase())).toList();
          if (items.isEmpty) return Center(child: Text('No records', style: TextStyle(color: Theme.of(context).hintColor)));
          final useG = _grid || large;
          return useG ? GridView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: large ? 3 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4), itemCount: items.length, itemBuilder: (_, i) => _card(items[i], isDark, primary)) : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _card(items[i], isDark, primary));
        })),
      ])))),
    );
  }

  Widget _topBar(bool isDark, bool large) {
    final sw = MediaQuery.of(context).size.width;
    final small = sw < 600;
    return Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF262626) : const Color(0x1E000000), width: 1))), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (small) ...[IconButton(icon: const Icon(Icons.menu_rounded, size: 20), onPressed: () => _sk.currentState?.openDrawer(), padding: EdgeInsets.zero, constraints: const BoxConstraints()), const SizedBox(width: 8)],
      Expanded(child: Container(height: 30, decoration: BoxDecoration(color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Icon(Icons.search_rounded, color: Colors.grey[500], size: 14), const SizedBox(width: 4), Expanded(child: TextField(onChanged: (v) => setState(() => _q = v), textAlignVertical: TextAlignVertical.center, style: const TextStyle(fontSize: 12), decoration: InputDecoration(hintText: 'Search or ask AI...', hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)))]))),
      const SizedBox(width: 10),
      Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent[200], size: 16),
      const SizedBox(width: 10),
      IconButton(icon: Icon(_grid ? Icons.view_headline_rounded : Icons.dashboard_customize_outlined, color: _grid ? Theme.of(context).colorScheme.primary : Colors.grey[400], size: 18), onPressed: () => setState(() => _grid = !_grid), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    ]));
  }

  Widget _quickActions(Color primary, bool isDark) {
    final actions = [
      {'icon': Icons.note_add_outlined, 'label': 'Note', 'color': primary},
      {'icon': Icons.people_outline, 'label': 'CRM', 'color': const Color(0xFFFF6B6B)},
      {'icon': Icons.task_alt, 'label': 'Task', 'color': Colors.orange},
      {'icon': Icons.calendar_today, 'label': 'Calendar', 'color': Colors.purple},
      {'icon': Icons.receipt_long, 'label': 'Ledger', 'color': Colors.green},
      {'icon': Icons.inventory_2, 'label': 'Stock', 'color': Colors.blue},
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: actions.map((a) => InkWell(onTap: () {}, borderRadius: BorderRadius.circular(10), child: Container(width: 80, height: 72, decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(a['icon'] as IconData, color: a['color'] as Color, size: 22), const SizedBox(height: 4), Text(a['label'] as String, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54))])))).toList());
  }

  Widget _card(HubPayload data, bool isDark, Color primary) {
    final tag = data.intentTag;
    final paths = _img(data.mediaPaths);
    final ds = '${data.createdAt.month}/${data.createdAt.day} ${data.createdAt.hour.toString().padLeft(2, '0')}:${data.createdAt.minute.toString().padLeft(2, '0')}';
    return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IdeaDetailPage(payload: data))), borderRadius: BorderRadius.circular(14), child: Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(ds, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 10)), if (tag.isNotEmpty && tag != 'NOTE') Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)), child: Text(tag, style: TextStyle(color: primary, fontSize: 8, fontWeight: FontWeight.bold)))],),
      const SizedBox(height: 8),
      if (paths.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(paths.first), height: 90, width: double.infinity, fit: BoxFit.cover)),
      if (paths.isNotEmpty) const SizedBox(height: 8),
      Text(data.rawText.isEmpty ? 'Quick record' : data.rawText, maxLines: _grid ? 3 : 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500)),
    ])));
  }

  List<String> _img(String j) { try { final d = jsonDecode(j); if (d is List) return d.cast<String>(); } catch (_) {} return []; }

  Widget _drawer(bool isDark, Color primary) {
    final items = [{'label': 'Home', 'icon': Icons.flash_on}, {'label': 'CRM', 'icon': Icons.people}, {'label': 'Calendar', 'icon': Icons.calendar_month}, {'label': 'AI Hub', 'icon': Icons.hub}, {'label': 'Settings', 'icon': Icons.settings}];
    return Drawer(backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF212121), child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 28, top: 24, bottom: 32), child: Container(width: 46, height: 46, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('L', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))))),
      Expanded(child: ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(leading: Icon(item['icon'] as IconData, color: Colors.grey[400], size: 22), title: Text(item['label'] as String, style: TextStyle(color: Colors.grey[300], fontSize: 15)), onTap: () { widget.onNavigate?.call(i); Navigator.pop(context); });
      })),
    ])));
  }

  String _greet() { final h = DateTime.now().hour; if (h < 12) return 'Good morning'; if (h < 18) return 'Good afternoon'; return 'Good evening'; }
}

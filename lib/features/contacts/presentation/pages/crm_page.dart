import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/database.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});
  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> with SingleTickerProviderStateMixin {
  AppDatabase get db => getIt<AppDatabase>();
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('CRM'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black45,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Companies'),
            Tab(text: 'Pipeline'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: const [
        _ContactsTab(),
        _CompaniesTab(),
        _DealsTab(),
      ]),
    );
  }
}

// ==================== Contacts Tab ====================
class _ContactsTab extends StatefulWidget { const _ContactsTab(); @override State<_ContactsTab> createState() => _ContactsTabState(); }
class _ContactsTabState extends State<_ContactsTab> {
  AppDatabase get db => getIt<AppDatabase>();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  String _q = '';

  @override void dispose() { _searchCtrl.dispose(); _nameCtrl.dispose(); _companyCtrl.dispose(); super.dispose(); }

  void _add() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('New Contact'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder(), isDense: true)), const SizedBox(height: 10),
      TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder(), isDense: true)),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ElevatedButton(onPressed: () async { if (_nameCtrl.text.trim().isEmpty) return; await db.addContact(name: _nameCtrl.text.trim(), company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim()); _nameCtrl.clear(); _companyCtrl.clear(); if (ctx.mounted) Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white), child: const Text('Add')),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Contact>>(stream: db.watchAllContacts(), builder: (ctx, snap) {
      final contacts = snap.data ?? [];
      return Column(children: [
        // Stats bar
        _statsBar(contacts, isDark),
        // Search
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 8), child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() => _q = v), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: 'Search contacts...', hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.grey[500]), prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white30 : Colors.grey[500]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), isDense: true))),
        // List
        Expanded(child: _q.isEmpty ? _buildList(contacts, isDark) : _buildList(contacts.where((c) => c.name.toLowerCase().contains(_q.toLowerCase()) || (c.company?.toLowerCase().contains(_q.toLowerCase()) ?? false)).toList(), isDark)),
        // FAB
        Padding(padding: const EdgeInsets.only(bottom: 12), child: FloatingActionButton.extended(onPressed: _add, backgroundColor: Theme.of(context).colorScheme.primary, icon: const Icon(Icons.add, color: Colors.white, size: 20), label: const Text('Add Contact', style: TextStyle(color: Colors.white, fontSize: 13)))),
      ]);
    });
  }

  Widget _statsBar(List<Contact> contacts, bool isDark) {
    final total = contacts.length;
    final thisWeek = contacts.where((c) => c.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
    return Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 4), child: Row(children: [
      _statChip('Total', '$total', isDark),
      const SizedBox(width: 8),
      _statChip('This Week', '$thisWeek', isDark),
      const SizedBox(width: 8),
      _statChip('Active', '$total', isDark),
    ]));
  }

  Widget _statChip(String label, String value, bool isDark) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)), child: Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45))])));

  Widget _buildList(List<Contact> contacts, bool isDark) {
    if (contacts.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.people_outline, size: 48, color: isDark ? Colors.white24 : Colors.grey[400]), const SizedBox(height: 8), Text('No contacts', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]))]));
    return ListView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 8), itemCount: contacts.length, itemBuilder: (_, i) => _contactTile(contacts[i], isDark));
  }

  Widget _contactTile(Contact c, bool isDark) {
    final alias = _parseAliases(c.aliases);
    return Card(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), child: ListTile(
      leading: CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), child: Text(c.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14))),
      title: Text(c.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: c.company != null ? Text(c.company!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[500])) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (alias.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)), child: Text(alias.first, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.primary))), const SizedBox(width: 4), Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white24 : Colors.grey[400])]),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailPage(contactId: c.id))),
    ));
  }

  List<String> _parseAliases(String s) { try { final d = jsonDecode(s); if (d is List) return d.cast<String>(); } catch (_) {} return []; }
}

// ==================== Companies Tab ====================
class _CompaniesTab extends StatefulWidget { const _CompaniesTab(); @override State<_CompaniesTab> createState() => _CompaniesTabState(); }
class _CompaniesTabState extends State<_CompaniesTab> {
  AppDatabase get db => getIt<AppDatabase>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Contact>>(stream: db.watchAllContacts(), builder: (ctx, snap) {
      final contacts = snap.data ?? [];
      // Group by company
      final Map<String, List<Contact>> groups = {};
      for (final c in contacts) {
        final key = c.company ?? 'No Company';
        groups.putIfAbsent(key, () => []).add(c);
      }
      final entries = groups.entries.toList();

      if (entries.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.business_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[400]), const SizedBox(height: 8), Text('No companies', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]))]));

      return ListView.builder(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), itemCount: entries.length, itemBuilder: (_, i) {
        final e = entries[i];
        return Card(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(e.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text('${e.value.length}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)))]),
          const SizedBox(height: 8),
          ...e.value.take(5).map((c) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.person_outline, size: 14, color: isDark ? Colors.white38 : Colors.grey[500]), const SizedBox(width: 6), Text('${c.name}${c.role != null ? '  ${c.role}' : ''}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54))]))),
          if (e.value.length > 5) Padding(padding: const EdgeInsets.only(top: 6), child: Text('+${e.value.length - 5} more...', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[500]))),
        ])));
      });
    });
  }
}

// ==================== Deals Tab (Pipeline Kanban) ====================
class _DealsTab extends StatefulWidget { const _DealsTab(); @override State<_DealsTab> createState() => _DealsTabState(); }
class _DealsTabState extends State<_DealsTab> {
  AppDatabase get db => getIt<AppDatabase>();
  static const stages = ['lead', 'contacted', 'quoting', 'negotiation', 'won', 'lost'];
  static const stageLabels = {'lead': 'Leads', 'contacted': 'Contacted', 'quoting': 'Quoting', 'negotiation': 'Negotiation', 'won': 'Won', 'lost': 'Lost'};
  static const stageColors = {'lead': Colors.grey, 'contacted': Colors.blue, 'quoting': Colors.orange, 'negotiation': Colors.purple, 'won': Colors.green, 'lost': Colors.red};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Deal>>(stream: (db.select(db.deals)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch(), builder: (ctx, snap) {
      final deals = snap.data ?? [];
      return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: stages.map((stage) {
        final stageDeals = deals.where((d) => d.stage == stage).toList();
        final color = stageColors[stage]!;
        return Container(width: 220, margin: const EdgeInsets.only(right: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(stageLabels[stage]!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const Spacer(),
            Text('${stageDeals.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ])),
          const SizedBox(height: 8),
          if (stageDeals.isEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100]!, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('Empty', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey[400])))),
          ...stageDeals.map((d) => FutureBuilder<Contact?>(future: db.getContact(d.contactId), builder: (_, cs) {
            final c = cs.data;
            return Card(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
              if (c != null) ...[const SizedBox(height: 4), Text(c.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[500]))],
              if (d.value != null) ...[const SizedBox(height: 4), Text('\$${d.value!.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary))],
            ])));
          })),
        ]));
      }).toList()));
    });
  }
}

// ==================== Contact Detail Page ====================
class ContactDetailPage extends StatefulWidget {
  final int contactId;
  const ContactDetailPage({super.key, required this.contactId});
  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  AppDatabase get db => getIt<AppDatabase>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return FutureBuilder<Contact?>(future: db.getContact(widget.contactId), builder: (ctx, snap) {
      if (!snap.hasData || snap.data == null) return Scaffold(appBar: AppBar(title: const Text('Contact')), body: const Center(child: Text('Not found')));
      final c = snap.data!;
      final alias = _pa(c.aliases);
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
        appBar: AppBar(title: Text(c.name), backgroundColor: Colors.transparent, scrolledUnderElevation: 0, actions: [IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _edit(c))]),
        body: Column(children: [
          // Info card
          Container(margin: const EdgeInsets.fromLTRB(14, 0, 14, 12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)), child: Column(children: [
            CircleAvatar(radius: 28, backgroundColor: primary.withValues(alpha: 0.12), child: Text(c.name[0].toUpperCase(), style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 22))),
            const SizedBox(height: 10), Text(c.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            if (c.company != null) Text('${c.company}${c.role != null ? '  ${c.role}' : ''}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])),
            if (c.phone != null || c.email != null) Padding(padding: const EdgeInsets.only(top: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (c.phone != null) ...[Icon(Icons.phone_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey[500]), const SizedBox(width: 4), Text(c.phone!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])), const SizedBox(width: 14)],
              if (c.email != null) ...[Icon(Icons.email_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey[500]), const SizedBox(width: 4), Text(c.email!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600]))],
            ])),
            if (alias.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 4, children: alias.map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)), child: Text(a, style: TextStyle(fontSize: 10, color: primary)))).toList())),
          ])),
          // Timeline
          Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 6), child: Row(children: [Icon(Icons.timeline, size: 14, color: isDark ? Colors.white38 : Colors.grey[500]), const SizedBox(width: 5), Text('Activity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 0.5))])),
          Expanded(child: StreamBuilder<List<Activity>>(stream: db.watchActivitiesForContact(widget.contactId), builder: (_, asnap) {
            if (!asnap.hasData) return const Center(child: CircularProgressIndicator());
            final acts = asnap.data!;
            if (acts.isEmpty) return Center(child: Text('No activity yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])));
            return ListView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), itemCount: acts.length, itemBuilder: (_, i) => _timeline(acts[i], isDark));
          })),
        ]),
      );
    });
  }

  Widget _timeline(Activity a, bool isDark) {
    final icons = {'call': Icons.phone_in_talk, 'visit': Icons.meeting_room, 'email': Icons.email, 'quote': Icons.description, 'contract': Icons.article, 'note': Icons.note};
    final colors = {'call': Colors.blue, 'visit': Colors.green, 'email': Colors.orange, 'quote': Colors.purple, 'contract': const Color(0xFFFF6B6B), 'note': Colors.grey};
    final icon = icons[a.type] ?? Icons.circle;
    final color = colors[a.type] ?? Colors.grey;
    final t = '${a.createdAt.month}/${a.createdAt.day} ${a.createdAt.hour.toString().padLeft(2, '0')}:${a.createdAt.minute.toString().padLeft(2, '0')}';
    return Padding(padding: const EdgeInsets.only(bottom: 2), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 28, child: Column(children: [Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, size: 12, color: color))])),
      Expanded(child: Card(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)), child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(a.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)), const Spacer(), Text(t, style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.grey[500]))]),
        const SizedBox(height: 4), Text(a.content, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black87)),
      ])))),
    ])));
  }

  void _edit(Contact c) {
    final n = TextEditingController(text: c.name), co = TextEditingController(text: c.company ?? ''), ph = TextEditingController(text: c.phone ?? ''), em = TextEditingController(text: c.email ?? ''), al = TextEditingController(text: _pa(c.aliases).join(', '));
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Edit'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(n, 'Name'), const SizedBox(height: 8), _field(co, 'Company'), const SizedBox(height: 8), _field(ph, 'Phone'), const SizedBox(height: 8), _field(em, 'Email'), const SizedBox(height: 8), _field(al, 'Aliases (,)'),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async {
      final aliases = al.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await db.updateContact(c.id, ContactsCompanion(name: Value(n.text.trim()), company: Value(co.text.trim().isEmpty ? null : co.text.trim()), phone: Value(ph.text.trim().isEmpty ? null : ph.text.trim()), email: Value(em.text.trim().isEmpty ? null : em.text.trim()), aliases: Value(jsonEncode(aliases))));
      if (ctx.mounted) Navigator.pop(ctx);
    }, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white), child: const Text('Save'))]));
  }

  Widget _field(TextEditingController ctrl, String label) => TextField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true));

  List<String> _pa(String s) { try { final d = jsonDecode(s); if (d is List) return d.cast<String>(); } catch (_) {} return []; }
}

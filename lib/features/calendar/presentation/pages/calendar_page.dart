import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/vault/vault_service.dart';
import '../../../contacts/presentation/widgets/crm_design.dart';
import '../../../../core/sync/sync_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  VaultService get vault => getIt<VaultService>();
  AppDatabase get db => getIt<AppDatabase>();
  DateTime _month = DateTime.now();
  DateTime? _sel;
  Set<String> _dates = {};
  String _daily = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  void _scan() async {
    if (vault.vaultPath == null) return;
    final d = Directory(p.join(vault.vaultPath!, 'daily'));
    if (!await d.exists()) return;
    final y = _month.year,
        m = _month.month.toString().padLeft(2, '0'),
        pre = '$y-$m';
    final set = <String>{};
    await for (final e in d.list()) {
      if (e is File && e.path.endsWith('.md')) {
        final n = p.basenameWithoutExtension(e.path);
        if (n.startsWith(pre)) set.add(n);
      }
    }
    if (mounted) setState(() => _dates = set);
  }

  Future<void> _load(DateTime date) async {
    if (vault.vaultPath == null) return;
    setState(() {
      _sel = date;
      _loading = true;
    });
    final ds =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final fp = p.join(vault.vaultPath!, 'daily', '$ds.md');
    final f = File(fp);
    String c = '';
    if (await f.exists()) {
      final n = await vault.readNote(fp);
      c = n?.body ?? await f.readAsString();
    }
    if (mounted) {
      setState(() {
        _daily = c;
        _loading = false;
      });
    }
  }

  void _prev() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _scan();
        _sel = null;
        _daily = '';
      });
  void _next() => setState(() {
        _month = DateTime(_month.year, _month.month + 1);
        _scan();
        _sel = null;
        _daily = '';
      });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
    final hasV = vault.vaultPath != null;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final today = DateTime.now();

    final fd = DateTime(_month.year, _month.month, 1);
    final ld = DateTime(_month.year, _month.month + 1, 0);
    final so = fd.weekday - 1;
    final total = so + ld.day;
    final cells = <Widget>[];
    for (int i = 0; i < total; i++) {
      if (i < so) {
        cells.add(const SizedBox());
        continue;
      }
      final day = i - so + 1;
      final date = DateTime(_month.year, _month.month, day);
      final ds =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final has = _dates.contains(ds);
      final isT = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isS = _sel != null &&
          _sel!.year == date.year &&
          _sel!.month == date.month &&
          _sel!.day == date.day;
      cells.add(GestureDetector(
          onTap: () => _load(date),
          child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: isS
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: isT
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            shape: BoxShape.circle),
                        child: Center(
                            child: Text('$day',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isT
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isT
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87))))),
                    if (has)
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle)),
                  ]))));
    }

    return ValueListenableBuilder<int>(
      valueListenable: getIt<SyncService>().syncTick,
      builder: (_, tick, __) => Scaffold(
        key: ValueKey('sync_$tick'),
        backgroundColor: bg,
        floatingActionButton: FloatingActionButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (ctx) => _addEventSheet(),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
            child: Column(children: [
          if (!hasV)
            Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('Configure Vault in Settings',
                      style: TextStyle(fontSize: 11, color: Colors.orange))
                ])),
          // Month header
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _prev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
                Expanded(
                    child: Text('${months[_month.month - 1]} ${_month.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _next,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ])),
          // Weekday header
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => Expanded(
                          child: Center(
                              child: Text(d,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey[500])))))
                      .toList())),
          // Calendar grid
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.1,
                  children: cells)),
          // Divider
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
          // Daily note / Upcoming section
          Expanded(
              child: _sel == null
                  ? _upcomingWidget(isDark)
                  : _dailyWidget(isDark)),
        ]))));
  }

  Widget _addEventSheet() {
    return _AddEventSheet(db: db);
  }

  Widget _upcomingWidget(bool isDark) {
    return StreamBuilder<List<Task>>(
        stream: db.watchActiveTasks(),
        builder: (_, snap) {
          final tasks = snap.data ?? [];
          return ListView(padding: const EdgeInsets.all(14), children: [
            Row(children: [
              Icon(Icons.event_note,
                  size: 14, color: isDark ? Colors.white38 : Colors.grey[500]),
              const SizedBox(width: 5),
              Text('Upcoming',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      letterSpacing: 0.5))
            ]),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text('No upcoming tasks',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey[400])))),
            ...tasks.take(10).map((t) => CrmSwipeDismissible(
                  dark: isDark,
                  dismissKey: Key('task_${t.id}'),
                  onDelete: () => db.deleteTask(t.id),
                  child: Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12)),
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.check_circle_outline,
                              size: 16,
                              color:
                                  t.priority > 0 ? Colors.orange : Colors.grey),
                          title: Text(t.title,
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  decoration: t.status == 'done'
                                      ? TextDecoration.lineThrough
                                      : null)),
                          subtitle: t.dueDate != null
                              ? Text('${t.dueDate!.month}/${t.dueDate!.day}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.grey[500]))
                              : null)),
                )),
          ]);
        });
  }

  Widget _dailyWidget(bool isDark) {
    final ds = _sel != null
        ? '${_sel!.year}-${_sel!.month.toString().padLeft(2, '0')}-${_sel!.day.toString().padLeft(2, '0')}'
        : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(children: [
            Text(ds,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() {
                      _sel = null;
                      _daily = '';
                    }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints())
          ])),
      Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _daily.isEmpty
                  ? Center(
                      child: Text('No notes',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white30 : Colors.grey[400])))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: SelectableText(
                          _daily.length > 800
                              ? '${_daily.substring(0, 800)}...'
                              : _daily,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color:
                                  isDark ? Colors.white70 : Colors.black87)))),
    ]);
  }
}

class _AddEventSheet extends StatefulWidget {
  final AppDatabase db;
  const _AddEventSheet({required this.db});
  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await widget.db.addTask(title: title, dueDate: _selectedDate);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

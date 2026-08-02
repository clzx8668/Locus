import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../contacts/presentation/widgets/crm_design.dart';
import '../../../contacts/presentation/widgets/crm_table_schema.dart';
import 'package:locus/features/home/presentation/idea_detail_page.dart';

enum _HomeViewMode { grid, list, table }

class IdeaStreamPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const IdeaStreamPage({super.key, this.onNavigate});

  @override
  State<IdeaStreamPage> createState() => _IdeaStreamPageState();
}

class _IdeaStreamPageState extends State<IdeaStreamPage> {
  AppDatabase get db => getIt<AppDatabase>();
  final GlobalKey<ScaffoldState> _sk = GlobalKey();
  final _search = TextEditingController();
  String _q = '';
  _HomeViewMode _mode = _HomeViewMode.grid;

  final Set<int> _selectedPayloadIds = {};
  bool get _hasPayloadSelection => _selectedPayloadIds.isNotEmpty;

  void _togglePayloadSelect(int id) => setState(() {
        if (_selectedPayloadIds.contains(id)) {
          _selectedPayloadIds.remove(id);
        } else {
          _selectedPayloadIds.add(id);
        }
      });

  void _clearPayloadSelection() => setState(() => _selectedPayloadIds.clear());

  Future<void> _confirmDelete(int id) async {
    final confirmed = await crmDeleteConfirmation(
      context: context,
      title: 'Delete this record?',
      onConfirm: () {},
      dark: crmIsDark(context),
    );
    if (confirmed == true) {
      db.deletePayload(id);
    }
  }

  Future<void> _deleteSelectedPayloads() async {
    final confirmed = await crmDeleteConfirmation(
      context: context,
      title: 'Delete ${_selectedPayloadIds.length} selected record(s)?',
      onConfirm: () {},
      dark: crmIsDark(context),
    );
    if (confirmed == true) {
      for (final id in _selectedPayloadIds.toList()) {
        db.deletePayload(id);
      }
      _clearPayloadSelection();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HubPayload> _filter(List<HubPayload> items) {
    if (_q.isEmpty) return items;
    final lower = _q.toLowerCase();
    return items
        .where((i) =>
            i.rawText.toLowerCase().contains(lower) ||
            i.intentTag.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = crmIsDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    final sw = MediaQuery.of(context).size.width;
    final large = sw >= 960;

    return ValueListenableBuilder<int>(
      valueListenable: getIt<SyncService>().syncTick,
      builder: (_, tick, __) => KeyedSubtree(
        key: ValueKey('sync_$tick'),
        child: Scaffold(
          key: _sk,
        backgroundColor: crmPageBackground(dark),
        drawer: large ? null : _drawer(dark, primary),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickInput(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(dark, large),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Text(
                      _greet(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: crmBodyTextColor(dark),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<HubPayload>>(
                      stream: db.watchAllPayloads(),
                      builder: (_, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        final items = _filter(snap.data!);
                        if (items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 44, color: crmMutedTextColor(dark)),
                                const SizedBox(height: 10),
                                Text('No records',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: crmMutedTextColor(dark))),
                              ],
                            ),
                          );
                        }
                        return _buildView(items, dark, primary, large);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildView(
      List<HubPayload> items, bool dark, Color primary, bool large) {
    switch (_mode) {
      case _HomeViewMode.grid:
        return _gridView(items, dark, primary, large);
      case _HomeViewMode.list:
        return _listView(items, dark, primary, large);
      case _HomeViewMode.table:
        return _tableView(items, dark, primary);
    }
  }

  Widget _gridView(
      List<HubPayload> items, bool dark, Color primary, bool large) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: large ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _gridCard(items[i], dark, primary, large),
      ),
    );
  }

  Widget _listView(
      List<HubPayload> items, bool dark, Color primary, bool large) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _listCard(items[i], dark, primary, large),
          );
        },
      ),
    );
  }

  Widget _tableView(List<HubPayload> items, bool dark, Color primary) {
    const columns = <CrmColumnSchema>[
      CrmColumnSchema(key: 'intent', label: 'Intent', width: 120),
      CrmColumnSchema(key: 'content', label: 'Content'),
      CrmColumnSchema(
          key: 'created',
          label: 'Created',
          width: 130,
          textAlign: TextAlign.right,
          sortable: true),
    ];
    final allSelected = items.isNotEmpty &&
        items.every((i) => _selectedPayloadIds.contains(i.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        children: [
          if (_hasPayloadSelection)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CrmDeleteActionBar(
                selectedCount: _selectedPayloadIds.length,
                onDelete: _deleteSelectedPayloads,
                dark: dark,
                primary: primary,
                onCancel: _clearPayloadSelection,
              ),
            ),
          Expanded(
            child: CrmSurface(
              dark: dark,
              radius: 16,
              child: CrmTableViewport(
                minWidth: 600,
                header: _tableHeader(columns, dark, allSelected, items),
                body: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, thickness: 1, color: crmBorderColor(dark)),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final dateStr = _formatDate(item.createdAt);
                      final selected = _selectedPayloadIds.contains(item.id);
                      return InkWell(
                        hoverColor: crmHoverColor(dark),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => IdeaDetailPage(payload: item))),
                        child: Container(
                          height: crmRowHeight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: crmCellPadding),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Checkbox(
                                  value: selected,
                                  onChanged: (_) =>
                                      _togglePayloadSelect(item.id),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child:
                                      _tagChip(item.intentTag, primary, dark),
                                ),
                              ),
                              Expanded(
                                child: crmBodyText(
                                    item.rawText.isEmpty
                                        ? 'Quick record'
                                        : item.rawText,
                                    dark),
                              ),
                              SizedBox(
                                width: 130,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: crmMutedText(dateStr, dark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<CrmColumnSchema> cols, bool dark, bool allSelected,
      List<HubPayload> items) {
    return Container(
      height: crmHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: crmCellPadding),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: crmBorderColor(dark)))),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) {
                if (allSelected) {
                  _clearPayloadSelection();
                } else {
                  setState(() {
                    _selectedPayloadIds.addAll(items.map((i) => i.id));
                  });
                }
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
          for (final col in cols)
            SizedBox(
              width: col.width,
              child: Align(
                alignment: col.textAlign == TextAlign.right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: crmHeaderText(col.label, dark, sortable: col.sortable),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridCard(HubPayload data, bool dark, Color primary, bool large) {
    final paths = _img(data.mediaPaths);
    final dateStr =
        '${data.createdAt.month}/${data.createdAt.day} ${data.createdAt.hour.toString().padLeft(2, '0')}:${data.createdAt.minute.toString().padLeft(2, '0')}';
    final card = InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => IdeaDetailPage(payload: data))),
      borderRadius: BorderRadius.circular(14),
      child: CrmSurface(
        dark: dark,
        radius: 14,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                crmMutedText(dateStr, dark),
                if (data.intentTag.isNotEmpty && data.intentTag != 'NOTE')
                  _tagChip(data.intentTag, primary, dark),
              ],
            ),
            if (paths.isNotEmpty) const SizedBox(height: 8),
            if (paths.isNotEmpty)
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(paths.first),
                      height: 80, width: double.infinity, fit: BoxFit.cover)),
            if (paths.isNotEmpty) const SizedBox(height: 8),
            const Spacer(),
            Text(
              data.rawText.isEmpty ? 'Quick record' : data.rawText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: crmBodyTextColor(dark)),
            ),
          ],
        ),
      ),
    );

    if (large) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 14, color: crmMutedTextColor(dark)),
              onPressed: () => _confirmDelete(data.id),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      );
    }

    return CrmSwipeDismissible(
      dark: dark,
      onDelete: () => db.deletePayload(data.id),
      child: card,
    );
  }

  Widget _listCard(HubPayload data, bool dark, Color primary, bool large) {
    final paths = _img(data.mediaPaths);
    final dateStr =
        '${data.createdAt.month}/${data.createdAt.day} ${data.createdAt.hour.toString().padLeft(2, '0')}:${data.createdAt.minute.toString().padLeft(2, '0')}';
    final card = InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => IdeaDetailPage(payload: data))),
      borderRadius: BorderRadius.circular(14),
      child: CrmSurface(
        dark: dark,
        radius: 14,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paths.isNotEmpty) ...[
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(paths.first),
                      width: 72, height: 56, fit: BoxFit.cover)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.rawText.isEmpty ? 'Quick record' : data.rawText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: crmBodyTextColor(dark)),
                        ),
                      ),
                      if (data.intentTag.isNotEmpty && data.intentTag != 'NOTE')
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _tagChip(data.intentTag, primary, dark),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  crmMutedText(dateStr, dark),
                ],
              ),
            ),
            if (large) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 14, color: crmMutedTextColor(dark)),
                onPressed: () => _confirmDelete(data.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );

    if (!large) {
      return CrmSwipeDismissible(
        dark: dark,
        onDelete: () => db.deletePayload(data.id),
        child: card,
      );
    }
    return card;
  }

  Widget _tagChip(String tag, Color primary, bool dark) {
    return CrmChip(label: tag, dark: dark, accent: primary);
  }

  Widget _topBar(bool dark, bool large) {
    final sw = MediaQuery.of(context).size.width;
    final small = sw < 600;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: crmElevatedSurfaceColor(dark),
        border: Border(bottom: BorderSide(color: crmBorderColor(dark))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (small) ...[
            IconButton(
                icon: const Icon(Icons.menu_rounded, size: 20),
                onPressed: () => _sk.currentState?.openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: CrmSearchField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              dark: dark,
              hintText: 'Search or ask AI...',
            ),
          ),
          const SizedBox(width: 10),
          _modeToggle(dark),
        ],
      ),
    );
  }

  Widget _modeToggle(bool dark) {
    const modes = [
      (_HomeViewMode.grid, 'Grid', Icons.dashboard_customize_outlined),
      (_HomeViewMode.list, 'List', Icons.view_headline_rounded),
      (_HomeViewMode.table, 'Table', Icons.table_chart_outlined),
    ];
    final current = modes.firstWhere((m) => m.$1 == _mode);
    return PopupMenuButton<_HomeViewMode>(
      offset: const Offset(0, 34),
      color: crmElevatedSurfaceColor(dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: crmBorderColor(dark)),
      ),
      onSelected: (mode) => setState(() => _mode = mode),
      itemBuilder: (_) => [
        for (final (mode, label, icon) in modes)
          PopupMenuItem<_HomeViewMode>(
            value: mode,
            height: 34,
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: _mode == mode
                        ? Theme.of(context).colorScheme.primary
                        : crmMutedTextColor(dark)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        _mode == mode ? FontWeight.w600 : FontWeight.w400,
                    color: _mode == mode
                        ? crmBodyTextColor(dark)
                        : crmMutedTextColor(dark),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF171717) : const Color(0xFFF6F6F4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: crmBorderColor(dark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.$3,
                size: 15, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(current.$2,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: crmBodyTextColor(dark))),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 14, color: crmMutedTextColor(dark)),
          ],
        ),
      ),
    );
  }

  List<String> _img(String j) {
    try {
      final d = jsonDecode(j);
      if (d is List) return d.cast<String>();
    } catch (_) {}
    return [];
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  Widget _drawer(bool dark, Color primary) {
    final items = [
      {'label': 'Home', 'icon': Icons.flash_on},
      {'label': 'CRM', 'icon': Icons.people},
      {'label': 'Calendar', 'icon': Icons.calendar_month},
      {'label': 'AI Hub', 'icon': Icons.hub},
      {'label': 'Settings', 'icon': Icons.settings},
    ];
    return Drawer(
      backgroundColor: dark ? const Color(0xFF1A1A1A) : const Color(0xFF212121),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 24, bottom: 32),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: primary, borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('L',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900))),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    leading: Icon(item['icon'] as IconData,
                        color: Colors.grey[400], size: 22),
                    title: Text(item['label'] as String,
                        style:
                            TextStyle(color: Colors.grey[300], fontSize: 15)),
                    onTap: () {
                      widget.onNavigate?.call(i);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickInput(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Quick note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      db.insertPayload(
                        HubPayloadsCompanion.insert(rawText: text),
                      );
                    }
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

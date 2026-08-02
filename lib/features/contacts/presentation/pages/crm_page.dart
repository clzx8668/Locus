import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../widgets/crm_design.dart';
import '../widgets/crm_table_schema.dart';
import '../../../../core/sync/sync_service.dart';
import 'company_detail_page.dart';
import 'contact_detail_page.dart';
import 'deal_detail_page.dart';

class CrmPage extends StatefulWidget {
  const CrmPage({super.key});

  @override
  State<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends State<CrmPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = crmIsDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<int>(
      valueListenable: getIt<SyncService>().syncTick,
      builder: (_, tick, __) => Scaffold(
      key: ValueKey('sync_$tick'),
      backgroundColor: crmPageBackground(dark),
      appBar: AppBar(
        title: const Text('CRM'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF171717) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: crmBorderColor(dark)),
              ),
              child: TabBar(
                controller: _tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: primary.withValues(alpha: dark ? 0.24 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorPadding: const EdgeInsets.all(3),
                labelColor: primary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelColor: crmMutedTextColor(dark),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(text: 'Contacts'),
                  Tab(text: 'Companies'),
                  Tab(text: 'Pipeline'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ContactsView(),
          _CompaniesView(),
          _PipelineView(),
        ],
      ),
      ),
    );
  }
}

bool _isNarrow(BuildContext context) => MediaQuery.of(context).size.width < 760;

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171717) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: crmBorderColor(dark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: crmBodyTextColor(dark),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: crmMutedTextColor(dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool dark;

  const _PanelEmptyState({
    required this.title,
    required this.icon,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: crmMutedTextColor(dark)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
          ),
        ],
      ),
    );
  }
}

class _ContactsView extends StatefulWidget {
  const _ContactsView();

  @override
  State<_ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<_ContactsView> {
  AppDatabase get db => getIt<AppDatabase>();

  final _search = TextEditingController();
  String _query = '';
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasSelection => _selectedIds.isNotEmpty;

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Contact> contacts) {
    setState(() {
      if (_selectedIds.length == contacts.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(contacts.map((c) => c.id));
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _add() {
    final name = TextEditingController();
    final company = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Contact',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: company,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) return;
                      await db.addContact(
                        name: name.text.trim(),
                        company: company.text.trim().isEmpty
                            ? null
                            : company.text.trim(),
                        phone: phone.text.trim().isEmpty
                            ? null
                            : phone.text.trim(),
                        email: email.text.trim().isEmpty
                            ? null
                            : email.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Contact'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = crmIsDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    final narrow = _isNarrow(context);
    return StreamBuilder<List<Contact>>(
      stream: db.watchAllContacts(),
      builder: (_, snapshot) {
        final all = snapshot.data ?? const <Contact>[];
        final filtered = _query.isEmpty
            ? all
            : all.where((contact) {
                final q = _query.toLowerCase();
                return contact.name.toLowerCase().contains(q) ||
                    (contact.company?.toLowerCase().contains(q) ?? false) ||
                    (contact.email?.toLowerCase().contains(q) ?? false);
              }).toList();
        final weekly = all
            .where(
              (c) => c.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
            .length;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _hasSelection
              ? null
              : FloatingActionButton(
                  onPressed: _add,
                  backgroundColor: primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                if (_hasSelection)
                  CrmDeleteActionBar(
                    selectedCount: _selectedIds.length,
                    dark: dark,
                    primary: primary,
                    onCancel: _clearSelection,
                    onDelete: () async {
                      for (final id in _selectedIds) {
                        await db.deleteContact(id);
                      }
                      _clearSelection();
                    },
                  ),
                _toolbar(
                  dark: dark,
                  narrow: narrow,
                  metrics: [
                    _MetricChip(
                      label: 'Contacts',
                      value: all.length.toString(),
                      dark: dark,
                    ),
                    _MetricChip(
                      label: 'Added 7d',
                      value: weekly.toString(),
                      dark: dark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? _PanelEmptyState(
                          title: all.isEmpty ? 'No contacts yet' : 'No matches',
                          icon: Icons.people_outline,
                          dark: dark,
                        )
                      : narrow
                          ? _contactsMobile(filtered, dark, primary)
                          : _contactsTable(filtered, dark, primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolbar({
    required bool dark,
    required bool narrow,
    required List<Widget> metrics,
  }) {
    final search = Expanded(
      child: CrmSearchField(
        controller: _search,
        onChanged: (value) => setState(() => _query = value.trim()),
        dark: dark,
        hintText: 'Search contacts...',
      ),
    );
    final statWrap = Wrap(spacing: 8, runSpacing: 8, children: metrics);
    if (narrow) {
      return Column(
        children: [
          Row(children: [search]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: statWrap),
        ],
      );
    }
    return Row(
      children: [
        search,
        const SizedBox(width: 12),
        statWrap,
      ],
    );
  }

  Widget _contactsTable(List<Contact> list, bool dark, Color primary) {
    final allSelected = _selectedIds.length == list.length;
    final columns = crmContactColumns;
    return CrmSurface(
      dark: dark,
      radius: 16,
      child: CrmTableViewport(
        minWidth: 860,
        header: Container(
          height: crmHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: crmCellPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: crmBorderColor(dark)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: GestureDetector(
                  onTap: () => _selectAll(list),
                  child: Icon(
                    allSelected
                        ? Icons.check_box_rounded
                        : _selectedIds.isNotEmpty
                            ? Icons.indeterminate_check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: _selectedIds.isNotEmpty
                        ? primary
                        : crmBorderColor(dark),
                  ),
                ),
              ),
              for (final col in columns.skip(1))
                SizedBox(
                  width: col.width,
                  child: Align(
                    alignment: col.textAlign == TextAlign.right
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child:
                        crmHeaderText(col.label, dark, sortable: col.sortable),
                  ),
                ),
            ],
          ),
        ),
        body: Scrollbar(
          thumbVisibility: true,
          interactive: true,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: crmBorderColor(dark),
            ),
            itemBuilder: (_, index) {
              final contact = list[index];
              final selected = _selectedIds.contains(contact.id);
              return InkWell(
                hoverColor: crmHoverColor(dark),
                onTap: () {
                  if (_hasSelection) {
                    _toggleSelect(contact.id);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ContactDetailPage(contactId: contact.id),
                      ),
                    );
                  }
                },
                child: Container(
                  height: crmRowHeight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: crmCellPadding),
                  color: selected
                      ? primary.withValues(alpha: dark ? 0.12 : 0.06)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: GestureDetector(
                          onTap: () => _toggleSelect(contact.id),
                          child: Icon(
                            selected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: selected ? primary : crmBorderColor(dark),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: Row(
                          children: [
                            CrmAvatarBadge(seed: contact.name, accent: primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: crmBodyText(
                                contact.name,
                                dark,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: contact.company == null ||
                                contact.company!.trim().isEmpty
                            ? crmMutedText('-', dark)
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: CrmChip(
                                  label: contact.company!,
                                  dark: dark,
                                ),
                              ),
                      ),
                      SizedBox(
                        width: 140,
                        child: crmMutedText(contact.phone ?? '-', dark),
                      ),
                      Expanded(
                        child: crmMutedText(contact.email ?? '-', dark),
                      ),
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: crmMutedText(
                            _formatShortDate(contact.updatedAt),
                            dark,
                          ),
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
    );
  }

  Widget _contactsMobile(List<Contact> list, bool dark, Color primary) {
    return Column(
      children: [
        if (_hasSelection)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CrmDeleteActionBar(
              selectedCount: _selectedIds.length,
              dark: dark,
              primary: primary,
              onCancel: _clearSelection,
              onDelete: () async {
                for (final id in _selectedIds) {
                  await db.deleteContact(id);
                }
                _clearSelection();
              },
            ),
          ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            interactive: true,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 84),
              itemCount: list.length,
              itemBuilder: (_, index) {
                final contact = list[index];
                final selected = _selectedIds.contains(contact.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CrmSwipeDismissible(
                    dark: dark,
                    onDelete: () async {
                      await db.deleteContact(contact.id);
                    },
                    child: CrmSurface(
                      dark: dark,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        leading: CrmAvatarBadge(
                            seed: contact.name, accent: primary, size: 36),
                        title: crmBodyText(contact.name, dark,
                            weight: FontWeight.w600),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if ((contact.company ?? '').isNotEmpty)
                                CrmChip(label: contact.company!, dark: dark),
                              if ((contact.email ?? '').isNotEmpty)
                                CrmChip(label: contact.email!, dark: dark),
                            ],
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: primary,
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: crmMutedTextColor(dark),
                              ),
                        onTap: () {
                          if (_hasSelection) {
                            _toggleSelect(contact.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ContactDetailPage(contactId: contact.id),
                              ),
                            );
                          }
                        },
                        onLongPress: () => _toggleSelect(contact.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanySummary {
  final String name;
  final List<Contact> contacts;

  const _CompanySummary({required this.name, required this.contacts});

  DateTime get latestUpdated =>
      contacts.map((contact) => contact.updatedAt).fold<DateTime>(
            contacts.first.updatedAt,
            (latest, date) => date.isAfter(latest) ? date : latest,
          );
}

class _CompaniesView extends StatefulWidget {
  const _CompaniesView();

  @override
  State<_CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<_CompaniesView> {
  AppDatabase get db => getIt<AppDatabase>();

  final _search = TextEditingController();
  String _query = '';

  final Set<String> _selectedCompanyNames = {};

  bool get _hasCompanySelection => _selectedCompanyNames.isNotEmpty;

  void _toggleCompanySelect(String name) {
    setState(() {
      if (_selectedCompanyNames.contains(name)) {
        _selectedCompanyNames.remove(name);
      } else {
        _selectedCompanyNames.add(name);
      }
    });
  }

  void _clearCompanySelection() =>
      setState(() => _selectedCompanyNames.clear());

  void _addCompany() {
    final name = TextEditingController();
    final contactName = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Company',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactName,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) return;
                      await db.addContact(
                        name: contactName.text.trim().isEmpty
                            ? name.text.trim()
                            : contactName.text.trim(),
                        company: name.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Company'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = crmIsDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    final narrow = _isNarrow(context);
    return StreamBuilder<List<Contact>>(
      stream: db.watchAllContacts(),
      builder: (_, snapshot) {
        final contacts = snapshot.data ?? const <Contact>[];
        final grouped = <String, List<Contact>>{};
        for (final contact in contacts) {
          final companyName = (contact.company ?? 'No Company').trim();
          grouped.putIfAbsent(
              companyName.isEmpty ? 'No Company' : companyName, () => []);
          grouped[companyName.isEmpty ? 'No Company' : companyName]!
              .add(contact);
        }
        var companies = grouped.entries
            .map((entry) =>
                _CompanySummary(name: entry.key, contacts: entry.value))
            .toList();
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          companies = companies
              .where((company) => company.name.toLowerCase().contains(q))
              .toList();
        }
        companies
            .sort((a, b) => b.contacts.length.compareTo(a.contacts.length));
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _hasCompanySelection
              ? null
              : FloatingActionButton(
                  onPressed: _addCompany,
                  backgroundColor: primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                if (_hasCompanySelection)
                  CrmDeleteActionBar(
                    selectedCount: _selectedCompanyNames.length,
                    onDelete: () async {
                      for (final name in _selectedCompanyNames) {
                        await db.deleteCompany(name);
                      }
                      _clearCompanySelection();
                    },
                    dark: dark,
                    primary: primary,
                    onCancel: _clearCompanySelection,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: CrmSearchField(
                          controller: _search,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          dark: dark,
                          hintText: 'Search companies...',
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MetricChip(
                        label: 'Companies',
                        value: companies.length.toString(),
                        dark: dark,
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: companies.isEmpty
                      ? _PanelEmptyState(
                          title: 'No companies',
                          icon: Icons.business_outlined,
                          dark: dark,
                        )
                      : narrow
                          ? _companiesMobile(companies, dark, primary)
                          : _companiesTable(companies, dark, primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _companiesTable(
    List<_CompanySummary> companies,
    bool dark,
    Color primary,
  ) {
    return CrmSurface(
      dark: dark,
      radius: 16,
      child: CrmTableViewport(
        minWidth: 760,
        header: Container(
          height: crmHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: crmCellPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: crmBorderColor(dark)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedCompanyNames.length == companies.length) {
                        _selectedCompanyNames.clear();
                      } else {
                        _selectedCompanyNames
                            .addAll(companies.map((c) => c.name));
                      }
                    });
                  },
                  child: Icon(
                    _selectedCompanyNames.length == companies.length
                        ? Icons.check_box_rounded
                        : _selectedCompanyNames.isNotEmpty
                            ? Icons.indeterminate_check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: _selectedCompanyNames.isNotEmpty
                        ? primary
                        : crmBorderColor(dark),
                  ),
                ),
              ),
              for (final col in crmCompanyColumns)
                SizedBox(
                  width: col.width,
                  child: Align(
                    alignment: col.textAlign == TextAlign.right
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child:
                        crmHeaderText(col.label, dark, sortable: col.sortable),
                  ),
                ),
              const SizedBox(width: 28),
            ],
          ),
        ),
        body: Scrollbar(
          thumbVisibility: true,
          interactive: true,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: companies.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: crmBorderColor(dark),
            ),
            itemBuilder: (_, index) {
              final company = companies[index];
              final people = company.contacts.take(3).toList();
              final extraCount = company.contacts.length - people.length;
              final selected = _selectedCompanyNames.contains(company.name);
              return InkWell(
                hoverColor: crmHoverColor(dark),
                onTap: () {
                  if (_hasCompanySelection) {
                    _toggleCompanySelect(company.name);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompanyDetailPage(companyName: company.name),
                      ),
                    );
                  }
                },
                child: Container(
                  height: crmRowHeight + 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: crmCellPadding),
                  color: selected
                      ? primary.withValues(alpha: dark ? 0.12 : 0.06)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: GestureDetector(
                          onTap: () => _toggleCompanySelect(company.name),
                          child: Icon(
                            selected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: selected ? primary : crmBorderColor(dark),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Row(
                          children: [
                            CrmAvatarBadge(seed: company.name, accent: primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: crmBodyText(
                                company.name,
                                dark,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: crmMutedText(
                          company.contacts.length.toString(),
                          dark,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            for (final person in people)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CrmAvatarBadge(
                                    seed: person.name,
                                    accent: primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  crmMutedText(person.name, dark),
                                ],
                              ),
                            if (extraCount > 0)
                              CrmChip(
                                label: '+$extraCount more',
                                dark: dark,
                                accent: primary,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: crmMutedText(
                            _formatShortDate(company.latestUpdated),
                            dark,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: GestureDetector(
                          onTap: () {
                            crmDeleteConfirmation(
                              context: context,
                              title: 'Delete ${company.name}?',
                              onConfirm: () async =>
                                  await db.deleteCompany(company.name),
                              dark: dark,
                            );
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: crmMutedTextColor(dark),
                          ),
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
    );
  }

  Widget _companiesMobile(
    List<_CompanySummary> companies,
    bool dark,
    Color primary,
  ) {
    return Scrollbar(
      thumbVisibility: true,
      interactive: true,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemCount: companies.length,
        itemBuilder: (_, index) {
          final company = companies[index];
          final selected = _selectedCompanyNames.contains(company.name);
          return CrmSwipeDismissible(
            dark: dark,
            onDelete: () async => await db.deleteCompany(company.name),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onLongPress: () => _toggleCompanySelect(company.name),
              onTap: () {
                if (_hasCompanySelection) {
                  _toggleCompanySelect(company.name);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CompanyDetailPage(companyName: company.name),
                    ),
                  );
                }
              },
              child: Container(
                decoration: selected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary, width: 2),
                      )
                    : null,
                child: CrmSurface(
                  dark: dark,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CrmAvatarBadge(
                            seed: company.name, accent: primary, size: 40),
                        const Spacer(),
                        Text(
                          company.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: crmBodyTextColor(dark),
                          ),
                        ),
                        const SizedBox(height: 6),
                        crmMutedText(
                            '${company.contacts.length} contacts', dark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PipelineView extends StatefulWidget {
  const _PipelineView();

  @override
  State<_PipelineView> createState() => _PipelineViewState();
}

class _PipelineViewState extends State<_PipelineView> {
  AppDatabase get db => getIt<AppDatabase>();

  static const stages = [
    'lead',
    'contacted',
    'quoting',
    'negotiation',
    'won',
    'lost',
  ];

  static const labels = {
    'lead': 'Leads',
    'contacted': 'Contacted',
    'quoting': 'Quoting',
    'negotiation': 'Negotiation',
    'won': 'Won',
    'lost': 'Lost',
  };

  static const colors = {
    'lead': Color(0xFF9E9E9E),
    'contacted': Color(0xFF42A5F5),
    'quoting': Color(0xFFFFA726),
    'negotiation': Color(0xFFAB47BC),
    'won': Color(0xFF66BB6A),
    'lost': Color(0xFFEF5350),
  };

  void _addDeal() {
    final title = TextEditingController();
    String stage = 'lead';
    int? selectedContactId;
    final valueCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<Contact>>(
          future: db.watchAllContacts().first,
          builder: (_, contactSnapshot) {
            final contacts = contactSnapshot.data ?? const <Contact>[];
            return StatefulBuilder(
              builder: (_, setSheetState) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Deal',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (contacts.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: selectedContactId,
                          items: contacts
                              .map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) =>
                              setSheetState(() => selectedContactId = v),
                          decoration: const InputDecoration(
                            labelText: 'Contact',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text('No contacts available',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 12)),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: stage,
                        items: stages
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setSheetState(() => stage = v ?? stage),
                        decoration: const InputDecoration(
                          labelText: 'Stage',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (title.text.trim().isEmpty) return;
                            final cid = selectedContactId ??
                                (contacts.isNotEmpty
                                    ? contacts.first.id
                                    : null);
                            if (cid == null) return;
                            await db.addDeal(
                              contactId: cid,
                              title: title.text.trim(),
                              stage: stage,
                              value: valueCtrl.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(valueCtrl.text.trim()),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Create Deal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = crmIsDark(context);
    final primary = Theme.of(context).colorScheme.primary;
    return StreamBuilder<List<Deal>>(
      stream: (db.select(db.deals)
            ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
          .watch(),
      builder: (_, snapshot) {
        final all = snapshot.data ?? const <Deal>[];
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: _addDeal,
            backgroundColor: primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Scrollbar(
            thumbVisibility: true,
            interactive: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final stage in stages)
                  _stageColumn(
                    stage: stage,
                    deals: all.where((deal) => deal.stage == stage).toList(),
                    dark: dark,
                    primary: primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stageColumn({
    required String stage,
    required List<Deal> deals,
    required bool dark,
    required Color primary,
  }) {
    final stageColor = colors[stage] ?? primary;
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrmSurface(
            dark: dark,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stageColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  labels[stage] ?? stage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: crmBodyTextColor(dark),
                  ),
                ),
                const Spacer(),
                crmMutedText(deals.length.toString(), dark),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: deals.isEmpty
                ? _PanelEmptyState(
                    title: 'No deals',
                    icon: Icons.inbox_outlined,
                    dark: dark,
                  )
                : ListView.builder(
                    itemCount: deals.length,
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DealCard(
                          deal: deals[index],
                          dark: dark,
                          primary: primary,
                          stageColor: stageColor,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DealDeleteButton extends StatefulWidget {
  final bool dark;
  final VoidCallback onTap;

  const _DealDeleteButton({required this.dark, required this.onTap});

  @override
  State<_DealDeleteButton> createState() => _DealDeleteButtonState();
}

class _DealDeleteButtonState extends State<_DealDeleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: _hovered
                ? const Color(0xFFFF6B6B)
                : crmMutedTextColor(widget.dark),
          ),
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final bool dark;
  final Color primary;
  final Color stageColor;

  const _DealCard({
    required this.deal,
    required this.dark,
    required this.primary,
    required this.stageColor,
  });

  @override
  Widget build(BuildContext context) {
    final db = getIt<AppDatabase>();
    final narrow = _isNarrow(context);
    return FutureBuilder<Contact?>(
      future: db.getContact(deal.contactId),
      builder: (_, snapshot) {
        final contact = snapshot.data;

        Widget card = InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DealDetailPage(dealId: deal.id),
            ),
          ),
          child: Stack(
            children: [
              CrmSurface(
                dark: dark,
                radius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: crmBodyTextColor(dark),
                      ),
                    ),
                    if (contact != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CrmAvatarBadge(seed: contact.name, accent: primary),
                          const SizedBox(width: 8),
                          Expanded(child: crmMutedText(contact.name, dark)),
                        ],
                      ),
                    ],
                    if (deal.value != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '\$${deal.value!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                    if (deal.probability != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: deal.probability! / 100,
                                minHeight: 6,
                                backgroundColor: crmBorderColor(dark),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(stageColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          crmMutedText('${deal.probability}%', dark),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!narrow)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _DealDeleteButton(
                    dark: dark,
                    onTap: () {
                      crmDeleteConfirmation(
                        context: context,
                        title: 'Delete this deal?',
                        onConfirm: () async {
                          await db.deleteDeal(deal.id);
                        },
                        dark: dark,
                      );
                    },
                  ),
                ),
            ],
          ),
        );

        if (narrow) {
          card = CrmSwipeDismissible(
            dismissKey: ValueKey(deal.id),
            onDelete: () async {
              await db.deleteDeal(deal.id);
            },
            dark: dark,
            child: card,
          );
        }

        return card;
      },
    );
  }
}

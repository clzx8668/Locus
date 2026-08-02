import 'package:flutter/material.dart';

import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';
import '../widgets/crm_design.dart';
import '../widgets/crm_table_schema.dart';
import 'contact_detail_page.dart';
import 'deal_detail_page.dart';

class CompanyDetailPage extends StatefulWidget {
  final String companyName;

  const CompanyDetailPage({super.key, required this.companyName});

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage>
    with SingleTickerProviderStateMixin {
  AppDatabase get db => getIt<AppDatabase>();
  late final TabController _tab;
  late String _companyName;

  @override
  void initState() {
    super.initState();
    _companyName = widget.companyName;
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
      builder: (_, tick, __) => StreamBuilder<List<Contact>>(
        key: ValueKey('sync_$tick'),
        stream: db.watchContactsForCompany(_companyName),
        builder: (_, snapshot) {
        final contacts = snapshot.data ?? const <Contact>[];
        final contactIds = contacts.map((contact) => contact.id).toList();
        return Scaffold(
          backgroundColor: crmPageBackground(dark),
          appBar: AppBar(
            title: Text(_companyName),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
                color: crmElevatedSurfaceColor(dark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: crmBorderColor(dark)),
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEdit();
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: crmElevatedSurfaceColor(dark),
                        title: Text('Delete $_companyName?',
                            style: TextStyle(color: crmBodyTextColor(dark))),
                        content: Text('This action cannot be undone.',
                            style: TextStyle(color: crmMutedTextColor(dark))),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Color(0xFFEF5350))),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await db.deleteCompany(_companyName);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: Color(0xFFEF5350))),
                  ),
                ],
              ),
            ],
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
                      Tab(text: 'Overview'),
                      Tab(text: 'Contacts'),
                      Tab(text: 'Deals'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _overviewTab(contacts, contactIds, dark, primary),
              _contactsTab(contacts, dark, primary),
              _dealsTab(contacts, contactIds, dark, primary),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _overviewTab(
    List<Contact> contacts,
    List<int> contactIds,
    bool dark,
    Color primary,
  ) {
    if (contacts.isEmpty) {
      return _emptyState('No contacts linked to this company', dark);
    }
    final firstSeen = contacts
        .map((contact) => contact.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final lastUpdated = contacts
        .map((contact) => contact.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return StreamBuilder<List<Deal>>(
      stream: db.watchDealsForContacts(contactIds),
      builder: (_, dealSnapshot) {
        final deals = dealSnapshot.data ?? const <Deal>[];
        return StreamBuilder<List<Activity>>(
          stream: db.watchActivitiesForContacts(contactIds),
          builder: (_, activitySnapshot) {
            final activities = activitySnapshot.data ?? const <Activity>[];
            Widget buildPanel(bool compact) => CrmFieldPanel(
                  dark: dark,
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
                        child: Column(
                          children: [
                            CrmAvatarBadge(
                              seed: _companyName,
                              accent: primary,
                              size: 56,
                            ),
                            const SizedBox(height: 14),
                            CrmInlineTitle(
                              value: _companyName,
                              dark: dark,
                              placeholder: 'Company name',
                              onSave: (value) async {
                                final oldName = _companyName;
                                await db.renameCompany(oldName, value);
                                if (!mounted) return;
                                setState(() => _companyName = value);
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${contacts.length} contacts',
                              style: TextStyle(
                                fontSize: 12,
                                color: crmMutedTextColor(dark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                          height: 1, thickness: 1, color: crmBorderColor(dark)),
                      _panelSectionHeader('Overview', dark),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          children: [
                            _readonlyField(
                              icon: Icons.calendar_today_outlined,
                              label: 'First Seen',
                              value: _formatDateTime(firstSeen),
                              dark: dark,
                            ),
                            _readonlyField(
                              icon: Icons.update_outlined,
                              label: 'Updated',
                              value: _formatDateTime(lastUpdated),
                              dark: dark,
                            ),
                            _readonlyField(
                              icon: Icons.people_outline_rounded,
                              label: 'Contacts',
                              value: contacts.length.toString(),
                              dark: dark,
                            ),
                            _readonlyField(
                              icon: Icons.handshake_outlined,
                              label: 'Deals',
                              value: deals.length.toString(),
                              dark: dark,
                            ),
                            _readonlyField(
                              icon: Icons.history_rounded,
                              label: 'Activity',
                              value: activities.length.toString(),
                              dark: dark,
                            ),
                          ],
                        ),
                      ),
                      _panelSectionHeader('People', dark),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final contact in contacts.take(6))
                                CrmChip(
                                  label: contact.name,
                                  dark: dark,
                                  accent: primary,
                                ),
                              if (contacts.length > 6)
                                CrmChip(
                                  label: '+${contacts.length - 6} more',
                                  dark: dark,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );

            final sideCards = Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        title: 'Contacts',
                        dark: dark,
                        child: _metricValue(
                          contacts.length.toString(),
                          'active people',
                          dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoCard(
                        title: 'Deals',
                        dark: dark,
                        child: _metricValue(
                          deals.length.toString(),
                          'open items',
                          dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoCard(
                        title: 'Activity',
                        dark: dark,
                        child: _metricValue(
                          activities.length.toString(),
                          'logged events',
                          dark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoCard(
                  title: 'People',
                  dark: dark,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final contact in contacts)
                        CrmChip(
                            label: contact.name, dark: dark, accent: primary),
                    ],
                  ),
                ),
              ],
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildPanel(false),
                              const SizedBox(width: 16),
                              Expanded(child: sideCards),
                            ],
                          )
                        : Column(
                            children: [
                              buildPanel(true),
                              const SizedBox(height: 16),
                              sideCards,
                            ],
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _contactsTab(List<Contact> contacts, bool dark, Color primary) {
    if (contacts.isEmpty) return _emptyState('No contacts yet', dark);
    final columns = crmContactColumns
        .where((column) => column.key != 'select' && column.key != 'company')
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        if (narrow) {
          return Scrollbar(
            thumbVisibility: true,
            interactive: true,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (_, index) {
                final contact = contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CrmSurface(
                    dark: dark,
                    child: ListTile(
                      leading: CrmAvatarBadge(
                        seed: contact.name,
                        accent: primary,
                        size: 36,
                      ),
                      title: crmBodyText(
                        contact.name,
                        dark,
                        weight: FontWeight.w600,
                      ),
                      subtitle: Text(
                        [contact.role, contact.email]
                            .whereType<String>()
                            .join('  '),
                        style: TextStyle(
                          fontSize: 12,
                          color: crmMutedTextColor(dark),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: crmMutedTextColor(dark),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ContactDetailPage(contactId: contact.id),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: CrmSurface(
            dark: dark,
            radius: 16,
            child: CrmTableViewport(
              minWidth: 760,
              header: _tableHeader(columns, dark),
              body: Scrollbar(
                thumbVisibility: true,
                interactive: true,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: crmBorderColor(dark),
                  ),
                  itemBuilder: (_, index) {
                    final contact = contacts[index];
                    return InkWell(
                      hoverColor: crmHoverColor(dark),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ContactDetailPage(contactId: contact.id),
                        ),
                      ),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(
                            horizontal: crmCellPadding),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 240,
                              child: Row(
                                children: [
                                  CrmAvatarBadge(
                                      seed: contact.name, accent: primary),
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
                                  _formatDate(contact.updatedAt),
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
          ),
        );
      },
    );
  }

  Widget _dealsTab(
    List<Contact> contacts,
    List<int> contactIds,
    bool dark,
    Color primary,
  ) {
    return StreamBuilder<List<Deal>>(
      stream: db.watchDealsForContacts(contactIds),
      builder: (_, snapshot) {
        final deals = snapshot.data ?? const <Deal>[];
        if (deals.isEmpty) return _emptyState('No deals linked yet', dark);
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;
            if (narrow) {
              return Scrollbar(
                thumbVisibility: true,
                interactive: true,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deals.length,
                  itemBuilder: (_, index) {
                    final deal = deals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CrmSurface(
                        dark: dark,
                        child: ListTile(
                          title: crmBodyText(deal.title, dark,
                              weight: FontWeight.w600),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                CrmChip(
                                  label: _stageLabel(deal.stage),
                                  dark: dark,
                                  accent: _stageColor(deal.stage),
                                ),
                                if (deal.value != null)
                                  CrmChip(
                                    label:
                                        '\$${deal.value!.toStringAsFixed(0)}',
                                    dark: dark,
                                    accent: primary,
                                  ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: crmMutedTextColor(dark),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealDetailPage(dealId: deal.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: CrmSurface(
                dark: dark,
                radius: 16,
                child: CrmTableViewport(
                  minWidth: 980,
                  header: _tableHeader(crmDealColumns, dark),
                  body: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: deals.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: crmBorderColor(dark),
                      ),
                      itemBuilder: (_, index) {
                        final deal = deals[index];
                        Contact? linkedContact;
                        for (final contact in contacts) {
                          if (contact.id == deal.contactId) {
                            linkedContact = contact;
                            break;
                          }
                        }
                        return InkWell(
                          hoverColor: crmHoverColor(dark),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealDetailPage(dealId: deal.id),
                            ),
                          ),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                                horizontal: crmCellPadding),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 220,
                                  child: crmBodyText(
                                    deal.title,
                                    dark,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CrmChip(
                                        label: _companyName, dark: dark),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: crmMutedText(
                                      linkedContact?.name ?? '-', dark),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CrmChip(
                                      label: _stageLabel(deal.stage),
                                      dark: dark,
                                      accent: _stageColor(deal.stage),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: crmMutedText(
                                      deal.value == null
                                          ? '-'
                                          : '\$${deal.value!.toStringAsFixed(0)}',
                                      dark,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: crmMutedText(
                                      deal.probability == null
                                          ? '-'
                                          : '${deal.probability}%',
                                      dark,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: crmMutedText(
                                      deal.expectedCloseDate == null
                                          ? '-'
                                          : _formatDate(
                                              deal.expectedCloseDate!),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _readonlyField({
    required IconData icon,
    required String label,
    required String value,
    required bool dark,
  }) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 15, color: crmMutedTextColor(dark)),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: crmBodyText(value, dark, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required bool dark,
    required Widget child,
  }) {
    return CrmSectionBlock(
      title: title,
      dark: dark,
      child: child,
    );
  }

  Widget _panelSectionHeader(String title, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: crmMutedTextColor(dark),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _metricValue(String value, String label, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: crmBodyTextColor(dark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: crmMutedTextColor(dark)),
        ),
      ],
    );
  }

  Widget _emptyState(String title, bool dark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined,
              size: 44, color: crmMutedTextColor(dark)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEdit() async {
    final dark = crmIsDark(context);
    final controller = TextEditingController(text: _companyName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmElevatedSurfaceColor(dark),
        title: Text('Edit Company',
            style: TextStyle(color: crmBodyTextColor(dark))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: crmBodyTextColor(dark)),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: crmMutedTextColor(dark)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: crmBorderColor(dark)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty && result != _companyName) {
      final oldName = _companyName;
      await db.renameCompany(oldName, result.trim());
      if (mounted) setState(() => _companyName = result.trim());
    }
    controller.dispose();
  }
}

Widget _tableHeader(List<CrmColumnSchema> columns, bool dark) {
  return Container(
    height: crmHeaderHeight,
    padding: const EdgeInsets.symmetric(horizontal: crmCellPadding),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: crmBorderColor(dark))),
    ),
    child: Row(
      children: [
        for (final column in columns)
          SizedBox(
            width: column.width,
            child: Align(
              alignment: column.textAlign == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child:
                  crmHeaderText(column.label, dark, sortable: column.sortable),
            ),
          ),
      ],
    ),
  );
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

Color _stageColor(String stage) {
  return {
        'lead': const Color(0xFF9E9E9E),
        'contacted': const Color(0xFF42A5F5),
        'quoting': const Color(0xFFFFA726),
        'negotiation': const Color(0xFFAB47BC),
        'won': const Color(0xFF66BB6A),
        'lost': const Color(0xFFEF5350),
      }[stage] ??
      const Color(0xFF9E9E9E);
}

String _stageLabel(String stage) {
  return {
        'lead': 'Lead',
        'contacted': 'Contacted',
        'quoting': 'Quoting',
        'negotiation': 'Negotiation',
        'won': 'Won',
        'lost': 'Lost',
      }[stage] ??
      stage;
}

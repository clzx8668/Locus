import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';
import '../widgets/crm_design.dart';

class DealDetailPage extends StatefulWidget {
  final int dealId;

  const DealDetailPage({super.key, required this.dealId});

  @override
  State<DealDetailPage> createState() => _DealDetailPageState();
}

class _DealDetailPageState extends State<DealDetailPage>
    with SingleTickerProviderStateMixin {
  AppDatabase get db => getIt<AppDatabase>();
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      builder: (_, tick, __) => StreamBuilder<Deal?>(
        key: ValueKey('sync_$tick'),
        stream: db.watchDeal(widget.dealId),
        builder: (_, dealSnapshot) {
        final deal = dealSnapshot.data;
        if (deal == null) {
          return Scaffold(
            backgroundColor: crmPageBackground(dark),
            appBar: AppBar(title: const Text('Deal')),
            body: Center(
              child: Text(
                'Not found',
                style: TextStyle(color: crmMutedTextColor(dark)),
              ),
            ),
          );
        }
        return FutureBuilder<Contact?>(
          future: db.getContact(deal.contactId),
          builder: (_, contactSnapshot) {
            final contact = contactSnapshot.data;
            return Scaffold(
              backgroundColor: crmPageBackground(dark),
              appBar: AppBar(
                title: Text(deal.title),
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
                        _showEdit(deal);
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: crmElevatedSurfaceColor(dark),
                            title: Text('Delete ${deal.title}?',
                                style:
                                    TextStyle(color: crmBodyTextColor(dark))),
                            content: Text('This action cannot be undone.',
                                style:
                                    TextStyle(color: crmMutedTextColor(dark))),
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
                          await db.deleteDeal(widget.dealId);
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
                          Tab(text: 'Activity'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tab,
                children: [
                  _overviewTab(deal, contact, dark, primary),
                  _activityTab(deal.id, dark, primary),
                ],
              ),
            );
          },
        );
      },
      ),
    );
  }

  Widget _overviewTab(Deal deal, Contact? contact, bool dark, Color primary) {
    final stageColor = _stageColor(deal.stage);
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.handshake_outlined,
                          color: stageColor, size: 26),
                    ),
                    const SizedBox(height: 14),
                    CrmInlineTitle(
                      value: deal.title,
                      dark: dark,
                      placeholder: 'Deal title',
                      onSave: (value) async {
                        await db.updateDeal(
                          deal.id,
                          DealsCompanion(title: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    CrmChip(
                      label: _stageLabel(deal.stage),
                      dark: dark,
                      accent: stageColor,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: crmBorderColor(dark)),
              _panelSectionHeader('Overview', dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: [
                    if (contact != null)
                      _readonlyField(
                        icon: Icons.person_outline_rounded,
                        label: 'Contact',
                        value: contact.name,
                        dark: dark,
                      ),
                    if (contact?.company != null &&
                        contact!.company!.isNotEmpty)
                      _readonlyField(
                        icon: Icons.business_outlined,
                        label: 'Company',
                        value: contact.company!,
                        dark: dark,
                      ),
                    CrmInlineDropdownField<String>(
                      icon: Icons.flag_outlined,
                      label: 'Stage',
                      value: deal.stage,
                      dark: dark,
                      items: const [
                        DropdownMenuItem(value: 'lead', child: Text('Lead')),
                        DropdownMenuItem(
                          value: 'contacted',
                          child: Text('Contacted'),
                        ),
                        DropdownMenuItem(
                            value: 'quoting', child: Text('Quoting')),
                        DropdownMenuItem(
                          value: 'negotiation',
                          child: Text('Negotiation'),
                        ),
                        DropdownMenuItem(value: 'won', child: Text('Won')),
                        DropdownMenuItem(value: 'lost', child: Text('Lost')),
                      ],
                      onChanged: (value) async {
                        if (value == null || value == deal.stage) return;
                        await db.updateDeal(
                          deal.id,
                          DealsCompanion(stage: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.attach_money_rounded,
                      label: 'Value',
                      value: deal.value == null
                          ? ''
                          : deal.value!.toStringAsFixed(0),
                      dark: dark,
                      placeholder: 'No value',
                      keyboardType: TextInputType.number,
                      onSave: (value) async {
                        await db.updateDeal(
                          deal.id,
                          DealsCompanion(
                              value: Value(double.tryParse(value ?? ''))),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.query_stats_rounded,
                      label: 'Probability',
                      value: deal.probability?.toString() ?? '',
                      dark: dark,
                      placeholder: '0-100',
                      keyboardType: TextInputType.number,
                      onSave: (value) async {
                        await db.updateDeal(
                          deal.id,
                          DealsCompanion(
                              probability: Value(int.tryParse(value ?? ''))),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.event_outlined,
                      label: 'Close',
                      value: deal.expectedCloseDate == null
                          ? ''
                          : _formatDateTime(deal.expectedCloseDate!),
                      dark: dark,
                      placeholder: 'MM/DD HH:MM',
                      onSave: (value) async {
                        await db.updateDeal(
                          deal.id,
                          DealsCompanion(
                            expectedCloseDate:
                                Value(_parseFlexibleDateTime(value)),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    _readonlyField(
                      icon: Icons.schedule_outlined,
                      label: 'Created',
                      value: _formatDateTime(deal.createdAt),
                      dark: dark,
                    ),
                    _readonlyField(
                      icon: Icons.update_outlined,
                      label: 'Updated',
                      value: _formatDateTime(deal.updatedAt),
                      dark: dark,
                    ),
                  ],
                ),
              ),
              _panelSectionHeader('Notes', dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: CrmInlineField(
                  icon: Icons.note_alt_outlined,
                  label: 'Notes',
                  value: deal.notes ?? '',
                  dark: dark,
                  placeholder: 'Click to add notes',
                  minLines: 4,
                  maxLines: 8,
                  onSave: (value) async {
                    await db.updateDeal(
                      deal.id,
                      DealsCompanion(notes: Value(value)),
                    );
                    if (mounted) setState(() {});
                  },
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
                title: 'Value',
                dark: dark,
                child: _metricValue(
                  deal.value == null
                      ? '-'
                      : '\$${deal.value!.toStringAsFixed(0)}',
                  'deal size',
                  dark,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _infoCard(
                title: 'Probability',
                dark: dark,
                child: _metricValue(
                  deal.probability == null ? '-' : '${deal.probability}%',
                  'win likelihood',
                  dark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _infoCard(
          title: 'Linked Contact',
          dark: dark,
          child: contact == null
              ? crmMutedText('No linked contact', dark)
              : Row(
                  children: [
                    CrmAvatarBadge(
                        seed: contact.name, accent: primary, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          crmBodyText(contact.name, dark,
                              weight: FontWeight.w600),
                          const SizedBox(height: 4),
                          crmMutedText(contact.company ?? 'No company', dark),
                        ],
                      ),
                    ),
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
  }

  Widget _activityTab(int dealId, bool dark, Color primary) {
    return StreamBuilder<List<Activity>>(
      stream: db.watchActivitiesForDeal(dealId),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded,
                    size: 44, color: crmMutedTextColor(dark)),
                const SizedBox(height: 10),
                Text(
                  'No deal activity yet',
                  style:
                      TextStyle(fontSize: 13, color: crmMutedTextColor(dark)),
                ),
              ],
            ),
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          interactive: true,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: activities.length,
            itemBuilder: (_, index) {
              final activity = activities[index];
              final accent = _activityColor(activity.type, primary);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CrmSurface(
                  dark: dark,
                  radius: 14,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CrmChip(
                            label: activity.type.toUpperCase(),
                            dark: dark,
                            accent: accent,
                          ),
                          const Spacer(),
                          crmMutedText(
                              _formatDateTime(activity.createdAt), dark),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activity.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: crmBodyTextColor(dark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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

  Future<void> _showEdit(Deal deal) async {
    final dark = crmIsDark(context);
    final controller = TextEditingController(text: deal.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmElevatedSurfaceColor(dark),
        title:
            Text('Edit Deal', style: TextStyle(color: crmBodyTextColor(dark))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: crmBodyTextColor(dark)),
          decoration: InputDecoration(
            labelText: 'Title',
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
    if (result != null && result.trim().isNotEmpty && result != deal.title) {
      await db.updateDeal(
        deal.id,
        DealsCompanion(title: Value(result.trim())),
      );
      if (mounted) setState(() {});
    }
    controller.dispose();
  }
}

DateTime? _parseFlexibleDateTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final text = raw.trim();
  final direct = DateTime.tryParse(text);
  if (direct != null) return direct;
  final now = DateTime.now();
  final withTime = RegExp(r'^(\d{1,2})/(\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?$')
      .firstMatch(text);
  if (withTime != null) {
    return DateTime(
      now.year,
      int.parse(withTime.group(1)!),
      int.parse(withTime.group(2)!),
      int.parse(withTime.group(3) ?? '0'),
      int.parse(withTime.group(4) ?? '0'),
    );
  }
  return null;
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
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

Color _activityColor(String type, Color primary) {
  return {
        'call': const Color(0xFF42A5F5),
        'visit': const Color(0xFF66BB6A),
        'email': const Color(0xFFFFA726),
        'quote': const Color(0xFFAB47BC),
        'contract': primary,
        'note': const Color(0xFF9E9E9E),
      }[type] ??
      primary;
}

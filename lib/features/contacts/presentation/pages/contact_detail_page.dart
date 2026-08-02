import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../../core/database/database.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';
import '../widgets/crm_design.dart';
import 'deal_detail_page.dart';

class ContactDetailPage extends StatefulWidget {
  final int contactId;

  const ContactDetailPage({super.key, required this.contactId});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage>
    with SingleTickerProviderStateMixin {
  AppDatabase get db => getIt<AppDatabase>();
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
      builder: (_, tick, __) => StreamBuilder<Contact?>(
        key: ValueKey('sync_$tick'),
        stream: db.watchContact(widget.contactId),
        builder: (_, snapshot) {
        final contact = snapshot.data;
        if (contact == null) {
          return Scaffold(
            backgroundColor: crmPageBackground(dark),
            appBar: AppBar(title: const Text('Contact')),
            body: Center(
              child: Text(
                'Not found',
                style: TextStyle(color: crmMutedTextColor(dark)),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: crmPageBackground(dark),
          appBar: AppBar(
            title: Text(contact.name),
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
                    _showEdit(contact);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: crmElevatedSurfaceColor(dark),
                        title: Text('Delete ${contact.name}?',
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
                      await db.deleteContact(widget.contactId);
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
              _overviewTab(contact, dark, primary),
              _activityTab(dark, primary),
              _dealsTab(dark, primary),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _overviewTab(Contact contact, bool dark, Color primary) {
    final aliases = _decodeAliases(contact.aliases);
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
                        seed: contact.name, accent: primary, size: 56),
                    const SizedBox(height: 14),
                    CrmInlineTitle(
                      value: contact.name,
                      dark: dark,
                      placeholder: 'Contact name',
                      onSave: (value) async {
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(name: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created ${_formatRelative(contact.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: crmMutedTextColor(dark),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: crmBorderColor(dark)),
              _panelSectionHeader('Details', dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: [
                    CrmInlineField(
                      icon: Icons.business_outlined,
                      label: 'Company',
                      value: contact.company ?? '',
                      dark: dark,
                      placeholder: 'No company',
                      onSave: (value) async {
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(company: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: contact.role ?? '',
                      dark: dark,
                      placeholder: 'No role',
                      onSave: (value) async {
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(role: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: contact.phone ?? '',
                      dark: dark,
                      placeholder: 'No phone',
                      keyboardType: TextInputType.phone,
                      onSave: (value) async {
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(phone: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.alternate_email_rounded,
                      label: 'Email',
                      value: contact.email ?? '',
                      dark: dark,
                      placeholder: 'No email',
                      keyboardType: TextInputType.emailAddress,
                      onSave: (value) async {
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(email: Value(value)),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    CrmInlineField(
                      icon: Icons.sell_outlined,
                      label: 'Aliases',
                      value: aliases.join(', '),
                      dark: dark,
                      placeholder: 'Comma separated aliases',
                      onSave: (value) async {
                        final normalized = (value ?? '')
                            .split(',')
                            .map((entry) => entry.trim())
                            .where((entry) => entry.isNotEmpty)
                            .toList();
                        await db.updateContact(
                          contact.id,
                          ContactsCompanion(
                              aliases: Value(jsonEncode(normalized))),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    _readonlyField(
                      icon: Icons.schedule_outlined,
                      label: 'Created',
                      value: _formatDateTime(contact.createdAt),
                      dark: dark,
                    ),
                    _readonlyField(
                      icon: Icons.update_outlined,
                      label: 'Updated',
                      value: _formatDateTime(contact.updatedAt),
                      dark: dark,
                    ),
                  ],
                ),
              ),
              _panelSectionHeader('Aliases', dark),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: aliases.isEmpty
                      ? crmMutedText('No aliases', dark)
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final alias in aliases)
                              CrmChip(
                                  label: alias, dark: dark, accent: primary),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );

    final sideCards = Column(
      children: [
        _infoCard(
          title: 'Snapshot',
          dark: dark,
          child: Column(
            children: [
              _metaMetric(
                label: 'Company',
                value: contact.company ?? 'Unassigned',
                dark: dark,
              ),
              _metaMetric(
                label: 'Role',
                value: contact.role ?? 'Not set',
                dark: dark,
              ),
              _metaMetric(
                label: 'Aliases',
                value: aliases.isEmpty ? '0' : aliases.length.toString(),
                dark: dark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          title: 'Notes',
          dark: dark,
          child: CrmInlineField(
            icon: Icons.note_alt_outlined,
            label: 'Notes',
            value: contact.notes ?? '',
            dark: dark,
            placeholder: 'Click to add notes',
            minLines: 4,
            maxLines: 8,
            onSave: (value) async {
              await db.updateContact(
                contact.id,
                ContactsCompanion(notes: Value(value)),
              );
              if (mounted) setState(() {});
            },
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

  Widget _activityTab(bool dark, Color primary) {
    return StreamBuilder<List<Activity>>(
      stream: db.watchActivitiesForContact(widget.contactId),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return _emptyState(
            title: 'No activity yet',
            icon: Icons.history_toggle_off_rounded,
            dark: dark,
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          interactive: true,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: activities.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _activityCard(activities[index], dark, primary),
              );
            },
          ),
        );
      },
    );
  }

  Widget _activityCard(Activity activity, bool dark, Color primary) {
    const typeIcons = {
      'call': Icons.phone_in_talk_outlined,
      'visit': Icons.meeting_room_outlined,
      'email': Icons.mail_outline_rounded,
      'quote': Icons.description_outlined,
      'contract': Icons.article_outlined,
      'note': Icons.note_alt_outlined,
    };
    final accent = {
          'call': const Color(0xFF42A5F5),
          'visit': const Color(0xFF66BB6A),
          'email': const Color(0xFFFFA726),
          'quote': const Color(0xFFAB47BC),
          'contract': primary,
          'note': const Color(0xFF9E9E9E),
        }[activity.type] ??
        primary;
    return CrmSurface(
      dark: dark,
      radius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  typeIcons[activity.type] ?? Icons.circle_outlined,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              CrmChip(
                label: activity.type.toUpperCase(),
                dark: dark,
                accent: accent,
              ),
              const Spacer(),
              crmMutedText(_formatDateTime(activity.createdAt), dark),
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
    );
  }

  Widget _dealsTab(bool dark, Color primary) {
    return StreamBuilder<List<Deal>>(
      stream: db.watchDealsForContact(widget.contactId),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final deals = snapshot.data!;
        if (deals.isEmpty) {
          return _emptyState(
            title: 'No deals yet',
            icon: Icons.handshake_outlined,
            dark: dark,
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          interactive: true,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: deals.length,
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _dealCard(deals[index], dark, primary),
              );
            },
          ),
        );
      },
    );
  }

  Widget _dealCard(Deal deal, bool dark, Color primary) {
    final accent = _stageColor(deal.stage);
    final label = _stageLabel(deal.stage);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DealDetailPage(dealId: deal.id)),
      ),
      child: CrmSurface(
        dark: dark,
        radius: 14,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deal.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: crmBodyTextColor(dark),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CrmChip(label: label, dark: dark, accent: accent),
              ],
            ),
            if (deal.value != null) ...[
              const SizedBox(height: 8),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 70, child: crmMutedText('Probability', dark)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: deal.probability! / 100,
                        minHeight: 6,
                        backgroundColor: crmBorderColor(dark),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
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

  Widget _metaMetric({
    required String label,
    required String value,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: crmMutedText(label, dark)),
          Expanded(child: crmBodyText(value, dark, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required IconData icon,
    required bool dark,
  }) {
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

  List<String> _decodeAliases(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  Future<void> _showEdit(Contact contact) async {
    final dark = crmIsDark(context);
    final controller = TextEditingController(text: contact.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: crmElevatedSurfaceColor(dark),
        title: Text('Edit Contact',
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
    if (result != null && result.trim().isNotEmpty && result != contact.name) {
      await db.updateContact(
        contact.id,
        ContactsCompanion(name: Value(result.trim())),
      );
      if (mounted) setState(() {});
    }
    controller.dispose();
  }
}

String _formatDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

String _formatRelative(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
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

import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/theme_config.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  SyncService get ss => getIt<SyncService>();

  static const _frequencyOptions = [1, 5, 10, 15, 30, 60, 120, 360, 720, 1440];

  String _frequencyLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final r = minutes % 60;
    return r > 0 ? '${h}h ${r}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? TwentyTokens.darkBg : TwentyTokens.lightBg;
    final cb = d ? TwentyTokens.darkCard : TwentyTokens.lightCard;
    final bd = d ? TwentyTokens.darkBorder : TwentyTokens.lightBorder;
    final primary = getIt<ThemeConfig>().primaryColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Sync Mode'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: ss,
        builder: (context, _) {
          final mode = ss.pbSyncMode;
          return ListView(
            padding: const EdgeInsets.all(TwentyTokens.paddingPage),
            children: [
              _sectionHeader('Mode'),
              _card(cb, bd, [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SegmentedButton<PbSyncMode>(
                    segments: const [
                      ButtonSegment(value: PbSyncMode.manual, label: Text('Manual', style: TextStyle(fontSize: 13))),
                      ButtonSegment(value: PbSyncMode.auto, label: Text('Auto', style: TextStyle(fontSize: 13))),
                      ButtonSegment(value: PbSyncMode.smart, label: Text('Smart', style: TextStyle(fontSize: 13))),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => ss.setPbSyncMode(v.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.15);
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return primary;
                        return d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight;
                      }),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (mode == PbSyncMode.manual) _buildManualInfo(cb, bd, d),
              if (mode == PbSyncMode.auto || mode == PbSyncMode.smart) ...[
                _buildFrequencySection(cb, bd, d),
                const SizedBox(height: 16),
                _buildScheduledSection(cb, bd, d, primary),
              ],
              if (mode == PbSyncMode.smart) ...[
                const SizedBox(height: 16),
                _buildLifecycleSection(cb, bd, d),
              ],
            ],
          );
        },
      ),
    );
  }

  // --- Manual Mode ---

  Widget _buildManualInfo(Color cb, Color bd, bool d) {
    return _card(cb, bd, [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only sync when you tap "Sync Now" or pull down to refresh.',
                style: TextStyle(fontSize: 13, color: d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // --- Frequency Section (Auto & Smart) ---

  Widget _buildFrequencySection(Color cb, Color bd, bool d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Sync Frequency'),
      _card(cb, bd, [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('System will auto-sync at this interval.',
                style: TextStyle(fontSize: 12, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencyOptions.map((m) {
                final sel = ss.autoConfig.intervalMinutes == m;
                return ChoiceChip(
                  label: Text(_frequencyLabel(m), style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
                  selected: sel,
                  selectedColor: getIt<ThemeConfig>().primaryColor,
                  onSelected: (_) => ss.setAutoConfig(intervalMinutes: m),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
    ]);
  }

  // --- Scheduled Time Section (Auto & Smart) ---

  Widget _buildScheduledSection(Color cb, Color bd, bool d, Color primary) {
    final timeStr = ss.autoConfig.scheduledTime ?? 'Not set';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Daily Scheduled'),
      _card(cb, bd, [
        ListTile(
          leading: Icon(Icons.schedule, size: 20, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
          title: const Text('Sync at fixed time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('Optional: trigger sync at a specific time each day.',
              style: TextStyle(fontSize: 11, color: d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(timeStr, style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
          ]),
          onTap: () => _pickTime(),
        ),
        if (ss.autoConfig.scheduledTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 14, bottom: 10),
            child: TextButton(
              onPressed: () => ss.setAutoConfig(scheduledTime: null),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
              child: const Text('Clear', style: TextStyle(fontSize: 11)),
            ),
          ),
      ]),
    ]);
  }

  // --- Lifecycle Section (Smart Only) ---

  Widget _buildLifecycleSection(Color cb, Color bd, bool d) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('App Event Triggers'),
      _card(cb, bd, [
        SwitchListTile(
          secondary: Icon(Icons.exit_to_app, size: 20, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
          title: const Text('Sync on app resume', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('Trigger sync when app comes back to foreground.',
              style: TextStyle(fontSize: 11, color: d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight)),
          value: ss.autoConfig.syncOnResume,
          onChanged: (v) => ss.setAutoConfig(syncOnResume: v),
          activeThumbColor: getIt<ThemeConfig>().primaryColor,
          activeTrackColor: getIt<ThemeConfig>().primaryColor.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
        _divider(bd),
        SwitchListTile(
          secondary: Icon(Icons.bedtime, size: 20, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
          title: const Text('Sync on app pause', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('Best-effort quick push when app goes to background.',
              style: TextStyle(fontSize: 11, color: d ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight)),
          value: ss.autoConfig.syncOnPause,
          onChanged: (v) => ss.setAutoConfig(syncOnPause: v),
          activeThumbColor: getIt<ThemeConfig>().primaryColor,
          activeTrackColor: getIt<ThemeConfig>().primaryColor.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      ]),
    ]);
  }

  // --- Helpers ---

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: TwentyTokens.fontSizeSm,
                fontWeight: TwentyTokens.weightSemibold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? TwentyTokens.textMutedDark
                    : TwentyTokens.textMutedLight,
                letterSpacing: 0.5)),
      );

  Widget _card(Color bg, Color bd, List<Widget> children) =>
      Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TwentyTokens.radiusLg), border: Border.all(color: bd)), child: Column(children: children));

  Widget _divider(Color c) => Divider(height: 1, color: c, indent: 54);

  void _pickTime() {
    TimeOfDay? picked = TimeOfDay.now();
    final existing = ss.autoConfig.scheduledTime;
    if (existing != null && existing.isNotEmpty) {
      final parts = existing.split(':');
      if (parts.length == 2) {
        picked = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    showTimePicker(context: context, initialTime: picked).then((t) {
      if (t == null || !mounted) return;
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      ss.setAutoConfig(scheduledTime: '$hh:$mm');
    });
  }
}

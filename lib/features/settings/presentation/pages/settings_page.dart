import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/vault/vault_service.dart';
import '../../../../core/vault/fts_index_service.dart';
import '../../../../core/theme/theme_config.dart';
import 'sync_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppDatabase get db => getIt<AppDatabase>();
  VaultService get vs => getIt<VaultService>();
  FtsIndexService get fts => getIt<FtsIndexService>();
  ThemeConfig get tc => getIt<ThemeConfig>();
  SyncService get ss => getIt<SyncService>();

  final _vCtrl = TextEditingController();
  final _pbUrlCtrl = TextEditingController();
  final _pbEmailCtrl = TextEditingController();
  final _pbPassCtrl = TextEditingController();
  String _vPath = ''; bool _vOk = false; bool _rebuilding = false;
  bool _pbConnecting = false;

  /// Get current device LAN IPs (192.168.x.x / 10.x.x.x).
  Future<List<String>> _getLocalIps() async {
    final ips = <String>[];
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    return ips;
  }

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _vCtrl.dispose(); _pbUrlCtrl.dispose(); _pbEmailCtrl.dispose(); _pbPassCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await db.getConfig('vault_path'); _vPath = p ?? ''; _vOk = _vPath.isNotEmpty; _vCtrl.text = _vPath;
    _pbUrlCtrl.text = await db.getConfig('pb_server_url') ?? '';
    _pbEmailCtrl.text = await db.getConfig('pb_email') ?? '';
    _pbPassCtrl.text = await db.getConfig('pb_password') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _saveV() async { final x = _vCtrl.text.trim(); if (x.isEmpty) return; await db.setConfig('vault_path', x); await vs.initialize(x); await fts.initialize(x); if (mounted) { setState(() { _vPath = x; _vOk = true; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vault: $x'))); } }
  Future<void> _defV() async { _vCtrl.text = p.join((await getApplicationDocumentsDirectory()).path, 'LocusVault'); await _saveV(); }
  Future<void> _rebuildIdx() async { if (!_vOk) return; setState(() => _rebuilding = true); await fts.rebuildAll(vs); if (mounted) { setState(() => _rebuilding = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fts.documentCount} files indexed'))); } }

  void _setMode(ThemeMode m) async { tc.update(themeMode: m); await db.setConfig('theme_mode', m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system'); }
  void _setColor(String key) async { final c = ThemeConfig.colorOptions[key]!; tc.update(primaryColor: c); await db.setConfig('theme_color', key); }
  void _setFont(String key) async { final s = ThemeConfig.fontScales[key] ?? 1.0; tc.update(fontScale: s); await db.setConfig('font_scale', key); }

  String _modeLabel() { switch (tc.themeMode) { case ThemeMode.light: return 'Light'; case ThemeMode.dark: return 'Dark'; default: return 'System'; } }
  String _colorLabel() { for (final e in ThemeConfig.colorOptions.entries) { if (e.value == tc.primaryColor) return ThemeConfig.colorNames[e.key] ?? 'Coral'; } return 'Coral'; }
  String _fontLabel() { for (final e in ThemeConfig.fontScales.entries) { if (e.value == tc.fontScale) return ThemeConfig.fontScaleNames[e.key] ?? 'Medium'; } return 'Medium'; }
  String _syncModeLabel() { switch (ss.pbSyncMode) { case PbSyncMode.manual: return 'Manual'; case PbSyncMode.auto: return 'Auto'; case PbSyncMode.smart: return 'Smart'; } }


  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final primary = tc.primaryColor;
    final bg = d ? TwentyTokens.darkBg : TwentyTokens.lightBg;
    final cb = d ? TwentyTokens.darkCard : TwentyTokens.lightCard;
    final bd = d ? TwentyTokens.darkBorder : TwentyTokens.lightBorder;
    return Scaffold(backgroundColor: bg, appBar: AppBar(title: const Text('Settings'), centerTitle: true, scrolledUnderElevation: 0, backgroundColor: Colors.transparent), body: ListView(padding: const EdgeInsets.all(TwentyTokens.paddingPage), children: [
      _sec('Appearance'), _card(cb, bd, [
        _tile(Icons.palette_outlined, 'Theme Mode', _modeLabel(), () => _pickMode()),
        _divider(bd), _tile(Icons.color_lens_outlined, 'Color Scheme', _colorLabel(), () => _pickColor(), trailing: _dots(primary)),
        _divider(bd), _tile(Icons.text_fields, 'Font Size', _fontLabel(), () => _pickFont()),
      ]), const SizedBox(height: 20),
      _sec('Vault'), _card(cb, bd, [
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.folder_outlined, size: 18), const SizedBox(width: 8), const Text('Vault Path', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)), const Spacer(), if (_vOk) _badge('Active', Colors.green)]),
          const SizedBox(height: 8), TextField(controller: _vCtrl, style: TextStyle(fontSize: 12, color: d ? TwentyTokens.textPrimaryDark : TwentyTokens.textPrimaryLight), decoration: InputDecoration(hintText: 'Enter vault path...', hintStyle: TextStyle(fontSize: 12, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true)),
          const SizedBox(height: 8), Row(children: [TextButton.icon(onPressed: _defV, icon: const Icon(Icons.home_outlined, size: 14), label: const Text('Default', style: TextStyle(fontSize: 11)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))), const Spacer(), ElevatedButton(onPressed: _saveV, style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)), child: const Text('Save', style: TextStyle(fontSize: 11)))])],
        )), _divider(bd), _tile(Icons.storage_outlined, 'FTS Index', '${fts.documentCount} files indexed', _rebuildIdx, trailing: _rebuilding ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null),
      ]), const SizedBox(height: 20),
      _sec('AI'), _card(cb, bd, [_tile(Icons.key, 'API Key', 'DeepSeek  deepseek-chat', () {}), _divider(bd), _tile(Icons.tune, 'Model', 'deepseek-chat', () {})]),
      const SizedBox(height: 20),
      _sec('PocketBase Sync'),
      // --- Sync Mode Selector ---
      ListenableBuilder(
        listenable: ss,
        builder: (context, _) => _card(cb, bd, [
          _tile(Icons.sync, 'Sync Mode', _syncModeLabel(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncSettingsPage()))),
        ]),
      ),
      const SizedBox(height: 12),
      // --- PocketBase Server Connection ---
      ListenableBuilder(
        listenable: ss,
        builder: (context, _) => _card(cb, bd, [
          Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.dns_outlined, size: 18),
              const SizedBox(width: 8),
              const Text('Server', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const Spacer(),
              if (ss.isPbConnected) _badge('Connected', Colors.green) else _badge('Offline', Colors.grey),
            ]),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _getLocalIps(),
              builder: (ctx, snap) {
                final ips = snap.data ?? [];
                if (ips.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.lan, size: 12, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Expanded(child: Text('This device IPs: ${ips.join(', ')}', style: TextStyle(fontSize: 10, color: Colors.orange[800]))),
                    GestureDetector(
                      onTap: () { Clipboard.setData(ClipboardData(text: ips.first)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP copied'))); },
                      child: Icon(Icons.copy, size: 12, color: Colors.orange[600]),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(controller: _pbUrlCtrl, style: _fieldStyle(d), decoration: _fieldDeco('Server URL (e.g. http://192.168.x.x:8090)', d), keyboardType: TextInputType.url),
            const SizedBox(height: 6),
            TextField(controller: _pbEmailCtrl, style: _fieldStyle(d), decoration: _fieldDeco('Admin Email', d), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 6),
            TextField(controller: _pbPassCtrl, style: _fieldStyle(d), decoration: _fieldDeco('Admin Password', d), obscureText: true),
            const SizedBox(height: 10),
            Row(children: [
              if (ss.isPbConnected)
                TextButton.icon(onPressed: _pbDisconnect, icon: const Icon(Icons.link_off, size: 14), label: const Text('Disconnect', style: TextStyle(fontSize: 11)), style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)))
              else
                ElevatedButton.icon(
                  onPressed: _pbConnecting ? null : _pbConnect,
                  icon: _pbConnecting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.link, size: 14),
                  label: const Text('Connect', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (ss.isPbConnected && !_pbConnecting) ? _pbSyncNow : null,
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Sync Now', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: primary.withValues(alpha: 0.8), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
              ),
            ]),
          ])),
        ]),
      ),
      const SizedBox(height: 20), _sec('Data'), _card(cb, bd, [_tile(Icons.lock_outlined, 'Database', 'SQLCipher AES-256', () {})]),
    ]));
  }

  Widget _sec(String t) => Padding(padding: const EdgeInsets.only(left: 2, bottom: 8), child: Text(t, style: TextStyle(fontSize: TwentyTokens.fontSizeSm, fontWeight: TwentyTokens.weightSemibold, color: Theme.of(context).brightness == Brightness.dark ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight, letterSpacing: 0.5)));
  Widget _card(Color bg, Color bd, List<Widget> c) => Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TwentyTokens.radiusLg), border: Border.all(color: bd)), child: Column(children: c));
  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback? onTap, {Widget? trailing}) => ListTile(leading: Icon(icon, size: 20, color: Theme.of(context).brightness == Brightness.dark ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? TwentyTokens.textSecondaryDark : TwentyTokens.textSecondaryLight)) : null, trailing: trailing, onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2));
  Widget _divider(Color c) => Divider(height: 1, color: c, indent: 54);
  Widget _badge(String l, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(l, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)));

  TextStyle _fieldStyle(bool d) => TextStyle(fontSize: 12, color: d ? TwentyTokens.textPrimaryDark : TwentyTokens.textPrimaryLight);
  InputDecoration _fieldDeco(String hint, bool d) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 12, color: d ? TwentyTokens.textMutedDark : TwentyTokens.textMutedLight),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    isDense: true,
  );

  Widget _dots(Color cur) => Row(mainAxisSize: MainAxisSize.min, children: ThemeConfig.colorOptions.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 6), child: GestureDetector(onTap: () => _setColor(e.key), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle, border: cur == e.value ? Border.all(color: Colors.white, width: 2.5) : null, boxShadow: cur == e.value ? [BoxShadow(color: e.value.withValues(alpha: 0.4), blurRadius: 6)] : null))))).toList());

  void _pickMode() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Theme Mode'), children: [
    _opt('System', tc.themeMode == ThemeMode.system, () => _setMode(ThemeMode.system)),
    _opt('Light', tc.themeMode == ThemeMode.light, () => _setMode(ThemeMode.light)),
    _opt('Dark', tc.themeMode == ThemeMode.dark, () => _setMode(ThemeMode.dark)),
  ]));

  void _pickColor() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Color Scheme'), children: ThemeConfig.colorOptions.entries.map((e) => _opt(ThemeConfig.colorNames[e.key] ?? e.key, tc.primaryColor == e.value, () => _setColor(e.key), color: e.value)).toList()));
  void _pickFont() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Font Size'), children: ThemeConfig.fontScales.entries.map((e) => _opt(ThemeConfig.fontScaleNames[e.key] ?? e.key, tc.fontScale == e.value, () => _setFont(e.key))).toList()));


  Future<void> _pbConnect() async {
    final url = _pbUrlCtrl.text.trim();
    final email = _pbEmailCtrl.text.trim();
    final pass = _pbPassCtrl.text.trim();
    if (url.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all PocketBase fields')));
      return;
    }
    setState(() => _pbConnecting = true);
    final err = await ss.connectPocketBase(serverUrl: url, email: email, password: pass);
    setState(() => _pbConnecting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err == null ? 'Connected to PocketBase' : 'Failed: $err'),
      ));
    }
  }

  Future<void> _pbSyncNow() async {
    setState(() => _pbConnecting = true);
    final result = await ss.triggerPbSync(fromUser: true);
    setState(() => _pbConnecting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result ?? 'Sync completed'),
      ));
    }
  }

  void _pbDisconnect() {
    ss.disconnectPocketBase();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disconnected from PocketBase')));
  }

  Widget _opt(String label, bool sel, VoidCallback onTap, {Color? color}) => SimpleDialogOption(onPressed: () { onTap(); Navigator.pop(context); }, child: Row(children: [if (color != null) Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)), Expanded(child: Text(label)), if (sel) const Icon(Icons.check, size: 18, color: Color(0xFFFF6B6B))]));
}

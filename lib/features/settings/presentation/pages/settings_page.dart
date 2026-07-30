import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/vault/vault_service.dart';
import '../../../../core/vault/fts_index_service.dart';
import '../../../../core/theme/theme_config.dart';

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

  final _vCtrl = TextEditingController();
  String _vPath = ''; bool _vOk = false; bool _rebuilding = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _vCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = await db.getConfig('vault_path'); _vPath = p ?? ''; _vOk = _vPath.isNotEmpty; _vCtrl.text = _vPath;
    if (mounted) setState(() {});
  }

  Future<void> _saveV() async { final x = _vCtrl.text.trim(); if (x.isEmpty) return; await db.setConfig('vault_path', x); await vs.initialize(x); await fts.initialize(x); if (mounted) { setState(() { _vPath = x; _vOk = true; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vault: $x'))); } }
  Future<void> _defV() async { _vCtrl.text = p.join((await getApplicationDocumentsDirectory()).path, 'LocusVault'); await _saveV(); }
  Future<void> _rebuildIdx() async { if (!_vOk) return; setState(() => _rebuilding = true); await fts.rebuildAll(vs); if (mounted) { setState(() => _rebuilding = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fts.documentCount} files indexed'))); } }

  // Theme actions - instant via ThemeConfig
  void _setMode(ThemeMode m) async {
    tc.update(themeMode: m);
    await db.setConfig('theme_mode', m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system');
  }

  void _setColor(String key) async {
    final c = ThemeConfig.colorOptions[key]!;
    tc.update(primaryColor: c);
    await db.setConfig('theme_color', key);
  }

  void _setFont(String key) async {
    final s = ThemeConfig.fontScales[key] ?? 1.0;
    tc.update(fontScale: s);
    await db.setConfig('font_scale', key);
  }

  String _modeLabel() { switch (tc.themeMode) { case ThemeMode.light: return 'Light'; case ThemeMode.dark: return 'Dark'; default: return 'System'; } }
  String _colorLabel() { for (final e in ThemeConfig.colorOptions.entries) { if (e.value == tc.primaryColor) return ThemeConfig.colorNames[e.key] ?? 'Coral'; } return 'Coral'; }
  String _fontLabel() { for (final e in ThemeConfig.fontScales.entries) { if (e.value == tc.fontScale) return ThemeConfig.fontScaleNames[e.key] ?? 'Medium'; } return 'Medium'; }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
    final cb = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bd = isDark ? Colors.white10 : Colors.black12;
    final primary = tc.primaryColor;

    return Scaffold(backgroundColor: bg, appBar: AppBar(title: const Text('Settings'), centerTitle: true, scrolledUnderElevation: 0, backgroundColor: Colors.transparent), body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
      _sec('Appearance'), _card(cb, bd, [
        _tile(Icons.palette_outlined, 'Theme Mode', _modeLabel(), () => _pickMode()),
        _divider(bd),
        _tile(Icons.color_lens_outlined, 'Color Scheme', _colorLabel(), () => _pickColor(), trailing: _dots(primary)),
        _divider(bd),
        _tile(Icons.text_fields, 'Font Size', _fontLabel(), () => _pickFont()),
      ]),
      const SizedBox(height: 20),
      _sec('Vault'), _card(cb, bd, [
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.folder_outlined, size: 18), const SizedBox(width: 8), const Text('Vault Path', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)), const Spacer(), if (_vOk) _badge('Active', Colors.green)]),
          const SizedBox(height: 8), TextField(controller: _vCtrl, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87), decoration: InputDecoration(hintText: 'Enter vault path...', hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.grey[400]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true)),
          const SizedBox(height: 8), Row(children: [TextButton.icon(onPressed: _defV, icon: const Icon(Icons.home_outlined, size: 14), label: const Text('Default', style: TextStyle(fontSize: 11)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))), const Spacer(), ElevatedButton(onPressed: _saveV, style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)), child: const Text('Save', style: TextStyle(fontSize: 11)))])],
        )),
        _divider(bd), _tile(Icons.storage_outlined, 'FTS Index', '${fts.documentCount} files indexed', _rebuildIdx, trailing: _rebuilding ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null),
      ]),
      const SizedBox(height: 20),
      _sec('AI'), _card(cb, bd, [_tile(Icons.key, 'API Key', 'DeepSeek  deepseek-chat', () {}), _divider(bd), _tile(Icons.tune, 'Model', 'deepseek-chat', () {})]),
      const SizedBox(height: 20),
      _sec('Data'), _card(cb, bd, [_tile(Icons.lock_outlined, 'Database', 'SQLCipher AES-256', () {})]),
    ]));
  }

  Widget _sec(String t) => Padding(padding: const EdgeInsets.only(left: 2, bottom: 8), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)));
  Widget _card(Color bg, Color bd, List<Widget> c) => Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: bd)), child: Column(children: c));
  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback? onTap, {Widget? trailing}) => ListTile(leading: Icon(icon, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.grey[500])) : null, trailing: trailing, onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2));
  Widget _divider(Color c) => Divider(height: 1, color: c, indent: 54);
  Widget _badge(String l, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(l, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)));

  Widget _dots(Color cur) => Row(mainAxisSize: MainAxisSize.min, children: ThemeConfig.colorOptions.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 6), child: GestureDetector(onTap: () => _setColor(e.key), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle, border: cur == e.value ? Border.all(color: Colors.white, width: 2.5) : null, boxShadow: cur == e.value ? [BoxShadow(color: e.value.withValues(alpha: 0.4), blurRadius: 6)] : null))))).toList());

  void _pickMode() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Theme Mode'), children: [
    _opt('System', tc.themeMode == ThemeMode.system, () => _setMode(ThemeMode.system)),
    _opt('Light', tc.themeMode == ThemeMode.light, () => _setMode(ThemeMode.light)),
    _opt('Dark', tc.themeMode == ThemeMode.dark, () => _setMode(ThemeMode.dark)),
  ]));

  void _pickColor() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Color Scheme'), children: ThemeConfig.colorOptions.entries.map((e) => _opt(ThemeConfig.colorNames[e.key] ?? e.key, tc.primaryColor == e.value, () => _setColor(e.key), color: e.value)).toList()));

  void _pickFont() => showDialog(context: context, builder: (ctx) => SimpleDialog(title: const Text('Font Size'), children: ThemeConfig.fontScales.entries.map((e) => _opt(ThemeConfig.fontScaleNames[e.key] ?? e.key, tc.fontScale == e.value, () => _setFont(e.key))).toList()));

  Widget _opt(String label, bool sel, VoidCallback onTap, {Color? color}) => SimpleDialogOption(
    onPressed: () { onTap(); Navigator.pop(context); },
    child: Row(children: [if (color != null) Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)), Expanded(child: Text(label)), if (sel) const Icon(Icons.check, size: 18, color: Color(0xFFFF6B6B))]),
  );
}

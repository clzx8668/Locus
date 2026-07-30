import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/di/service_locator.dart';
import '../../../../core/database/database.dart';
import '../../../../core/utils/intent_router.dart';
import '../../../../core/vault/vault_service.dart';
import '../../../../core/services/ai_route_service.dart';
import '../../../../core/services/disambiguation_engine.dart';

class QuickInputBottomSheet extends StatefulWidget {
  const QuickInputBottomSheet({super.key});
  @override
  State<QuickInputBottomSheet> createState() => _QuickInputBottomSheetState();
}

class _QuickInputBottomSheetState extends State<QuickInputBottomSheet> {
  final db = getIt<AppDatabase>();
  final aiRoute = getIt<AiRouteService>();
  final TextEditingController _tc = TextEditingController();
  final List<String> _imgs = [];
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  ActivityRouteResult? _route;

  Future<void> _pick(ImageSource src) async {
    try { final i = await _picker.pickImage(source: src); if (i != null) setState(() => _imgs.add(i.path)); } catch (_) {}
  }

  void _media() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
    ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
    ListTile(leading: const Icon(Icons.photo_library), title: const Text('From Gallery'), onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
  ])));

  Future<void> _send() async {
    final text = _tc.text.trim();
    if (text.isEmpty && _imgs.isEmpty) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tag = IntentRouter.parseTag(text);
      await db.insertPayload(HubPayloadsCompanion(rawText: d.Value(text), intentTag: d.Value(tag), mediaPaths: d.Value(jsonEncode(_imgs))));
      if (tag == 'CRM' && text.isNotEmpty) {
        final r = await aiRoute.routeActivity(rawText: text, mediaPaths: jsonEncode(_imgs));
        if (mounted) { setState(() { _route = r; _busy = false; }); if (r.isRouted) { if (mounted) Navigator.pop(context); return; } if (r.needsConfirmation) return; }
      }
      try {
        final vs = getIt<VaultService>();
        if (vs.vaultPath != null) {
          final fn = vs.generateFileName(text.isNotEmpty ? text : 'media-note');
          await vs.writeNote(subDir: 'inbox', fileName: fn, frontmatter: {'title': text.isNotEmpty ? text.substring(0, text.length < 60 ? text.length : 60) : 'Media Note', 'type': 'note', 'tags': tag == 'NOTE' ? 'quick-note' : tag.toLowerCase(), 'created': DateTime.now().toIso8601String(), 'source': 'quick-capture', 'intent': tag}, body: text);
          _daily(vs, text);
        }
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    } finally { if (mounted) setState(() => _busy = false); }
  }

  void _daily(VaultService vs, String text) async {
    final now = DateTime.now(); DateTime? dt;
    if (RegExp(r'今天').hasMatch(text)) dt = now;
    if (RegExp(r'明天').hasMatch(text)) dt = now.add(const Duration(days: 1));
    if (RegExp(r'后天').hasMatch(text)) dt = now.add(const Duration(days: 2));
    if (dt != null) {
      final ds = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final fp = p.join(vs.vaultPath!, 'daily', '$ds.md');
      final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (await File(fp).exists()) { await vs.appendToNote(fp, '\n- $ts $text'); }
      else { await vs.writeNote(subDir: 'daily', fileName: '$ds.md', frontmatter: {'title': ds, 'type': 'daily', 'tags': 'daily', 'created': dt.toIso8601String()}, body: '## $ds\n\n- $ts $text\n'); }
    }
  }

  void _confirm(ContactOption o) { setState(() => _route = null); if (mounted) Navigator.pop(context); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 15)]),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        if (_route != null && _route!.needsConfirmation) _confirmBox(primary, isDark),
        if (_imgs.isNotEmpty) Container(height: 72, margin: const EdgeInsets.only(bottom: 12), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _imgs.length, itemBuilder: (_, i) => Stack(children: [Container(margin: const EdgeInsets.only(right: 12, top: 4), width: 64, height: 64, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(_imgs[i])), fit: BoxFit.cover))), Positioned(right: 4, top: 0, child: GestureDetector(onTap: () => setState(() => _imgs.removeAt(i)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white))))]))),
        Row(children: [
          IconButton(icon: Icon(Icons.add_photo_alternate_outlined, color: primary, size: 28), onPressed: _busy ? null : _media),
          Expanded(child: TextField(controller: _tc, maxLines: 4, minLines: 1, autofocus: true, enabled: !_busy, style: const TextStyle(fontSize: 15), decoration: InputDecoration(hintText: 'Quick capture...', hintStyle: TextStyle(color: theme.hintColor, fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
          const SizedBox(width: 4),
          _busy ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: Icon(Icons.send_rounded, color: primary, size: 28), onPressed: _send),
        ]),
      ]),
    ));
  }

  Widget _confirmBox(Color primary, bool isDark) {
    return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.people_outline, size: 16, color: primary), const SizedBox(width: 6), Text('Select contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary))]),
      const SizedBox(height: 8),
      for (final o in _route!.alternatives)
        Padding(padding: const EdgeInsets.only(bottom: 4), child: InkWell(onTap: () => _confirm(o), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(children: [Expanded(child: Text(o.company != null ? '${o.name}  ${o.company}' : o.name, style: const TextStyle(fontSize: 13))), Text(o.matchReason, style: TextStyle(fontSize: 10, color: Colors.grey[500]))])))),
    ]));
  }
}

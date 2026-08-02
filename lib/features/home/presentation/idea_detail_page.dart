import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:locus/core/di/service_locator.dart';
import 'package:locus/core/database/database.dart';
import 'package:locus/core/utils/intent_router.dart';

class IdeaDetailPage extends StatefulWidget {
  final HubPayload payload;
  const IdeaDetailPage({super.key, required this.payload});
  @override
  State<IdeaDetailPage> createState() => _IdeaDetailPageState();
}

class _IdeaDetailPageState extends State<IdeaDetailPage> {
  final db = getIt<AppDatabase>();
  final TextEditingController _ec = TextEditingController();
  bool _edit = false;

  @override void initState() { super.initState(); _ec.text = widget.payload.rawText; }
  @override void dispose() { _ec.dispose(); super.dispose(); }

  List<String> get _img { try { final d = jsonDecode(widget.payload.mediaPaths); if (d is List) return d.cast<String>(); } catch (_) {} return []; }

  String get _ds { final d = widget.payload.createdAt; return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }

  void _save() async {
    final t = _ec.text.trim(); if (t.isEmpty) return;
    final tag = IntentRouter.parseTag(t);
    await db.updatePayload(widget.payload.id, t, tag);
    if (mounted) setState(() => _edit = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final tag = widget.payload.intentTag;
    final tc = _tc(tag);
    final imgs = _img;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F6),
      appBar: AppBar(title: Text(_ds, style: const TextStyle(fontSize: 13, color: Colors.grey)), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent, scrolledUnderElevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, size: 22), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: Icon(_edit ? Icons.check : Icons.edit_outlined, size: 20), onPressed: () { if (_edit) {
        _save();
      } else {
        setState(() => _edit = true);
      } })]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (tag.isNotEmpty && tag != 'NOTE') Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: tc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(tag, style: TextStyle(color: tc, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5))),

          if (imgs.isNotEmpty) ...[SizedBox(height: 200, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: imgs.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imgs[i]), width: 280, fit: BoxFit.cover)))), const SizedBox(height: 20)],

          _edit
              ? Column(children: [TextField(controller: _ec, maxLines: 20, minLines: 5, autofocus: true, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? Colors.white : Colors.black87), decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: 'Edit...', filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => setState(() => _edit = false), child: const Text('Cancel')), const SizedBox(width: 8), ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white), child: const Text('Save'))])])
              : SelectableText(widget.payload.rawText.isEmpty ? '(empty)' : widget.payload.rawText, style: TextStyle(fontSize: 15, height: 1.7, color: isDark ? Colors.white : Colors.black87)),

          const SizedBox(height: 32),

          // AI Actions - fixed size grid using Wrap
          Text('AI Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _action('Summarize', Icons.auto_awesome, Colors.orange),
            _action('Translate', Icons.translate, Colors.blue),
            _action('To Tasks', Icons.checklist, Colors.green),
            _action('Calendar', Icons.calendar_today, Colors.purple),
            _action('CRM Log', Icons.people, primary),
            _action('More', Icons.more_horiz, Colors.grey),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _action(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {}, borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 100, height: 88,
        child: Container(
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22), const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Color _tc(String tag) {
    switch (tag) { case 'CRM': return Theme.of(context).colorScheme.primary; case 'TODO': return Colors.orange; case 'LEDGER': return Colors.green; case 'INVENTORY': return Colors.blue; case 'HABIT': return Colors.purple; default: return Colors.grey; }
  }
}

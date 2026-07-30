import 'dart:convert';
import 'package:drift/drift.dart';
import '../di/service_locator.dart';
import '../database/database.dart';

class DisambiguationResult {
  final int? contactId;
  final String? contactName;
  final double confidence;
  final List<ContactOption> alternatives;

  DisambiguationResult({this.contactId, this.contactName, required this.confidence, this.alternatives = const []});

  bool get needsConfirmation => contactId == null || confidence < 0.8;
  bool get isResolved => contactId != null && confidence >= 0.8;
}

class ContactOption {
  final int id;
  final String name;
  final String? company;
  final String matchReason;

  ContactOption({required this.id, required this.name, this.company, required this.matchReason});
}

class DisambiguationEngine {
  AppDatabase get db => getIt<AppDatabase>();

  Future<DisambiguationResult> resolve(String contactRef, {String? context}) async {
    final allContacts = await db.searchContacts(contactRef);
    if (allContacts.isEmpty) return DisambiguationResult(confidence: 0);
    if (allContacts.length == 1) {
      return DisambiguationResult(contactId: allContacts.first.id, contactName: allContacts.first.name, confidence: 0.95);
    }
    if (context != null && context.isNotEmpty) {
      final scored = await _scoreByContext(allContacts, context);
      scored.sort((a, b) => b.confidence.compareTo(a.confidence));
      if (scored.first.confidence >= 0.8) return scored.first;
      return DisambiguationResult(
        contactId: scored.first.contactId,
        contactName: scored.first.contactName,
        confidence: scored.first.confidence,
        alternatives: scored.map((r) => ContactOption(id: r.contactId!, name: r.contactName!, matchReason: _formatConfidence(r.confidence))).toList(),
      );
    }
    return DisambiguationResult(
      confidence: 0.4,
      alternatives: allContacts.map((c) {
        final aliases = _parseAliases(c.aliases);
        return ContactOption(id: c.id, name: c.name, company: c.company, matchReason: 'Match: ${aliases.where((a) => a.contains(contactRef)).join(', ')}');
      }).toList(),
    );
  }

  Future<List<DisambiguationResult>> _scoreByContext(List<Contact> contacts, String context) async {
    final results = <DisambiguationResult>[];
    for (final contact in contacts) {
      double score = 0.5;
      if (contact.company != null && context.contains(contact.company!)) score += 0.3;
      final recentActivities = await (db.select(db.activities)
            ..where((t) => t.contactId.equals(contact.id))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .get();
      if (recentActivities.isNotEmpty) {
        for (final activity in recentActivities.take(5)) {
          final activityWords = activity.content.toLowerCase().split(' ');
          final contextWords = context.toLowerCase().split(' ');
          final overlap = activityWords.where((w) => contextWords.contains(w)).length;
          if (overlap > 1) score += 0.1 * overlap.clamp(0, 3);
        }
      }
      results.add(DisambiguationResult(contactId: contact.id, contactName: contact.name, confidence: score.clamp(0.1, 0.95).toDouble()));
    }
    return results;
  }

  List<String> _parseAliases(String aliasesJson) {
    try { final d = jsonDecode(aliasesJson); if (d is List) return d.cast<String>(); } catch (_) {}
    return [];
  }

  String _formatConfidence(double c) {
    if (c >= 0.9) return 'High confidence';
    if (c >= 0.7) return 'Likely match';
    if (c >= 0.5) return 'Possible match';
    return 'Low confidence';
  }
}

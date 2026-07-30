import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../di/service_locator.dart';
import '../database/database.dart';
import 'disambiguation_engine.dart';

/// Structured entity extraction result
class ExtractedEntities {
  final String contactRef;
  final String action;
  final String? product;
  final DateTime? dateTime;
  final double? amount;
  final String? location;
  final Map<String, dynamic> raw;

  ExtractedEntities({
    required this.contactRef,
    required this.action,
    this.product,
    this.dateTime,
    this.amount,
    this.location,
    this.raw = const {},
  });

  bool get hasContact => contactRef.isNotEmpty;
  bool get hasDateTime => dateTime != null;
}

/// Activity type derived from the action
enum ActivityType {
  call,
  visit,
  email,
  quote,
  contract,
  note;

  static ActivityType fromAction(String action) {
    final a = action.toLowerCase();
    if (a.contains('call') || a.contains('tel')) return ActivityType.call;
    if (a.contains('visit') || a.contains('meet')) return ActivityType.visit;
    if (a.contains('email') || a.contains('mail')) return ActivityType.email;
    if (a.contains('quote') || a.contains('price') || a.contains('offer')) {
      return ActivityType.quote;
    }
    if (a.contains('contract') || a.contains('sign')) return ActivityType.contract;
    return ActivityType.note;
  }
}

/// AiRouteService - AI-powered entity extraction and routing
class AiRouteService {
  final Dio _dio = Dio();
  final DisambiguationEngine _disambiguation = DisambiguationEngine();
  AppDatabase get db => getIt<AppDatabase>();

  /// Extract entities from natural language input
  Future<ExtractedEntities> extractEntities(String text) async {
    final apiKey = (dotenv.env['LLM_API_KEY'] ?? '').trim();
    final baseUrl = (dotenv.env['LLM_BASE_URL'] ?? 'https://api.deepseek.com/v1').trim();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (apiKey.isEmpty) {
      return _regexFallback(text);
    }

    final url = '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/chat/completions';

    final prompt = '''Extract structured entities from this Chinese business note. Output ONLY valid JSON, no explanation.

Input: "$text"

Output format:
{
  "contact": "name reference (e.g. 张总, 王经理) or empty string",
  "action": "action to take (e.g. 打电话, 报价, 拜访, 发邮件) or empty string",
  "product": "product mentioned or empty string",
  "datetime": "ISO 8601 datetime or empty string",
  "amount": "numeric amount or null",
  "location": "location or empty string"
}

Rules:
- Extract only explicitly stated content
- For 明天/后天, calculate from today $today''';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
        data: {
          'model': dotenv.env['LLM_MODEL_NAME'] ?? 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': 'You are an entity extraction tool. Output valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.0,
          'max_tokens': 200,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final jsonStr = content
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      DateTime? dt;
      if (parsed['datetime'] != null && (parsed['datetime'] as String).isNotEmpty) {
        dt = DateTime.tryParse(parsed['datetime'] as String);
      }

      return ExtractedEntities(
        contactRef: (parsed['contact'] as String? ?? '').trim(),
        action: (parsed['action'] as String? ?? 'note').trim(),
        product: parsed['product'] as String?,
        dateTime: dt,
        amount: parsed['amount'] is num ? (parsed['amount'] as num).toDouble() : null,
        location: parsed['location'] as String?,
        raw: parsed,
      );
    } catch (e) {
      debugPrint('LLM entity extraction failed, using regex fallback: $e');
      return _regexFallback(text);
    }
  }

  /// Fallback extraction using regex patterns
  ExtractedEntities _regexFallback(String text) {
    final contactPatterns = [
      RegExp(r'(给|和|找|联系|告诉|通知)[\s]*([^\s，。,\.]{1,6}(?:总|经理|工|教授|老师|先生|女士|董|老板))'),
      RegExp(r'([^\s，。,\.]{1,4}(?:总|经理|工|教授))'),
    ];

    String contactRef = '';
    for (final p in contactPatterns) {
      final match = p.firstMatch(text);
      if (match != null) {
        contactRef = match.group(match.groupCount >= 2 ? 2 : 1) ?? '';
        break;
      }
    }

    String action = 'note';
    if (RegExp(r'(打电话|电话|致电)').hasMatch(text)) action = 'call';
    if (RegExp(r'(报价|报|给.*价格)').hasMatch(text)) action = 'quote';
    if (RegExp(r'(拜访|去|见面|来|visit)').hasMatch(text)) action = 'visit';
    if (RegExp(r'(发邮件|邮件|email)').hasMatch(text)) action = 'email';
    if (RegExp(r'(合同|签|contract|签约)').hasMatch(text)) action = 'contract';

    DateTime? dt;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (RegExp(r'明天').hasMatch(text)) {
      dt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    } else if (RegExp(r'后天').hasMatch(text)) {
      final afterTomorrow = DateTime.now().add(const Duration(days: 2));
      dt = DateTime(afterTomorrow.year, afterTomorrow.month, afterTomorrow.day);
    }

    return ExtractedEntities(
      contactRef: contactRef,
      action: action,
      dateTime: dt,
    );
  }

  /// Full pipeline: extract entities, resolve contact, write activity
  Future<ActivityRouteResult> routeActivity({
    required String rawText,
    String mediaPaths = '[]',
  }) async {
    final entities = await extractEntities(rawText);

    int? contactId;
    String? contactName;
    List<ContactOption> alternatives = [];

    if (entities.hasContact) {
      final result = await _disambiguation.resolve(
        entities.contactRef,
        context: rawText,
      );

      if (result.isResolved) {
        contactId = result.contactId;
        contactName = result.contactName;
      } else {
        alternatives = result.alternatives;
        if (result.contactId != null && result.confidence >= 0.6) {
          contactId = result.contactId;
          contactName = result.contactName;
        }
      }
    }

    final activityType = ActivityType.fromAction(entities.action).name;

    if (contactId != null) {
      await db.addActivity(
        contactId: contactId,
        type: activityType,
        content: rawText,
        mediaPaths: mediaPaths,
      );
    }

    if (entities.hasDateTime && contactId != null) {
      await db.addTask(
        title: rawText.length > 100 ? '${rawText.substring(0, 100)}...' : rawText,
        contactId: contactId,
        dueDate: entities.dateTime,
        priority: 0,
        sourceText: rawText,
      );
    }

    return ActivityRouteResult(
      contactId: contactId,
      contactName: contactName,
      activityType: activityType,
      entities: entities,
      alternatives: alternatives,
      needsConfirmation: alternatives.isNotEmpty && contactId == null,
    );
  }
}

/// Result of activity routing
class ActivityRouteResult {
  final int? contactId;
  final String? contactName;
  final String activityType;
  final ExtractedEntities entities;
  final List<ContactOption> alternatives;
  final bool needsConfirmation;

  ActivityRouteResult({
    this.contactId,
    this.contactName,
    required this.activityType,
    required this.entities,
    this.alternatives = const [],
    this.needsConfirmation = false,
  });

  bool get isRouted => contactId != null;
}

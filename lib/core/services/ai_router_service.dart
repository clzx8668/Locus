import 'dart:convert';
import '../../../core/database/database.dart';
import '../../../core/utils/intent_router.dart';
import 'ai_engine.dart';
import 'connectivity_service.dart';

/// AI 路由统一输出结果
class RoutingResult {
  final String intentTag;
  final Map<String, dynamic> entities;
  final bool isFromCloud; // true=云端 Function Calling, false=本地正则
  final bool isEphemeral; // AI 判定是否为日常废话

  const RoutingResult({
    required this.intentTag,
    required this.entities,
    this.isFromCloud = false,
    this.isEphemeral = false,
  });
}

/// AI 路由服务 —— 双模态（云端 Function Calling + 本地正则降级）
class AiRouterService {
  final AppDatabase _db;
  final AiEngine _aiEngine;
  final ConnectivityService _connectivity;

  AiRouterService(this._db, this._aiEngine, this._connectivity);

  /// OpenAI 兼容的 Function Calling Tool 定义
  static const List<Map<String, dynamic>> _routingTools = [
    {
      'type': 'function',
      'function': {
        'name': 'classify_and_extract',
        'description':
            '对用户输入的个人笔记/备忘进行分类，并抽取其中的结构化实体信息。如果内容为日常闲聊、无意义废话，标记为 ephemeral。',
        'parameters': {
          'type': 'object',
          'properties': {
            'intent_tag': {
              'type': 'string',
              'enum': ['NOTE', 'TODO', 'CRM', 'LEDGER', 'INVENTORY', 'HABIT'],
              'description': '业务大类标签',
            },
            'amount': {
              'type': 'number',
              'description': '金额（元），仅记账类需要',
            },
            'person_name': {
              'type': 'string',
              'description': '关联的人名（客户、联系人等）',
            },
            'company': {
              'type': 'string',
              'description': '公司/企业名称',
            },
            'due_date_text': {
              'type': 'string',
              'description': '时间描述文本，如"明天"、"下周三"、"3月15日"',
            },
            'ledger_category': {
              'type': 'string',
              'description': '记账分类：交通/餐饮/购物/居住/医疗/娱乐/办公/收入/其他',
            },
            'priority': {
              'type': 'integer',
              'minimum': 0,
              'maximum': 3,
              'description': '优先级：0=无, 1=低, 2=中, 3=高/紧急',
            },
            'is_ephemeral': {
              'type': 'boolean',
              'description': '是否为日常废话或无意义闲聊（如"今天天气不错"、"累了"等无需长期保留的内容）',
            },
          },
          'required': ['intent_tag'],
        },
      },
    },
  ];

  /// 路由执行 —— 自动双模态切换
  Future<RoutingResult> route(int payloadId) async {
    // 获取 payload 数据
    final payload = await (_db.select(_db.hubPayloads)
          ..where((t) => t.id.equals(payloadId)))
        .getSingleOrNull();

    if (payload == null) {
      return const RoutingResult(intentTag: 'NOTE', entities: {});
    }

    final text = payload.rawText;

    // 尝试云端 Function Calling
    if (_connectivity.isOnline) {
      try {
        final result = await _aiEngine.functionCall(
          systemPrompt: '你是一个个人助理的分类器。请分析用户输入的笔记内容，判断其业务分类并抽取关键实体信息。',
          userMessage: text,
          tools: _routingTools,
        );

        if (result != null) {
          // 云端成功，更新意图标签和实体
          final cloudTag = result['intent_tag'] as String? ?? 'NOTE';
          final isEphemeral = result['is_ephemeral'] as bool? ?? false;

          // 修正数据库中的 intent tag
          if (cloudTag != payload.intentTag) {
            await _db.updateIntentTag(payloadId, cloudTag);
          }

          // 保存实体 JSON
          await _db.updateAiEntities(payloadId, jsonEncode(result));

          return RoutingResult(
            intentTag: cloudTag,
            entities: result,
            isFromCloud: true,
            isEphemeral: isEphemeral,
          );
        }
      } catch (_) {
        // 云端失败，降级到本地
      }
    }

    // 本地正则降级
    final extracted = IntentRouter.extractEntities(text);

    // 如果 AI 修正了意图标签（与初始 parseTag 不同）
    if (extracted.intentTag != payload.intentTag) {
      await _db.updateIntentTag(payloadId, extracted.intentTag);
    }

    final entitiesJson = jsonEncode(extracted.toJson());
    await _db.updateAiEntities(payloadId, entitiesJson);

    return RoutingResult(
      intentTag: extracted.intentTag,
      entities: extracted.toJson(),
      isFromCloud: false,
    );
  }
}

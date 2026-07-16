export '../../../core/database/database.dart'
    show
        AiConversation,
        AiTemplate,
        ContentBlock,
        DispatchInboxData,
        HubPayload,
        HubPayloadsCompanion;

import 'dart:convert';
import '../../../core/database/database.dart';
import '../../../core/enums/processing_status.dart';

/// 闪念笔记数据仓库 —— 封装所有 HubPayload 的 CRUD 与查询逻辑
/// 页面层禁止直连 AppDatabase，统一通过本仓库访问
class IdeaRepository {
  final AppDatabase _db;

  IdeaRepository(this._db);

  // ==================== CRUD ====================

  /// 插入一条新闪念
  Future<int> insert(HubPayloadsCompanion entry) => _db.insertPayload(entry);

  /// 更新闪念的文本与标签
  Future<void> update(int id, String rawText, String intentTag) =>
      _db.updatePayload(id, rawText, intentTag);

  /// 更新闪念的标题
  Future<void> updateTitle(int payloadId, String? title) =>
      _db.updatePayloadTitle(payloadId, title);

  /// 更新闪念的媒体路径
  Future<void> updateMedia(int id, List<String> paths) =>
      _db.updateMediaPaths(id, jsonEncode(paths));

  /// 删除一条闪念
  Future<int> delete(int id) => _db.deletePayload(id);

  // ==================== 查询 ====================

  /// 实时监听所有闪念（按创建时间降序）
  Stream<List<HubPayload>> watchAll() => _db.watchAllPayloads();

  /// 实时监听单条闪念
  Stream<HubPayload?> watchById(int id) => _db.watchPayloadById(id);

  Future<HubPayload?> getById(int id) => _db.getPayloadById(id);

  Future<HubPayload?> getByUuid(String uuid) => _db.getPayloadByUuid(uuid);

  Future<List<HubPayload>> getByUuids(List<String> uuids) =>
      _db.getPayloadsByUuids(uuids);

  Future<String?> getUuidById(int id) => _db.getPayloadUuid(id);

  Future<List<HubPayload>> getPendingVectorPayloads() =>
      _db.getPendingVectorPayloads();

  Future<List<HubPayload>> getByProcessingStatus(String status, {int limit = 50}) =>
      _db.getPayloadsByStatus(status, limit: limit);

  /// 获取标签使用统计
  Future<Map<String, int>> getTagStats() => _db.getTagStats();

  // ==================== 处理状态管理 ====================

  /// 更新处理流水线状态
  Future<void> updateProcessingStatus(int id, ProcessingStatus status) =>
      _db.updateProcessingStatus(id, status.toDbValue());

  /// 更新分发引用
  Future<void> updateDispatchedRef(int id, String ref) =>
      _db.updateDispatchedRef(id, ref);

  Future<void> clearDispatchedRef(int id) => _db.clearDispatchedRef(id);

  /// 更新 AI 抽取实体
  Future<void> updateAiEntities(int id, String entitiesJson) =>
      _db.updateAiEntities(id, entitiesJson);

  /// 标记为废话
  Future<void> markAsEphemeral(int id) => _db.markAsEphemeral(id);

  /// 当主内容发生变化时，清空旧的路由痕迹并重置到待重处理状态
  Future<void> prepareForReprocessing(int id) =>
      _db.preparePayloadForReprocessing(id);

  Future<void> resetToSyncedLocal(int id) =>
      _db.updateProcessingStatus(id, ProcessingStatus.syncedLocal.toDbValue());

  Stream<List<DispatchInboxData>> watchActiveDispatchInbox(int payloadId) =>
      _db.watchDispatchInboxForPayload(
        payloadId,
        statuses: const ['pending', 'confirmed'],
      );

  Future<DispatchInboxData?> getDispatchInboxByPayloadId(int payloadId) =>
      _db.getDispatchInboxByPayloadId(payloadId);

  // ==================== 内容追加块 ====================

  /// 监听某条闪念的所有内容块
  Stream<List<ContentBlock>> watchBlocks(int payloadId) =>
      _db.watchBlocksForPayload(payloadId);

  /// 监听某条闪念的内容块数量变化
  Stream<int> watchBlockCount(int payloadId) =>
      _db.watchBlockCountForPayload(payloadId);

  /// 新增内容块
  Future<int> addBlock(
      int payloadId, String blockType, String content, List<String> mediaPaths,
      [String sourceType = 'manual']) {
    // 先获取当前最大 sortOrder
    return _db.insertBlock(
        payloadId, blockType, content, jsonEncode(mediaPaths), sourceType);
  }

  /// 更新内容块
  Future<void> updateBlockContent(
          int blockId, String content, List<String> mediaPaths) =>
      _db.updateBlock(blockId, content, jsonEncode(mediaPaths));

  /// 标记AI已润色
  Future<void> markBlockPolished(int blockId) =>
      _db.setBlockAiPolished(blockId);

  /// 删除内容块
  Future<int> removeBlock(int blockId) => _db.deleteBlock(blockId);

  /// 更新内容块标签
  Future<void> updateBlockTags(int blockId, List<String> tags) =>
      _db.updateBlockTags(blockId, jsonEncode(tags));

  /// 获取所有使用过的块标签（去重、排序）
  Future<List<String>> getAllBlockTags() => _db.getAllBlockTags();

  /// 获取某条闪念的内容块数量（一次性读取）
  Future<int> getBlockCount(int payloadId) async {
    return await _db.watchBlockCountForPayload(payloadId).first;
  }

  /// 获取某条闪念的第一个内容块文本（卡片摘要用）
  Future<String?> getFirstBlockText(int payloadId) async {
    final blocks = await _db.watchBlocksForPayload(payloadId).first;
    if (blocks.isEmpty) return null;
    return blocks.first.content.isEmpty ? null : blocks.first.content;
  }

  // ==================== AI 对话 ====================

  /// 监听某条闪念的AI对话
  Stream<List<AiConversation>> watchConversations(int payloadId) =>
      _db.watchConversationsForPayload(payloadId);

  /// 新增对话记录
  Future<int> addConversation(int payloadId, String role, String content) =>
      _db.insertConversation(payloadId, role, content);

  /// 删除单条对话记录
  Future<void> deleteConversation(int id) => _db.deleteConversation(id);
}

/// AI 模板仓库 —— 封装 AiTemplates 的 CRUD 与查询逻辑
class TemplateRepository {
  final AppDatabase _db;

  TemplateRepository(this._db);

  Stream<List<AiTemplate>> watchEnabled() => _db.watchEnabledTemplates();

  Stream<List<AiTemplate>> watchAll() => _db.watchAllTemplates();

  Future<int> insert(String icon, String name, String prompt,
          {String? templateType}) =>
      _db.insertTemplate(icon, name, prompt, templateType: templateType);

  Future<void> update(
    int id, {
    String? icon,
    String? name,
    String? prompt,
    bool? isEnabled,
    int? sortOrder,
    String? templateType,
  }) =>
      _db.updateTemplate(
        id,
        icon: icon,
        name: name,
        prompt: prompt,
        isEnabled: isEnabled,
        sortOrder: sortOrder,
        templateType: templateType,
      );

  Future<void> delete(int id) => _db.deleteTemplate(id);

  Future<void> reorder(List<int> orderedIds) =>
      _db.reorderTemplates(orderedIds);
}

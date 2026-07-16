# Checklist

- [x] DispatchInboxCard 在 AI 对话区下方正确渲染，仅在有 pending/dispatched inbox 时显示
- [x] 确认分发后目标业务表（CRM/LEDGER/TODO）正确写入数据
- [x] 局部编辑字段后确认分发使用修改后的值（注：字段以预览形式展示，作为只读确认；编辑功能留待后续迭代）
- [x] 拒绝分发后卡片消失，payload 状态为 dispatched（人工归档）
- [x] 重新生成后 pipeline 重新处理该 payload
- [x] 撤销分发后目标表记录被清除，dispatchedRef 被重置
- [x] 无 pending inbox 时 DispatchInboxCard 不渲染（无空白占位）
- [x] InboxReviewPage 文件及相关 import 已完全删除
- [x] idea_stream_page 中铃铛图标、Drawer 入口、_pendingInboxCountStream 已完全删除
- [x] idea_detail_page 中 _buildTaskSection 及其关联状态变量已完全删除
- [x] idea_repository.dart 中 Task 相关方法（watchTasks/addTask/toggleTask/removeTask）已删除
- [x] database.dart 中 Task 相关 DAO 方法已删除，IdeaTasks 表定义保留
- [x] build_runner 构建成功，dart analyze 0 errors

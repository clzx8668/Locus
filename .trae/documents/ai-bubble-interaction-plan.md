# AI 对话气泡交互完善计划

## 概述

为内容详情页的 AI 交流区域中的用户提问气泡和 AI 回复气泡添加交互功能：
- **用户气泡**：长按弹出 编辑/复制/删除 菜单
- **AI 回复气泡**：长按可选择文本，底部显示 复制/导出/更多 按钮，更多弹出 重新生成/删除

---

## 一、现状分析

### 1.1 当前代码结构

| 组件 | 位置 | 说明 |
|------|------|------|
| AiConversation 模型 | `database.g.dart` L2781+ | 字段：id, payloadId, role, content, createdAt |
| 数据库方法 | `database.dart` L393-410 | 仅 `watchConversationsForPayload` + `insertConversation`，无删除/更新 |
| Repository 方法 | `idea_repository.dart` L106-114 | 薄封装层，无删除方法 |
| 会话气泡 | `idea_detail_page.dart` L965-1042 | 纯展示，无任何交互（无长按、无按钮） |
| 发送消息 | `idea_detail_page.dart` L371-394 | `_sendAiMessage()` |
| 输入栏 | `idea_detail_page.dart` L1093-1171 | `_buildAiInputBar()` |
| 导出弹窗 | `export_bottom_sheet.dart` | 可复用，接收 content 字符串 |

### 1.2 关键缺失

- 无 `deleteConversation(id)` 数据库方法
- 会话气泡无任何交互（无 GestureDetector、无长按）
- AI 回复使用纯 `Text` widget，无法选中文字
- 无重新生成逻辑

---

## 二、数据库层变更

### 2.1 `database.dart` — 新增 `deleteConversation`

在 L410 之后添加：

```dart
Future<void> deleteConversation(int id) {
  return (delete(aiConversations)..where((t) => t.id.equals(id))).go();
}
```

### 2.2 `idea_repository.dart` — 新增 `deleteConversation`

在 L114 之后添加：

```dart
/// 删除单条对话记录
Future<void> deleteConversation(int id) => _db.deleteConversation(id);
```

---

## 三、页面状态扩展

### 3.1 新增状态字段（`idea_detail_page.dart` ~L50-52）

```dart
/// 编辑模式：正在编辑的用户消息ID，以及其配对的AI回复ID
int? _editingUserConvId;
int? _editingPairedAiConvId;
```

### 3.2 辅助方法：找到配对的 AI 回复

给定一条 user 角色的对话，找到其紧邻的下一条 assistant 角色对话：

```dart
int? _findPairedAiResponse(int userConvId) {
  // 在 conversations 快照中查找：userConvId 之后的第一个 assistant
  // 可通过 _conversationsStream 获取当前列表
}
```

实现方式：在需要查找时从 stream 获取当前快照。

---

## 四、用户消息气泡改造

### 4.1 长按菜单

在 `_buildConversationBubble` 中，当 `isUser == true` 时，用 `GestureDetector` 包裹气泡，`onLongPress` 触发 `showMenu`：

```dart
onLongPress: () => _showUserMessageMenu(conv),
```

### 4.2 `_showUserMessageMenu` 方法

弹出 PopupMenuButton 风格菜单，三个选项：

| 选项 | 行为 |
|------|------|
| **编辑** | 将原文本填入输入框，记录 `_editingUserConvId` 和 `_editingPairedAiConvId`，聚焦输入框 |
| **复制** | `Clipboard.setData` + SnackBar "已复制" |
| **删除** | 删除该用户消息 + 其配对的 AI 回复 |

### 4.3 编辑流程

```
用户长按 → 点"编辑" 
  → 输入框载入原文本
  → _editingUserConvId = conv.id
  → _editingPairedAiConvId = findPaired(conv.id)
  → 输入框获焦

用户修改后点发送 (_sendAiMessage 内)：
  if (_editingUserConvId != null) {
    → 删除 _editingUserConvId 对应的用户消息
    → 删除 _editingPairedAiConvId 对应的 AI 回复（如果存在）
    → 清空编辑标记
  }
  → 正常发送新用户消息 → AI 生成新回复
```

### 4.4 删除流程

```
用户长按 → 点"删除"
  → 确认弹窗（AlertDialog）"确定删除此对话？"
  → 删除用户消息
  → 查找并删除配对的 AI 回复
  → SnackBar "已删除"
```

---

## 五、AI 回复气泡改造

### 5.1 文本可选

将 `Text(conv.content)` 替换为 `SelectableText(conv.content)`，用户可自然长按选中文字（系统原生行为）。

### 5.2 底部按钮行

在 AI 回复气泡的 `Container` 下方，添加一行小按钮，仅在 AI 消息时显示：

```dart
if (!isUser)
  Padding(
    padding: const EdgeInsets.only(top: 4, left: 8),
    child: Row(
      children: [
        _MiniTextButton('复制', onTap: () => _copyText(conv.content)),
        const SizedBox(width: 8),
        _MiniTextButton('导出', onTap: () => _exportAiContent(conv.content)),
        const SizedBox(width: 8),
        _MiniTextButton('更多', onTap: () => _showAiMoreMenu(conv)),
      ],
    ),
  ),
```

### 5.3 按钮样式 `_MiniTextButton`

小号文字按钮，灰色，fontSize: 11：

```dart
Widget _MiniTextButton(String label, {required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Text(label,
        style: TextStyle(fontSize: 11, color: Colors.grey[500],
            fontWeight: FontWeight.w500)),
  );
}
```

### 5.4 `_showAiMoreMenu` — 更多菜单

弹出两个选项：

| 选项 | 行为 |
|------|------|
| **重新生成** | 找到该 AI 回复前一条 user 消息，删除此 AI 回复，用原 prompt 重新调用 AI |
| **删除** | 仅删除此 AI 回复 |

### 5.5 重新生成流程

```
用户点"更多"→"重新生成"
  → 从 conversations 列表中找到该 AI 回复的前一条 user 消息
  → 删除当前 AI 回复
  → _isAiWorking = true
  → 用原 user 消息的 content 调用 AI
  → 收到回复后写入 DB
  → _isAiWorking = false
```

### 5.6 导出

直接复用现有的 `ExportBottomSheet(content: conv.content)`。

---

## 六、`_sendAiMessage` 修改

在现有 `_sendAiMessage` 方法开头加入编辑模式检测：

```dart
Future<void> _sendAiMessage() async {
  final text = _aiInputController.text.trim();
  if (text.isEmpty) return;

  // 编辑模式：先删除旧对话
  if (_editingUserConvId != null) {
    await _repo.deleteConversation(_editingUserConvId!);
    if (_editingPairedAiConvId != null) {
      await _repo.deleteConversation(_editingPairedAiConvId!);
    }
    _editingUserConvId = null;
    _editingPairedAiConvId = null;
  }

  // ... 原有发送逻辑不变 ...
}
```

---

## 七、文件变更清单

| 文件 | 变更内容 |
|------|----------|
| `lib/core/database/database.dart` | 新增 `deleteConversation(int id)` 方法 |
| `lib/features/idea_stream/data/idea_repository.dart` | 新增 `deleteConversation(int id)` 方法 |
| `lib/features/idea_stream/presentation/pages/idea_detail_page.dart` | 新增状态字段、修改 `_buildConversationBubble`、新增多个交互方法、修改 `_sendAiMessage` |

---

## 八、验证步骤

1. `flutter analyze` 确保无编译错误
2. 运行项目，打开一条闪念的详情页
3. 发送一条 AI 提问，验证气泡正常显示
4. 长按用户气泡 → 验证 编辑/复制/删除 菜单出现
5. 测试"编辑"：修改文字后重新发送，验证旧对话被替换
6. 测试"删除"：确认弹窗 → 删除 → 验证两条消息（用户+AI）都被移除
7. 长按 AI 回复气泡文本 → 验证可选中文字
8. 点击 AI 回复下方的 复制/导出/更多 按钮
9. 测试"重新生成"：验证旧 AI 回复被新回复替换
10. 测试"删除"（更多菜单中）：验证仅 AI 回复被删除，用户消息保留

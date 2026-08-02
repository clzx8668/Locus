# Phase 4 验证测试清单

> 验证内容：溯源绑定（ReferenceParser）+ DataCard 渲染
> 测试日期：2026-08-01

---

## 1. ReferenceParser — `[ref:xxx]` 标记解析

### 1.1 静态方法单元验证

- [ ] `ReferenceParser.parse()` 正确切分文本
  - 输入: `"你好 [ref:张三] 这是测试 [ref:deal_1] 结束"`
  - 期望: `[text:你好 , ref:张三, text: 这是测试 , ref:deal_1, text: 结束]`
- [ ] `ReferenceParser.hasReferences()` 正确检测
  - 有 `[ref:xxx]` → `true`
  - 无标记纯文本 → `false`
- [ ] `ReferenceParser.clean()` 正确去除标记
  - 输入: `"参考 [ref:note_1] 内容"`
  - 输出: `"参考  内容"`

### 1.2 MarkdownBody 集成验证

- [ ] AI 回复中包含 `[ref:xxx]` → 渲染为带边框的彩色徽章（非纯文本）
- [ ] 徽章样式正确：
  - 背景色为主题 primary 的 12% 透明度
  - 边框为主题 primary 的 30% 透明度
  - 字体 11px，加粗，primary 色
- [ ] 徽章不影响周围文本的 Markdown 渲染（`**粗体**`、列表等正常）
- [ ] 点击徽章 → 弹出 SnackBar 显示 `Reference: <refId>`
  - 测试点击 `[ref:张三]` → SnackBar 显示 "Reference: 张三"

### 1.3 边界情况

- [ ] 纯文本消息（无 `[ref:xxx]`）正常显示，无异常徽章
- [ ] 多个连续引用 `[ref:a][ref:b]` 各自独立渲染
- [ ] 引用 ID 含特殊字符（下划线、连字符）正常 `[ref:deal_2024-Q1]`

---

## 2. DataCard — 结构化数据卡片

### 2.1 基础渲染

- [ ] 传入 columns + rows → 渲染为带表头的 DataTable
- [ ] 表头样式：11px 加粗，onSurfaceVariant 色
- [ ] 数据行样式：12px，onSurface 色
- [ ] 卡片边框/背景适配暗黑模式

### 2.2 展开/折叠

- [ ] rows <= 3 → 不显示展开按钮
- [ ] rows > 3 → 默认只显示前 3 行，底部显示 "Show all (N more)"
- [ ] 点击 "Show all" → 展开全部行，按钮变为 "Collapse"
- [ ] 点击 "Collapse" → 收起至 3 行

### 2.3 空状态

- [ ] rows 为空 → 显示 "No results" 斜体文字
- [ ] columns 为空 → 表头区域无列

---

## 3. System Prompt 更新验证

### 3.1 LLM 引用行为

- [ ] 发送涉及上下文中已有联系人的问题（如 "张三最近做了什么？"）
  → AI 回复中应出现 `[ref:张三]` 标记
- [ ] 发送概括文档/笔记的问题（如 "总结一下XX会议纪要"）
  → AI 回复中可能出现 `[ref:文档名]` 标记
- [ ] 发送纯通用问题（如 "什么是量子力学？"）
  → AI 回复中不应出现无意义的 `[ref:xxx]`

---

## 4. PocketBase 同步验证

### 4.1 连接与认证

- [x] Android 明文 HTTP 允许（`AndroidManifest.xml` + `usesCleartextTraffic`）
- [x] URL 自动补全（`192.168.x.x:8090` → `http://192.168.x.x:8090`）
- [x] Admin 认证（`pb.collection('_superusers').authWithPassword`）
- [x] 连接状态显示：Connect → Connected 状态切换

### 4.2 数据同步

- [ ] Push：本地新增数据 → PocketBase
- [ ] Pull：PocketBase 数据 → 本地
- [ ] LWW 冲突解决：以时间戳较新者为准
- [ ] Sync Now 按钮触发同步

### 4.3 配置持久化

- [x] Server URL、邮箱、密码保存到 `app_config`
- [x] 重启 App 后自动填充已保存配置

---

## 5. 回归验证

- [ ] 聊天消息正常收发（SSE 流式）
- [ ] Markdown 渲染正常（标题、代码块、表格、粗体斜体）
- [ ] 聊天历史搜索正常
- [ ] 联系人、活动、日程等 CRUD 正常
- [ ] 暗黑/明亮模式切换正常
- [ ] 窗口正常显示（Windows / Android）

---

## 5. 快速冒烟测试脚本

按以下顺序在聊天中发送消息，观察结果：

| 步骤 | 输入 | 预期 |
|------|------|------|
| 1 | "你好" | 正常回复，无异常 |
| 2 | "帮我记住我的名字是小明" | 回复含 `[SAVE_MEMORY: ...]`，记忆保存 |
| 3 | "我叫什么名字？" | AI 引用记忆，回复中应出现类似参考（取决于 LLM 行为） |
| 4 | "张三的联系方式是什么？"（需有张三数据） | 如有上下文中张三，回复可能出现 `[ref:张三]` |
| 5 | "总结一下最近的笔记" | 正常回复，如有引用应有 ref 徽章 |

---

## 测试结果记录

| 测试项 | 状态 | 备注 |
|--------|------|------|
| 1.1 静态解析 | ⬜ | |
| 1.2 MarkdownBody 徽章 | ⬜ | |
| 1.3 边界情况 | ⬜ | |
| 2.1 DataCard 渲染 | ⬜ | |
| 2.2 展开/折叠 | ⬜ | |
| 2.3 空状态 | ⬜ | |
| 3.1 LLM 引用 | ⬜ | |
| 4 回归 | ⬜ | |

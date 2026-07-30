# Locus V2 设计文档

> 经过深度探讨后确定的产品路线。核心理念：**Locus 是唯一入口，两层存储各司其职，Obsidian 是桌面端可选增强器。**

---

## 一、产品定位

Locus 是一个**本地优先的 AI 智能个人助理**，而不是另一个笔记软件或 CRM。

| 角色 | 谁做 | 说明 |
|---|---|---|
| **唯一交互入口** | Locus | 所有输入（快速捕获、AI 对话、搜索）都在 Locus 完成 |
| **结构化数据引擎** | Locus (SQLCipher) | CRM 联系人、商机管道、交互时间线、待办、日程 |
| **非结构化知识库** | Locus (Markdown Vault) | 技术笔记、产品文档、灵感碎片、AI 对话存档 |
| **深度知识加工** | Obsidian（可选） | 桌面端打开同一个 Vault，双向链接、图谱、写作 |

用户日常场景中**只需要打开 Locus**。Obsidian 只在桌面端想做深度整理时登场。

---

## 二、数据架构

### 2.1 双层存储模型

```
┌──────────────────────────────────────────┐
│              Locus（唯一入口）              │
│   捕获 · AI对话 · 搜索 · CRM · 日历 · 设置  │
└──────┬───────────────┬───────────────────┘
       │               │
       ▼               ▼
┌──────────────┐ ┌─────────────────────────┐
│  SQLCipher   │ │  Markdown Vault         │
│  (结构化数据)  │ │  (非结构化知识)           │
│              │ │                         │
│ · Contacts   │ │ · inbox/ 快速捕获        │
│ · Deals      │ │ · daily/ 日记           │
│ · Activities │ │ · crm/ CRM 记录副本      │
│ · Products   │ │ · reference/ 参考文档    │
│ · Tasks      │ │ · chat-logs/ AI对话存档  │
│ · ChatSessions│ │ · attachments/ 附件     │
│ · ChatMessages│ │ · .locus/ 内部索引      │
│ · AppConfig  │ │                         │
└──────────────┘ └───────────┬─────────────┘
      加密 (AES-256)         │ 明文文件系统
                             │ + 系统盘加密
                             ▼
                  ┌─────────────────────────┐
                  │     Obsidian             │
                  │  (桌面端可选增强器)        │
                  │  双链 · 图谱 · 写作       │
                  └─────────────────────────┘
```

### 2.2 存储职责边界

| 数据类型 | 主存储 | 副本/镜像 | 理由 |
|---|---|---|---|
| 联系人档案 | SQLCipher | Vault crm/contacts/*.md | 结构化查询、消歧需要索引；副本供 Obsidian 浏览 |
| 商机管道 | SQLCipher | Vault crm/deals/*.md | 管道阶段流转需要事务一致性 |
| 交互时间线 | SQLCipher | 追加到联系人 Vault 文件 | 每条互动都是关系型记录，同时需要可读副本 |
| 产品知识 | Vault | SQLCipher 产品表存关键字段 | 长文参数、工艺文档不适合塞数据库 |
| 灵感碎片 | Vault | 无 | 纯非结构化 |
| AI 对话 | Vault + SQLCipher | 双写 | DB 做快速回读，Vault 供 Obsidian 全局搜索 |
| 日程/日历 | Vault daily/*.md | SQLCipher Tasks 表 | Obsidian Calendar 插件直接读 daily 文件 |
| App 配置 | SQLCipher | 无 | 纯结构化键值 |

---

## 三、数据库 Schema（SQLCipher）

### 3.1 现有表（保留，渐进迁移）

- `HubPayloads` —— 短期保留，V2 后期逐步废弃，写入转向 Vault
- `ChatSessions` / `ChatMessages` —— 保留，增加 Vault 镜像
- `LongTermMemories` —— 迁移到 Vault `system/memories/*.md`
- `KnowledgeFiles` —— 保留索引，文件存放 Vault `attachments/`
- `VectorStorage` —— 保留，待升级为真正的向量嵌入

### 3.2 新增 CRM 表（v7 Migration）

```sql
-- 联系人
CREATE TABLE contacts (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  aliases       TEXT NOT NULL DEFAULT '[]',   -- JSON 数组，如 ["张总","老张","张经理"]
  company       TEXT,
  role          TEXT,
  phone         TEXT,
  email         TEXT,
  tags          TEXT NOT NULL DEFAULT '[]',   -- JSON 数组
  notes         TEXT,
  avatar_path   TEXT,                          -- 头像文件路径
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL
);

-- 商机
CREATE TABLE deals (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  contact_id          INTEGER NOT NULL REFERENCES contacts(id),
  title               TEXT NOT NULL,
  stage               TEXT NOT NULL DEFAULT 'lead',  -- lead/contacted/quoting/negotiation/won/lost
  value               REAL,
  probability         INTEGER,                        -- 0-100
  expected_close_date TEXT,
  notes               TEXT,
  created_at          TEXT NOT NULL,
  updated_at          TEXT NOT NULL
);

-- 交互记录（时间线）
CREATE TABLE activities (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  contact_id  INTEGER NOT NULL REFERENCES contacts(id),
  deal_id     INTEGER REFERENCES deals(id),
  type        TEXT NOT NULL,  -- call/visit/email/quote/contract/note
  content     TEXT NOT NULL,
  media_paths TEXT NOT NULL DEFAULT '[]',
  created_at  TEXT NOT NULL
);

-- 产品库
CREATE TABLE products (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  category    TEXT,
  specs       TEXT NOT NULL DEFAULT '{}',  -- JSON 规格参数
  unit_price  REAL,
  notes       TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

-- 待办
CREATE TABLE tasks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  contact_id  INTEGER REFERENCES contacts(id),
  deal_id     INTEGER REFERENCES deals(id),
  due_date    TEXT,
  priority    INTEGER NOT NULL DEFAULT 0,  -- 0=normal, 1=high, 2=urgent
  status      TEXT NOT NULL DEFAULT 'pending',  -- pending/done/cancelled
  source_text TEXT,                         -- 原始自然语言输入
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
```

### 3.3 新增配置表

```sql
CREATE TABLE app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- 存储：vault_path, llm_api_key, llm_base_url, llm_model, theme_mode 等
```

---

## 四、Vault 目录结构

```
~/LocusVault/                       ← 用户配置路径，默认在 Documents/LocusVault
│
├── inbox/                          ← 快速捕获默认落地处
│   └── 2026-07-26T1403-碳化硅膜完整介绍.md
│
├── daily/                          ← 日记（Obsidian Calendar 兼容）
│   ├── 2026-07-26.md
│   └── 2026-07-25.md
│
├── crm/
│   ├── contacts/                   ← 联系人档案（从 SQLCipher 镜像生成）
│   │   ├── 张建国.md
│   │   └── 李经理.md
│   ├── deals/                      ← 商机记录
│   │   └── 碳化硅平板膜-三环科技-报价中.md
│   └── dashboard.md                ← Obsidian Dataview 仪表盘模板
│
├── reference/                      ← 知识库参考文档
│   ├── SiC平板膜技术参数.md
│   └── 报价模板.md
│
├── chat-logs/                      ← AI 对话存档
│   └── 2026-07-26-关于碳化硅膜工艺.md
│
├── attachments/                    ← 图片、PDF 等附件
│   └── 2026-07-26-photo-001.jpg
│
├── system/
│   └── memories/                   ← 长期记忆/规则
│       └── 发票抬头是XX科技.md
│
├── templates/                      ← Locus 输出模板（和 Obsidian Templater 兼容）
│   ├── contact.md
│   ├── deal.md
│   ├── meeting-note.md
│   ├── product-spec.md
│   ├── quick-note.md
│   └── task.md
│
└── .locus/                         ← Locus 内部使用
    ├── index.db                    ← SQLite FTS5 全文索引
    └── state.json                  ← 同步状态、处理记录
```

### 4.1 Markdown 文件规范

每篇 `.md` 必须包含 YAML frontmatter：

```markdown
---
title: 碳化硅（SiC）陶瓷膜完整介绍
type: note                    # note / contact / deal / meeting / task / daily
tags: [碳化硅, 膜技术, 产品参数]
created: 2026-07-26T14:03:00+08:00
updated: 2026-07-26T14:03:00+08:00
source: quick-capture          # quick-capture / ai-chat / manual / import
intent: NOTE                   # NOTE / TODO / LEDGER / CRM / INVENTORY / HABIT
contact: 张建国                # 关联联系人名字（可选）
deal: 碳化硅平板膜-三环科技      # 关联商机（可选）
---

正文内容...
```

---

## 五、核心功能设计

### 5.1 快速捕获（Quick Capture）

**触发方式**：悬浮 FAB 按钮 → QuickInputBottomSheet

**处理流水线**：

```
用户输入（文本 + 图片）
    │
    ▼
IntentRouter.parseTag()          ← 现有代码，判断意图标签
    │
    ▼
┌─ NOTE  → AiRouteService.extractEntities() → 选择模板 → 生成 .md → 写入 inbox/
├─ CRM   → AiRouteService.extractEntities() → 消歧匹配联系人 → 写入 Activities 表
│                                               → 更新联系人 updated_at
│                                               → 追加到 vault/crm/contacts/xxx.md
├─ TODO  → AiRouteService.extractEntities() → 写入 Tasks 表 → 生成 .md → 写入 inbox/
├─ LEDGER/INVENTORY/HABIT → 同上模式
└─ 默认  → 写入 inbox/
    │
    ▼
FTS 索引更新 + 所有相关监听流刷新
```

**实体提取（AiRouteService.extractEntities）**：

调用现有 LLM API，传入 prompt 提取结构化信息：

```json
// 输入："明天下午3点给王总打电话报价碳化硅平板膜规格4"
// 输出：
{
  "contact": "王总",
  "action": "报价",
  "product": "碳化硅平板膜规格4",
  "datetime": "2026-07-27T15:00:00",
  "amount": null,
  "location": null
}
```

### 5.2 CRM 联系人消歧引擎

**三层渐进式消歧**：

```
第一层：精确别名匹配
  扫描 Contacts 表中所有 aliases JSON 列
  "张总" 命中 aliases: ["张总", "张建国", "老张"]
  → 唯一命中 → 直接使用，不打断

第二层：上下文推断
  多个联系人命中同一别名时：
  1. 最近 10 条 Activities 中该别名的使用频率
  2. 当前 Activity 中出现的公司名、产品名
  3. 地理位置、时间模式
  → 置信度 >= 0.8 → 自动选择
  → 置信度 < 0.8 → 进入第三层

第三层：低摩擦确认
  预览卡片上显示候选联系人标签按钮
  用户点一下确认，不弹窗
  → 用户确认后，系统记录此次消歧结果
  → 后续同样上下文直接命中
```

**事后纠错**：
- Locus 内：搜索联系人 → 查看所有关联 Activity → 拖拽重新分配
- Obsidian 内：Dataview 列出 `#auto-matched` 标记的条目 → 批量审核

### 5.3 日历集成

**写入策略**：

```
用户输入："下周二上午10点机场接张教授看生产线"

1. AI 解析日期 → 2026-08-04 10:00
2. 检查 vault/daily/2026-08-04.md 是否存在
   → 不存在则从模板创建
3. 追加到当日笔记：

   ## 10:00 - 机场接张教授看生产线
   
   - 联系人：[[张教授]]
   - 地点：机场
   - 目的：看生产线
   - 状态：待办
   
4. 同时写入 Tasks 表（带 due_date 和 contact_id）
```

**读取**：Obsidian Calendar + Full Calendar 插件直接读 `daily/` 文件夹。

### 5.4 全局搜索

**搜索源合并**：

| 数据源 | 搜索方式 | 内容 |
|---|---|---|
| Vault `.md` 文件 | FTS5 全文索引（`.locus/index.db`） | 所有笔记、日记、对话存档 |
| SQLCipher Contacts | SQL LIKE / FTS | 联系人名字、公司、备注 |
| SQLCipher Activities | SQL LIKE / FTS | 交互记录内容 |
| SQLCipher Products | SQL LIKE | 产品名、类别 |
| SQLCipher ChatMessages | 现有 SQL | 对话历史 |

搜索结果合并显示，按相关度和时间排序。每条结果标注来源类型。

### 5.5 模板系统

Locus 维护 6-8 个核心模板在 `vault/templates/`，和 Obsidian Templater 共用格式：

```
templates/
├── quick-note.md      ← 快速笔记（默认）
├── contact.md          ← 联系人档案
├── deal.md             ← 商机记录
├── meeting-note.md     ← 会议纪要
├── product-spec.md     ← 产品参数
├── task.md             ← 待办事项
├── daily.md            ← 日记
└── chat-export.md      ← AI 对话导出
```

模板使用 `{{placeholder}}` 语法，AI 自动选择和填充。

### 5.6 AI 对话

**增强后的 RAG 上下文来源**：

```
用户提问 → ChatPage._sendMessage()
    │
    ├── 1. SQLCipher 长期记忆注入 System Prompt（现有）
    ├── 2. Vault FTS5 全文搜索关联内容（新增）
    ├── 3. 关联联系人最新 Activities（新增，CRM 上下文）
    ├── 4. VectorStorage 知识检索（保留，待升级为向量检索）
    └── 5. LLM 流式响应 + Markdown 渲染（现有）
```

### 5.7 联系人时间线

每个联系人在 Locus 内有独立视图：

```
联系人详情页：
┌─────────────────────────────────┐
│ 张建国 · 三环科技 · 采购总监      │
│ aliases: 张总, 老张, 张经理       │
│ 电话 138xxxx  |  最后联系 07-20   │
├─────────────────────────────────┤
│ [待办] 明天发报价单               │
│ [商机] 碳化硅平板膜 - 报价中      │
├─────────────────────────────────┤
│ 时间线：                         │
│ 07-26  电话：确认了规格4的需求     │
│ 07-20  拜访：带去样品看生产线      │
│ 07-15  邮件：发送了产品目录        │
│ ...                             │
└─────────────────────────────────┘
```

数据来源：Activities 表（主） + Deals 表（关联）。

---

## 六、迁移路径（从当前代码演进）

### Phase 1：基础设施（不破坏现有功能）

- [ ] 新增 `app_config` 表，用户配置 vault 路径
- [ ] 实现 `VaultService`（读写 `.md` 文件、frontmatter 解析/生成、文件变动监听）
- [ ] 实现 `FtsIndexService`（后台维护 `.locus/index.db`）
- [ ] 生成初始 vault 目录结构 + 默认模板文件
- [ ] 快速捕获双写：HubPayloads（现有） + vault inbox（新增）

### Phase 2：CRM 核心

- [ ] v7 migration：新增 Contacts / Deals / Activities / Products / Tasks 表
- [ ] 实现 `AiRouteService`（实体提取 prompt + API 调用）
- [ ] 实现联系人消歧引擎
- [ ] 实现联系人列表页 + 详情页 + 时间线
- [ ] 快速捕获 CRM 意图时自动写入 Activities + 镜像到 vault

### Phase 3：搜索与 AI 增强

- [ ] 全局搜索改为双源聚合（vault FTS + SQLCipher）
- [ ] AI 对话 RAG 增加 vault FTS 搜索
- [ ] AI 对话增加联系人上下文注入
- [ ] 聊天对话双写到 chat-logs/

### Phase 4：日历 & 模板

- [ ] 日期自然语言解析 → 写入 daily/ + Tasks 表
- [ ] 模板系统完整实现
- [ ] Calendar 页面：读取 daily/ 渲染日历视图

### Phase 5：清理与优化

- [ ] HubPayloads 表逐步废弃，写入改为纯 vault
- [ ] LongTermMemories 迁移到 vault system/memories/
- [ ] 移除旧 TimelinePage 和 MainNavigationScreen
- [ ] VectorStorage 升级为真正的向量嵌入 + 余弦检索

---

## 七、关键技术决策

| 决策 | 选择 | 理由 |
|---|---|---|
| CRM 存储 | SQLCipher（非 Obsidian 文件） | 几百个联系人的结构化查询、管道流转、消歧匹配需要数据库 |
| 知识库存储 | Markdown 文件（非 SQLCipher） | 长文、双链、Obsidian 互操作。非结构化内容不需要事务 |
| 日历 | Markdown daily/（非数据库） | Obsidian Calendar 插件生态直接支持 |
| Vault 加密 | 不做应用层加密，依赖系统盘加密 | Markdown 文件需要被 Obsidian 和其他工具读取。敏感信息（CRM）在 SQLCipher 加密层 |
| 云同步 | 不实现，由系统工具负责 | iCloud/Syncthing/Dropbox 已有成熟方案 |
| 文件监听 | `FileSystemEntity.watch()` 而非轮询 | 秒级感知 Obsidian 的变更 |
| AI 模型 | 保留现有 DeepSeek API 接口 | 可随时切换到本地模型 |

---

## 八、关键待办（开发看板）

| 优先级 | 任务 | 依赖 |
|---|---|---|
| P0 | 实现 VaultService（读写 .md + frontmatter） | 无 |
| P0 | 新增 AppConfig 表 + 设置页 vault 路径配置 | 无 |
| P1 | v7 Migration（5 张新表） | P0 |
| P1 | 快速捕获双写（vault + 现有） | P0 |
| P1 | AiRouteService（实体提取） | P1 |
| P1 | 联系人消歧引擎 | P1 |
| P1 | 联系人列表页 + 详情页 + 时间线 UI | P1 |
| P2 | FTS5 索引服务 | P0 |
| P2 | 全局搜索双源聚合 | P2 |
| P2 | AI 对话增强（vault RAG + CRM 上下文） | P2 |
| P2 | 日期解析 + daily 写入 | P0 |
| P3 | 模板系统完整实现 | P0 |
| P3 | Calendar 页面真实实现 | P2 |
| P3 | 清理死代码 | P3 |

---

## 九、不变原则

以下原则贯穿所有版本：

1. **本地优先**：核心功能离线可用，数据不依赖云端
2. **加密不妥协**：结构化敏感数据始终保持 SQLCipher AES-256 加密
3. **零摩擦输入**：任何功能的新增不能增加捕获步骤，FAB → 输入 → 完成，最多一次点击确认
4. **文件可移植**：Vault 内所有内容为标准 Markdown，任何编辑器可打开
5. **不做 Obsidian 能做的事**：不开发编辑器、不开发图谱、不开发双链系统
6. **Flutter 全平台**：手机端和桌面端一致体验

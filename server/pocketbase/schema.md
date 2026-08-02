# PocketBase Schema Reference

部署 PocketBase 后，在 Admin UI (`http://localhost:8090/_/`) 中手动创建以下 Collections。

## Collections 清单

### 1. contacts
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| name | text | ✅ | | 联系人名称 |
| aliases | text | | '[]' | 别名(JSON 数组) |
| company | text | | | 公司名 |
| role | text | | | 职位 |
| phone | text | | | 电话 |
| email | text | | | 邮箱 |
| tags | text | | '[]' | 标签(JSON) |
| notes | text | | | 备注 |
| avatar_path | text | | | 头像路径 |
| is_deleted | bool | ✅ | false | 软删除标记 |

索引：`company`, `name`, `is_deleted`

### 2. deals
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| contact_id | text | ✅ | | 关联联系人 UUID |
| title | text | ✅ | | 交易标题 |
| stage | text | | 'lead' | 阶段(lead/contacted/quoting/negotiation/won/lost) |
| value | number | | | 金额 |
| probability | number | | | 概率(%) |
| expected_close_date | date | | | 预计关闭日期 |
| notes | text | | | 备注 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`contact_id`, `stage`, `is_deleted`

### 3. activities
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| contact_id | text | ✅ | | 关联联系人 UUID |
| deal_id | text | | | 关联交易 UUID |
| type | text | ✅ | | 类型(call/visit/email/quote/contract/note) |
| content | text | ✅ | | 内容 |
| media_paths | text | | '[]' | 媒体路径(JSON) |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`contact_id`, `created`, `is_deleted`

### 4. tasks
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| title | text | ✅ | | 任务标题 |
| contact_id | text | | | 关联联系人 UUID |
| deal_id | text | | | 关联交易 UUID |
| due_date | date | | | 截止日期 |
| priority | number | | 0 | 优先级(0-3) |
| status | text | | 'pending' | pending/completed |
| source_text | text | | | 来源文本 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`status`, `due_date`, `is_deleted`

### 5. products
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| name | text | ✅ | | 产品名称 |
| category | text | | | 分类 |
| specs | text | | '{}' | 规格(JSON) |
| unit_price | number | | | 单价 |
| notes | text | | | 备注 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`category`, `is_deleted`

### 6. hub_payloads
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| raw_text | text | ✅ | | 原始输入文本 |
| media_paths | text | | '[]' | 媒体路径(JSON) |
| intent_tag | text | | 'NOTE' | 意图标签 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`intent_tag`, `created`, `is_deleted`

### 7. chat_sessions
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| title | text | ✅ | | 会话标题 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`updated`, `is_deleted`

### 8. chat_messages
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| session_id | text | ✅ | | 关联会话 UUID |
| role | text | ✅ | | 角色(user/assistant/system) |
| content | text | ✅ | | 消息内容 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`session_id`, `created`, `is_deleted`

### 9. long_term_memories
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| content | text | ✅ | | 记忆内容 |
| tags | text | | | 标签 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`updated`, `is_deleted`

### 10. knowledge_files
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| name | text | ✅ | | 文件名 |
| local_path | text | ✅ | | 本地路径 |
| size | number | ✅ | | 文件大小(字节) |
| extension | text | ✅ | | 扩展名 |
| is_active | bool | ✅ | true | 是否启用 |
| is_deleted | bool | ✅ | false | 软删除 |

索引：`updated`, `is_deleted`

## 注意事项

- PocketBase 自动生成 `id`（UUID）、`created`、`updated` 字段，无需手动创建
- 本地 `app_config` 和 `vector_storage` 表不同步到 PocketBase（纯本地表）
- 同步时使用 PocketBase 自带的 `filter` 参数做增量查询：`filter = "updated > '2024-01-01 00:00:00'"`

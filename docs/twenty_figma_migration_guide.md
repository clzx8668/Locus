# Twenty Figma 设计元素迁移指南

> 适用对象：把 Twenty 的 Figma 设计元素迁移到 Locus。  
> 当前状态：已确认 Figma 文件链接可打开，但自动化读取整个画布结构仍受 Figma 画布渲染方式限制，建议采用“你在 Figma 中点选 + 我持续整理”的协作方式。

## 1. 当前建议的迁移策略

推荐采用三段式迁移：

1. **先抽设计 token**
2. **再抽核心组件**
3. **最后落页面骨架**

不要一上来整页照搬。  
先拿到颜色、字体、间距、圆角、表格参数，再迁移 `panel`、`table`、`chip`、`avatar cell` 这些组件，会稳很多。

## 2. 这次优先迁移的对象

按你的目标，建议先迁这 5 类：

1. `FieldPanel` 详情侧栏
2. `Companies table` 表格
3. `Chip / Tag` 标签
4. `Avatar + Name Cell` 人员单元格
5. `Section Header / Group Header` 模块头

这 5 类已经足够把 Twenty 的核心后台视觉语言搬过来。

## 3. 你在 Figma 里怎么操作

下面这套流程最省时间。

### 3.1 先开 Dev Mode

在 Figma 文件中：

1. 打开目标页面
2. 切到右上角 `Dev Mode`
3. 逐个点选你要迁移的组件
4. 只记录右侧面板里的关键参数，不需要抄所有信息

## 4. 每个组件要记录什么

### 4.1 FieldPanel

请记录：

- Width / Height
- Padding
- Gap
- Background color
- Border color / Border width
- Radius
- Header 区高度
- Section header 高度
- Item 行高
- 标题字号 / 字重
- 正文字号 / 字重
- 次级文字颜色

### 4.2 Companies table

请记录：

- 整体容器宽度
- Header height
- Row height
- Group header height
- Cell padding
- Header text size / color
- Body text size / color
- Divider color
- Hover / Selected background
- 数值列是否右对齐

### 4.3 Chip / Tag

请记录：

- Height
- Padding
- Radius
- Background color
- Border color
- Text size
- Text color

### 4.4 Avatar + Name Cell

请记录：

- Avatar size
- Avatar and text gap
- Text size
- Text color

### 4.5 Group Header / Section Header

请记录：

- Height
- Padding
- Font size
- Font weight
- Text color
- Divider

## 5. 最快的协作方式

你不用整理成长文，直接按下面格式发我就行：

```text
[组件名]
width:
height:
padding:
gap:
radius:
background:
border:
title:
body:
muted:
notes:
```

例如：

```text
[Companies table]
width: 1152
header height: 34
row height: 30
group header: 32
cell padding x: 10
header text: 12 / #909090
body text: 12 / #505050
divider: #ECECE8
hover: #F8F8F6
notes: amount columns right aligned
```

## 6. 如果你想更快，我建议你这样截

优先给我这几种截图：

1. **组件选中后的右侧 Dev Mode 面板全图**
2. **颜色样式面板**
3. **Typography 样式面板**
4. **Spacing / Auto Layout 参数**
5. **单元格局部放大图**

这样我能更准确地区分：

- 真正的产品样式
- Figma 选中态高亮
- Auto Layout 辅助标记
- Dev Mode 才会显示的开发信息

## 7. 推荐的迁移顺序

建议你按这个顺序给我材料：

1. `FieldPanel`
2. `Chip`
3. `Section Header`
4. `Companies table`
5. `Avatar + Name Cell`
6. `Group Header`

每发一个，我就可以继续补：

- 设计参数文档
- Flutter design token
- 组件拆分建议
- 页面骨架代码

## 8. 我们的协作分工

你负责：

- 在 Figma 里点选组件
- 发截图或参数

我负责：

- 去噪和辨别哪些是 Figma 辅助标记
- 抽取可复用的设计 token
- 整理成 Locus 的组件参数档
- 转成 Flutter 更容易落地的结构

## 9. 下一步最省事的做法

请你下一次直接给我下面二选一：

### 方案 A：发截图

发这 3 张：

- `FieldPanel` 选中态右侧参数图
- `Companies table` 选中态右侧参数图
- `Chip` 或某个单元格局部图

### 方案 B：发纯文本参数

直接把你在 Dev Mode 看到的关键值贴给我，格式随意也行。

我收到后可以继续帮你输出：

- 更新现有 `twenty_company_panel_design_params.md`
- 生成 `Flutter token` 版本
- 生成 `Locus 组件映射表`

## 10. 结论

这个 Figma 链接目前能打开文件，但不适合直接依赖自动抓取来完整迁移设计系统。  
最有效的方式是：**你从 Figma Dev Mode 提供关键组件参数，我来负责提炼、归档和转成可开发的设计资产。**

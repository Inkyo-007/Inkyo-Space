---
title: Git 提交信息编写指南
published: 2026-09-14
updated: 2026-09-14
description: '一份 git commit message 的 Skill'
image: ''
tags: [开发, 实用]
category: '技术'
draft: false
lang: 'zh_CN'
---

# Git 提交信息编写指南（中文版）

> 基于 [tbaggery - A Note About Git Commit Messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
> 和 [Chris Beams - How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/) 两篇文章的精要提炼。

## 适用场景

当 agent 需要编写或生成 Git 提交信息（commit message）时使用。本 skill 适用于项目协作中需要统一、规范的中文提交信息。主题行使用中文，但保留必要的英文术语（如 API、bug、CLI 等）和代码标识。

---

## 七条核心规则（适配中文版）

### 1. 用空行分隔主题行与正文

```
50 字以内的简洁变更摘要

如有需要，在此添加更详细的说明文字。空行是关键分隔符，
Git 工具（log、shortlog、rebase 等）会将第一个空行之前的
内容视为主题行。简单改动可以只写一行主题。
```

- 空行是**关键分隔符**，不可省略。
- 只有一个空行，不要多空行。

### 2. 主题行限制在 50 个字符以内

- 中文主题行由于字符密度不同，建议控制在 **30 个中文字符**以内（等价于英文 50 字符）。
- 如果难以概括，说明提交内容过多——应拆分为多个**原子性提交**。

### 3. 主题行内容规范（中文场景下使用中文）

- 主题行以中文为主，必要时可混用英文术语。

✅ 正例：
```
修复用户登录时 token 过期未刷新的问题
新增文件上传 API 的类型校验
重构缓存层的并发控制逻辑
```

❌ 反例：
```
fixed token bug（避免中英混杂的非规范写法）
修复 bug（太模糊，看不出改了什么）
```

### 4. 主题行末尾不要加句号

- ✅ `优化首页加载性能`
- ❌ `优化首页加载性能。`
- ✅ `修正 CI 构建脚本中的路径错误`
- ❌ `修正 CI 构建脚本中的路径错误。`

### 5. 主题行使用祈使语气

中文的祈使语气表现为直接、简洁的**动宾结构**。避免过去时或进行时。

✅ 正例（推荐）：
```
修复登录页面的样式错乱
删除已废弃的 v1 API 接口
添加用户注册的邮箱验证逻辑
升级依赖库至安全版本
```

❌ 反例（避免）：
```
修复了登录页面的样式错乱（过去时）
正在处理登录页面的样式错乱（进行时）
修复 bug（太模糊）
```

**判断方法：** 主题行应读起来像一条"指令"或"命令"，而非事后描述。

### 6. 正文每行不超过 72 个字符

- 中文正文建议每行不超过 **36 个汉字**（按一个汉字 ≈ 2 个英文字符折算）。
- 编辑器建议设置 `textwidth=72`。

### 7. 正文解释 **What** 和 **Why**，而非 **How**

- **What**：本次提交做了什么改动
- **Why**：为什么需要这个改动（原有什么缺陷、新方案的优势）
- **How**：代码已自说明，除非实现复杂才需文字补充

---

## 完整模板

```
30 字以内简洁清晰的变更摘要

此处写更详细的说明性文字。每行建议不超过 36 个汉字。
解释本次提交要解决的问题，以及为什么选择当前的方案。
关注"做了什么"和"为什么做"，而非"怎么做的"。

如果有副作用或非直观的影响，在这里说明。

更多段落以空行分隔。

- 分项说明可以使用列表
- 使用连字符或星号作为列表标记
- 列表项之间用空行分隔

Closes: #123
See also: #456, #789
```

## 约定式提交规范（Conventional Commits）

> 源自 Angular 团队的提交信息规范，现已成为社区事实标准，可与语义化版本（SemVer）
> 和 CHANGELOG 自动生成工具（如 semantic-release）配合使用。
> 完整规范见 [conventionalcommits.org](https://www.conventionalcommits.org/zh-hans/v1.0.0/)。

### 基本格式

```text
<type>(<scope>): <subject>

<body>

<footer>
```

- `type`（类型，**必填**）：说明本次提交的性质，使用英文小写单词。
- `scope`（范围，**可选**）：用括号标注改动涉及的模块或区域，如 `fix(登录): ...`。
- `subject`（主题行）：冒号后空一格，依然遵循前述七条规则
  （中文动宾结构、30 字内、结尾无句号）。
- 简单改动可省略括号与正文：`docs: 修正 README 中的错别字`。

### 常用 type 一览

| type | 含义 | 版本号影响（SemVer） |
|:---|:---|:---|
| `feat` | 新功能（feature） | minor 升级 |
| `fix` | 修复 bug | patch 升级 |
| `docs` | 仅文档改动（README、注释等） | 无 |
| `style` | 代码格式调整（空格、分号、缩进），不改变逻辑 | 无 |
| `refactor` | 重构：既不修 bug 也不加功能 | 无 |
| `perf` | 性能优化（performance） | 视情况 |
| `test` | 添加或修改测试 | 无 |
| `build` | 构建系统或依赖改动（webpack、pom.xml、package.json 等） | 无 |
| `ci` | CI 配置改动（GitHub Actions、Jenkins 等） | 无 |
| `chore` | 其他杂项维护（如更新 .gitignore） | 无 |
| `revert` | 回滚某次提交 | 视情况 |

### 破坏性变更（Breaking Change）

两种等价写法，都会触发 SemVer major 升级：

```text
feat!: 移除对 Node 12 的支持

BREAKING CHANGE: 最低支持的 Node 版本升级为 14，旧版本将无法运行。
```

- `type` 后紧跟 `!` 表示本次提交包含不兼容变更。
- 正文或 footer 中用 `BREAKING CHANGE:`（英文全大写 + 冒号）说明具体影响。

### 示例

```text
feat(订单): 新增订单导出 Excel 功能
fix(登录): 修复 token 过期后未自动刷新的问题
docs: 更新 README 中的部署说明
perf(首页): 将列表渲染改为虚拟滚动以降低卡顿
test(用户): 补充密码强度校验的单元测试
chore(deps): 升级 lodash 至 4.17.21
revert: 回滚 "feat(订单): 新增订单导出 Excel 功能"
```

带正文的完整示例：

```text
fix(缓存): 修复并发写入导致的数据错乱

高并发场景下多个请求可能同时写入同一缓存键，
导致偶发的数据覆盖。改为按 key 加互斥锁，并补充回归测试。

Fixes: #789
```

> **与七条规则的关系：** 约定式提交是在七条规则之上增加的"前缀分类"约定，
> 两者不冲突——主题行依然保持简洁、动宾结构、不超长度。
> 前缀中的 `type` 固定使用英文小写，主题部分继续用中文。
> 使用前请确认目标仓库是否已采用该规范，**一致性优先**。

## 场景化示例

### 简单改动（一行即可）

```
修复用户指南中的拼写错误
```

### 功能新增

```
新增微信支付对接模块

实现微信 Native 支付的回调验证与订单状态同步逻辑。
采用统一下单 API，在支付成功后更新订单状态为"已支付"。

Closes: #456
```

### Bug 修复

```
修复大量并发请求下连接池耗尽的问题

root cause 是 HttpClient 默认连接池上限为 20，
在高并发场景下新请求会一直等待空闲连接。
将最大连接数调整为 200 并添加空闲回收超时机制。

Fixes: #789
```

### 重构 / 优化

```
重构数据导出模块，提升大文件处理性能

之前使用 DOM 方式构建 Excel 导致内存溢出。
改为 SAX 流式写入，单文件处理内存占用从 500MB 降至 50MB。
```

## 元数据标注（可选）

在正文末尾添加 issue 引用，建议使用 GitHub / GitLab 标准格式：

- `Closes: #123` — 关闭 issue
- `Fixes: #456` — 修复问题
- `Refs: #789` — 关联引用
- `Resolves: #234` — 解决
- `BREAKING CHANGE:` — 破坏性变更

## 常见反例速查

| ❌ 不要这样写 | ✅ 应该这样写 | 问题 |
|:---|:---|:---|
| `修复了数据导出的 bug` | `修复数据导出时 Excel 列宽溢出的问题` | 已做 → 要做；表述不够精确 |
| `修改了一些代码` | `清理 UserService 中未使用的 import 语句` | 过于模糊 |
| `新增功能。` | `新增用户密码重置功能` | 结尾句号；不够具体 |
| `change user avatar upload` | `更新用户头像上传接口的图片压缩逻辑` | 非中文主题 |

## 编写流程

1. 明确本次提交的核心变更点
2. 用祈使语气的动宾结构写一行摘要（30 汉字内）
3. 空一行
4. 在正文中解释 What 和 Why
5. 每行不超过 36 汉字（或 72 字符）
6. 末尾添加 issue 引用（如有）

## 一些灵活的原则

- **主题行语言**：主体用中文，但代码标识符、专有名词、缩写（API、CLI、UI、CI/CD 等）保留英文。
- **正文语言**：整体用中文，便于团队阅读；代码片段保持原文。
- **一致性优先**：同一仓库内的风格比某种"最佳风格"重要得多。
- **原子性**：每个提交应当只做一件事，方便回滚和 review。

---

**来源参考：**
- [A Note About Git Commit Messages - tbaggery (Tim Pope)](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
- [How to Write a Git Commit Message - Chris Beams](https://chris.beams.io/posts/git-commit/)
- [Pro Git Book - Contributing to a Project](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project#_commit_guidelines)
- [Conventional Commits 1.0.0 规范（中文）](https://www.conventionalcommits.org/zh-hans/v1.0.0/)

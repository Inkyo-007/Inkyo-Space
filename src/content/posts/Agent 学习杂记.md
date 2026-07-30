---
title: Agent 学习杂记
published: 2026-07-29
updated: 2026-07-29
description: '用于备忘的学习笔记，塞了各种内容'
image: ''
tags: [AI Agent, 笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## 2026-07-29

### 良好的项目架构

一个良好的 agent 项目架构：

```
my_agent_project/
├── main.py                  # 入口：只负责启动和交互循环
├── config.py                # 配置：模型名、API key、温度等集中管理
├── agents/
│   └── assistant.py         # agent 的组装逻辑（模型 + 工具 + prompt）
├── tools/                   # 工具层：每个工具一个文件
│   ├── __init__.py          # 统一导出 all_tools
│   ├── get_weather.py
│   └── calculate_expression.py
├── prompts/                 # prompt 较长时，从代码中抽出来单独放
│   └── assistant.py         # 或者直接写成 .txt / .jinja 模板
├── services/                # 外部世界的封装：API 客户端、数据库访问等
│   └── weather_api.py       # 真正的天气 API 请求放这里，tool 只是调用它
└── tests/                   # 测试，目录结构镜像源代码
    └── test_tools/
        └── test_calculate.py
```

1. **入口要薄**：main.py 只做"读输入 → 调 agent → 打印输出"。  
2. **依赖单向流动**：main → agents → tools → services，底层不知道上层的存在，防止出现循环引用
3. **配置集中、密钥走环境变量**：模型名、base_url、温度这类东西收到 config.py 或 .env 里，并且 .env 要加进 .gitignore。

### 良好的 python 命名规范

| 类型 | 风格 | 示例 | 说明 |
|------|------|------|------|
| 变量、函数 | snake_case | `user_input`、`get_weather()` | 全小写，下划线分隔 |
| 类 | PascalCase | `WeatherClient`、`CalculateExpressionInput` | 大驼峰，不用下划线 |
| 常量 | SCREAMING_SNAKE_CASE | `API_BASE_URL`、`MAX_RETRIES` | 全大写 |
| 模块/文件名 | snake_case | `get_weather.py` | 和函数一样 |
| 包/目录名 | 全小写 | `tools/`、`agents/` | 尽量短，尽量不用下划线 |
| 私有成员 | 前缀下划线 | `_internal_helper()` | 表示"别从外部直接用" |
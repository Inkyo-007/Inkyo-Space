---
title: Agent 开发杂记
published: 2026-09-17
updated: 2026-09-17
description: '用于备忘的学习笔记，主要记录了 Agent 开发相关的内容'
image: ''
tags: [AI Agent, 开发, 笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## OpenAI 客户端初始化

### `openai.OpenAI()` 参数：

```py
client = OpenAI(
    api_key="sk-...",                      # str | None，默认读 OPENAI_API_KEY 环境变量
    base_url="https://api.openai.com/v1",  # str | None，默认读 OPENAI_BASE_URL 环境变量
    organization="org-...",                # str | None，默认读 OPENAI_ORG_ID
    project="proj_...",                    # str | None，默认读 OPENAI_PROJECT_ID
    timeout=600.0,                         # float | Timeout，请求超时（秒）
    max_retries=2,                         # int，失败重试次数，默认 2
    default_headers={"X-Custom": "val"},   # Mapping[str, str] | None，附加到每个请求
    default_query={"k": "v"},              # Mapping[str, object] | None，附加到每个请求
    http_client=None,                      # httpx.Client | None，自定义 HTTP 客户端
)
```

### `chat.completions.create()` 参数：

```py
response = client.chat.completions.create(
    # ---- 基础 ----
    model="gpt-4o",                        # str，必填
    messages=[                             # list[dict]，必填
        {"role": "system", "content": "你是一个助手"},
        {"role": "user", "content": "你好"},
        {"role": "assistant", "content": None, "tool_calls": [
            {"id": "call_abc", "type": "function",
            "function": {"name": "get_weather", "arguments": "{\"city\": \"北京\"}"}}
        ]},
        {"role": "tool", "tool_call_id": "call_abc", "content": "晴"}
    ],
    # ---- 采样 ----
    temperature=1.0,                       # float，0~2
    top_p=1.0,                             # float，0~1
    n=1,                                   # int，返回几条候选
    stop=["\n\n"],                         # str | list[str] | None
    seed=42,                               # int | None，尽量复现输出
    frequency_penalty=0.0,                 # float，-2~2
    presence_penalty=0.0,                  # float，-2~2
    logit_bias={"50256": -100},            # dict[int, float] | None
    # ---- 长度 ----
    max_completion_tokens=4096,            # int | None，新参数（含推理 token）
    # max_tokens=4096,                     # 已废弃，o 系列不识别
    # ---- 工具 ----
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "查询天气",
            "parameters": {                # JSON Schema
                "type": "object",
                "properties": {"city": {"type": "string"}},
                "required": ["city"],
            },
        },
    }],
    tool_choice="auto",                    # "none" | "auto" | "required" | {"type": "function", "function": {"name": "..."}}
    parallel_tool_calls=True,              # bool，是否允许并行工具调用
    # ---- 推理（o 系列 / GPT-5）----
    reasoning_effort="medium",             # "none" | "minimal" | "low" | "medium" | "high"，取值随模型而定
    verbosity="medium",                    # "low" | "medium" | "high"，GPT-5 系列
    # ---- 输出格式 ----
    response_format={"type": "json_object"},  # text | json_object | json_schema
    # ---- 流式 ----
    stream=False,
    stream_options={"include_usage": True},   # 流式时最后一个 chunk 带 usage
    # ---- 可观测 / 缓存 ----
    logprobs=False,
    top_logprobs=5,                        # int，0~20，需 logprobs=True
    metadata={"session_id": "abc"},
    store=False,
    service_tier="auto",                   # "auto" | "default" | "flex" | "priority"
    prompt_cache_key="user-123",
    # ---- SDK 级（不进请求体）----
    extra_body={},                         # 第三方扩展参数入口
    extra_headers={},
    extra_query={},
    timeout=30.0,                          # 单次请求覆盖客户端超时
)
```

参数解释：

`response_format`

```py
# 强制 JSON 输出
response_format={"type": "json_object"}

# 然后提示词中要说"返回 JSON"
messages = [
    {"role": "system", "content": "你是助手，返回 JSON 格式"},
    {"role": "user", "content": "提取姓名和年龄，返回 JSON"}
]
```

`stream`

```py
# 非流式（默认）
response = client.chat.completions.create(...)

# 流式
stream = client.chat.completions.create(..., stream=True)
for chunk in stream:
    print(chunk.choices[0].delta.content, end="")
```

## Anthropic 客户端初始化

### `anthropic.Anthropic()` 参数

```py
client = Anthropic(
    api_key="sk-ant-...",                  # str | None，默认读 ANTHROPIC_API_KEY
    auth_token=None,                       # str | None，Bearer 认证（部分代理用），默认读 ANTHROPIC_AUTH_TOKEN
    base_url="https://api.anthropic.com",  # str | None，默认读 ANTHROPIC_BASE_URL
    timeout=600.0,                         # float | Timeout
    max_retries=2,                         # int，默认 2
    default_headers={},
    default_query={},
    http_client=None,
)
# SDK 会自动附加两个必需头：x-api-key 和 anthropic-version
```

与 OpenAI 的差异是不包含 `organization` 与 `project`

### Anthropic `messages.create()` 参数`

```py
response = client.messages.create(
    # ================= 基础（三个必填）=================
    model="claude-opus-5",                 # str，必填
    max_tokens=8096,                       # int，必填（思考模式下必须 > thinking.budget_tokens）
    messages=[                             # list[dict]，必填，role 只有 "user"/"assistant"
        {"role": "user", "content": "你好"},  # content 可为 str 或 block 列表
        # assistant 历史消息：思考块必须原样回传（含 signature）
        {"role": "assistant", "content": [
            {"type": "thinking", "thinking": "...", "signature": "EqUDCkYI..."},
            {"type": "redacted_thinking", "data": "EmwKAhgBEgy3va..."},
            {"type": "text", "text": "..."},
            {"type": "tool_use", "id": "toolu_xxx", "name": "get_weather",
             "input": {"city": "北京"}},
        ]},
        # 工具结果：以 tool_result block 放在 user 消息中回传
        {"role": "user", "content": [
            {"type": "tool_result", "tool_use_id": "toolu_xxx",
             "content": "晴", "is_error": False},
        ]},
    ],

    # ================= 角色设定 =================
    system="你是一个助手",                  # str | list[dict] | None，顶层参数（不在 messages 里）
    # 列表形态可带缓存控制：
    # system=[{"type": "text", "text": "...",
    #          "cache_control": {"type": "ephemeral", "ttl": "5m"}}],   # ttl: "5m" | "1h"

    # ================= 推理控制（⚠️ 新 API 形态）=================
    output_config={
        "effort": "high",                  # "low" | "medium" | "high" | "xhigh" | "max"
        # "format": {...},                 # JSONOutputFormatParam，结构化输出
    },
    thinking={"type": "enabled", "budget_tokens": 5000},   # budget 最小 1024，必须 < max_tokens
    # thinking={"type": "adaptive"},       # 由模型自行决定是否/多少思考
    # thinking={"type": "disabled"},       # 显式关闭（默认）
    # 以上两种 thinking 均可加 "display": "summarized" | "omitted"（思考内容的展示形态）

    # ⚠️ 注意：temperature / top_p / top_k 已从 SDK 1.7.0 移除（新模型不再支持采样参数）

    # ================= 工具 =================
    tools=[{
        "name": "get_weather",             # str，必填
        "description": "查询天气",          # str | None
        "input_schema": {                  # dict，必填，JSON Schema（无 "type": "function" 包装）
            "type": "object",
            "properties": {"city": {"type": "string"}},
            "required": ["city"],
        },
        # ---- 可选高级字段 ----
        # "strict": True,                  # 严格模式
        # "cache_control": {"type": "ephemeral"},
        # "defer_loading": True,           # 延迟加载（agentic 场景）
        # "eager_input_streaming": True,   # 流式输入
        # "input_examples": [...],         # 参数示例
        # "allowed_callers": [...],        # 允许的调用方
    }],
    tool_choice={"type": "auto"},          # 让模型自行决定（默认）
    # tool_choice={"type": "any"},         # 必须调用某个工具
    # tool_choice={"type": "tool", "name": "get_weather"},  # 强制调用指定工具
    # tool_choice={"type": "none"},        # 禁止工具调用
    # auto/any/tool 均可加 "disable_parallel_tool_use": True 禁用并行调用

    # ================= 其他 =================
    stop_sequences=["\n\n"],               # list[str] | None，最多 4 个
    metadata={"user_id": "user-123"},      # dict，仅支持 user_id 一个键
    service_tier="auto",                   # "auto" | "standard_only"
    cache_control={"type": "ephemeral", "ttl": "5m"},  # 顶层缓存控制
    stream=False,                          # bool
    # ---- 高级/agentic 特性（初学可忽略）----
    # container="container_xxx",           # str | dict，代码执行沙箱容器
    # inference_geo="us",                  # str，推理地理位置
    # workspace_id="ws_xxx",               # str，工作空间
    # user_profile_id="user_xxx",          # str，用户档案

    # ================= SDK 级（不进请求体）=================
    extra_headers={                        # dict，如 beta 特性头
        # "anthropic-beta": "interleaved-thinking-2025-05-14",
    },
    extra_query={},
    extra_body={},
    timeout=600.0,                         # float，单次请求覆盖客户端超时
)
```

与 OpenAI 的差异：

- `max_tokens` 必须填写
- `system` 是独立参数，不包含在 `message` 中
- `tools` / `tool_choice` 格式不同

`tools` / `tool_choice` 格式差异比较：

```py
# OpenAI
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "获取天气",
            "parameters": {...}  # 用 parameters
        }
    }
]

# Anthropic
tools = [
    {
        "name": "get_weather",
        "description": "获取天气",
        "input_schema": {...}  # 用 input_schema，没有 type 包装
    }
]

# OpenAI
tool_choice="auto"                    # 字符串
tool_choice={"type": "function", "function": {"name": "xxx"}}  # 强制特定工具

# Anthropic
tool_choice={"type": "auto"}          # 字典
tool_choice={"type": "any"}           # 必须用工具
tool_choice={"type": "tool", "name": "xxx"}  # 强制特定工具
```

## OpenAI 响应格式

### 非流式响应

```json
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion",
    "created": 1735689600,
    "model": "deepseek-chat",
    "system_fingerprint": "fp_xxx",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "最终回答",
                "reasoning_content": "思考过程文本（思考模式时返回，官方格式中不存在此字段）",
                "tool_calls": [
                    {
                        "id": "call_00_xxx",
                        "type": "function",
                        "function": {
                            "name": "get_weather",
                            "arguments": "{\"city\": \"北京\"}"
                        }
                    }
                ]
            },
            "finish_reason": "stop",
            "logprobs": null
        }
    ],
    "usage": {
        "prompt_tokens": 32,
        "completion_tokens": 50,
        "total_tokens": 82,
        "prompt_tokens_details": {
            "cached_tokens": 0
        },
        "completion_tokens_details": {
            "reasoning_tokens": 50
        },
        "prompt_cache_hit_tokens": 0,
        "prompt_cache_miss_tokens": 32
    }
}
```

**tool_calls 结构**

```py
[
    {
        "id": "call_abc123",
        "type": "function",
        "function": {
            "name": "get_weather",
            "arguments": '{"city": "北京"}'  # JSON 字符串！
        }
    }
]
```

### 流式响应

```py
# 第一个 chunk
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "system_fingerprint": "fp_xxx",
    "choices": [
        {
            "index": 0,
            "delta": {
                "role": "assistant",
                "content": ""
            },
            "finish_reason": null,
            "logprobs": null
        }
    ],
    "usage": null
}


# 思考 chunk：delta.reasoning_content 逐段到达
# OpenAI 官方不包括这个块，是拿不到思考内容的
{
    "id": "4d5b67b2-7765-4866-b61a-1e1b862c520a",
    "object": "chat.completion.chunk",
    "created": 1789843893,
    "model": "deepseek-flash",
    "choices": [
        {
            "index": 0,
            "delta": {
                "reasoning_content": "We"
            }
        }
    ]
}

# 正文 chunk（思考后出现）
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "choices": [
        {
            "index": 0,
            "delta": {
                "content": "你好" # 增量文本
            },
            "finish_reason": null
        }
    ]
}

# 流式 chunk 中的 tool_calls 结构
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "choices": [
        {
            "index": 0,
            "delta": {
                "tool_calls": [
                    {
                        "index": 0,
                        "id": "call_abc123",
                        "type": "function",
                        "function": {
                            "name": "get_weather",
                            "arguments": ""
                        }
                    }
                ]
            },
            "finish_reason": null
        }
    ]
}

{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "choices": [
        {
            "index": 0,
            "delta": {
                "tool_calls": [
                    {
                        "index": 0,
                        "function": {
                            "arguments": "{\"city\": \"北"
                        }
                    }
                ]
            },
            "finish_reason": null
        }
    ]
}

# 结束 chunk
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "choices": [
        {
            "index": 0,
            "delta": {},
            "finish_reason": "stop",
            "logprobs": null
        }
    ]
}

# usage chunk（仅当 stream_options={"include_usage": True}）：choices 为空数组
# 对于 deepseek 这样的 OpenAI 兼容服务，是直接把 "usage" 段直接挂在结束 chunk 里的
{
    "id": "chatcmpl-xxx",
    "object": "chat.completion.chunk",
    "created": 1735689600,
    "model": "gpt-4o",
    "choices": [],
    "usage": {
        "prompt_tokens": 32,
        "completion_tokens": 50,
        "total_tokens": 82,
        "completion_tokens_details": {
            "reasoning_tokens": 0
        }
    }
}
```

**处理方式**

```py
stream = client.chat.completions.create(..., stream=True)

for chunk in stream:
    delta = chunk.choices[0].delta
    
    # 文本增量
    if delta.content:
        print(delta.content, end="", flush=True)
    
    # 结束
    if chunk.choices[0].finish_reason:
        print(f"\n结束: {chunk.choices[0].finish_reason}")
```

## Anthropic 响应格式

### 非流式响应

```py
{
    "id": "msg_01XFDUDYJgAACzvnptvVoYEL",
    "type": "message",
    "role": "assistant",
    "model": "claude-sonnet-4-5",
    "content": [
        {
            "type": "thinking",
            "thinking": "让我分析这个问题...",
            "signature": "EqUDCkYIAxgCKkB..."
        },
        # 开启扩展思考后，模型的思考过程偶尔会包含被 Anthropic 安全系统标记的内容（比如涉及敏感话题的推理）。
        # 这时 API 不返回明文思考，而是返回一个 redacted_thinking block
        # data 是一段加密的不透明字符串，客户端无法解密、也不应尝试解析
        # 其是正常 thinking block 的替代品，那部分思考内容不可见，但对 Anthropic 服务端可读
        {
            "type": "redacted_thinking",
            "data": "EmwKAhgBEgy3va..."
        },
        {
            "type": "text",
            "text": "最终回答"
        },
        {
            "type": "tool_use",
            "id": "toolu_01A09q90qw90lq917835lq9",
            "name": "get_weather",
            "input": {
                "city": "北京"
            }
        }
    ],
    "stop_reason": "end_turn",
    "stop_sequence": null,
    "usage": {
        "input_tokens": 120,
        "output_tokens": 85,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0
    }
}
```

### 流式响应

```py
with client.messages.stream(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "你好"}]
) as stream:
    for event in stream:
        print(event)
```

Anthropic 流式返回的是**事件序列**，而不是简单的 chunk：

```py
# 事件 1：消息开始
{
    "type": "message_start",
    "message": {
        "id": "msg_01XFDUDYJgAACzvnptvVoYEL",
        "type": "message",
        "role": "assistant",
        "model": "claude-sonnet-4-5",
        "content": [],
        "stop_reason": null,
        "usage": {
            "input_tokens": 120,
            "output_tokens": 1
        }
    }
}

# 事件 2：内容块开始
{
    "type": "content_block_start",
    "index": 0,
    "content_block": {
        "type": "thinking",
        "thinking": "",
        "signature": ""
    }
}

# redacted_thinking 的加密数据无法逐段流式化（密文分段没有意义）
# 所以它是在 content_block_start 里一次性给全，中间没有任何 delta
{
    "type": "content_block_start",
    "index": 0,
    "content_block": {
        "type": "redacted_thinking",
        "data": "EmwKAhgBEgy3va..."
    }
}

# 事件 3：内容块增量
{
    "type": "content_block_delta",
    "index": 0,
    "delta": {
        "type": "thinking_delta",
        "thinking": "让我分析"
    }
}
{
    "type": "content_block_delta",
    "index": 0,
    "delta": {
        "type": "signature_delta",
        "signature": "EqUDCkYIAxgCKkB..."
    }
}
{
    "type": "content_block_delta",
    "index": 1,
    "delta": {
        "type": "text_delta",
        "text": "最终回答"
    }
}
{
    "type": "content_block_delta",
    "index": 2,
    "delta": {
        "type": "input_json_delta",
        "partial_json": "{\"city\": \"北"
    }
}

# 事件 4：内容块结束
{
    "type": "content_block_stop",
    "index": 2
}
# 消息增量（usage 更新）
{
    "type": "message_delta",
    "delta": {
        "stop_reason": "end_turn",
        "stop_sequence": null
    },
    "usage": {
        "output_tokens": 85
    }
}
# 消息结束
{
    "type": "message_stop"
}
```

**完备的处理方式参考**

```py
def process_stream_events(stream):
    """处理 Anthropic 流式事件"""
    
    # 状态
    text_parts = []
    tool_calls = {}  # index -> {id, name, input_parts}
    current_tool_index = None
    usage = None
    stop_reason = None
    
    for event in stream:
        # ===== 消息开始 =====
        if event.type == "message_start":
            usage = event.message.usage
            print(f"[message_start] input_tokens: {usage.input_tokens}")
        
        # ===== 内容块开始 =====
        elif event.type == "content_block_start":
            block = event.content_block
            
            if block.type == "text":
                print(f"[text_start] index: {event.index}")
            
            elif block.type == "tool_use":
                current_tool_index = event.index
                tool_calls[current_tool_index] = {
                    "id": block.id,
                    "name": block.name,
                    "input_parts": []
                }
                print(f"[tool_start] index: {event.index}, name: {block.name}, id: {block.id}")
        
        # ===== 内容块增量 =====
        elif event.type == "content_block_delta":
            delta = event.delta
            
            if delta.type == "text_delta":
                text_parts.append(delta.text)
                print(f"[text_delta] {delta.text}", end="")
            
            elif delta.type == "input_json_delta":
                if current_tool_index is not None:
                    tool_calls[current_tool_index]["input_parts"].append(delta.partial_json)
                    print(f"[input_json_delta] {delta.partial_json}", end="")
        
        # ===== 内容块结束 =====
        elif event.type == "content_block_stop":
            print(f"\n[block_stop] index: {event.index}")
            current_tool_index = None
        
        # ===== 消息增量 =====
        elif event.type == "message_delta":
            stop_reason = event.delta.stop_reason
            if event.usage:
                usage.output_tokens = event.usage.output_tokens
            print(f"[message_delta] stop_reason: {stop_reason}")
        
        # ===== 消息结束 =====
        elif event.type == "message_stop":
            print(f"[message_stop]")
    
    # 解析工具调用
    parsed_tools = []
    for index, tc in tool_calls.items():
        full_json = "".join(tc["input_parts"])
        parsed_input = json.loads(full_json)
        parsed_tools.append({
            "id": tc["id"],
            "name": tc["name"],
            "input": parsed_input
        })
    
    return {
        "text": "".join(text_parts),
        "tool_calls": parsed_tools,
        "usage": usage,
        "stop_reason": stop_reason
    }
```
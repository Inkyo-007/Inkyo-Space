---
title: uv 包管理器介绍
published: 2026-09-26
updated: 2026-09-26
description: '介绍 Python 项目中的 uv 包管理器'
image: ''
tags: [Python, 开发, 笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## 1. uv 简介

uv 是由 Astral（即开发 Ruff 的公司）用 Rust 编写的 Python 包和项目管理工具，2024 年发布后迅速成为 Python 生态中最受欢迎的工具之一。

相较于较前出现的 Python 管理工具 poetry、pdm，uv 吸收了它们的经验并取得了发展，在 2026 年的今天，uv 已经事实上成为新 Python 项目的默认选择之一。

## 2. 为什么用 uv？

1. **高性能**：由于 uv 是用 Rust 编写的，它在处理依赖解析和安装时比纯 Python 工具更快，在安装的时候比传统的 pip 快 10–100 倍。
2. **简洁的配置**：uv 使用单一的 `uv.toml` 文件管理项目依赖和配置，避免了多文件管理的复杂性。
3. **现代化特性**：uv 支持虚拟环境自动管理、依赖锁定、版本约束等现代化功能，避免了 pip + venv + pyenv + pip-tools + pipx 等多种工具的繁琐组合，使得项目管理更加高效。
4. **良好的生态兼容性**：uv 能够与现有的 Python 包生态无缝集成，支持 PyPI、私有仓库等多种源。
5. **活跃的社区**：作为 Astral 推出的工具，uv 拥有活跃的开发和用户社区，问题反馈和功能更新都非常及时。

总之就是，好用爱用多用！

## 3. uv 完整使用指南

### 3.1 安装 uv

uv 是单文件二进制，支持所有主流平台：

```bash
# macOS / Linux（官方推荐）
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows PowerShell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"

# 或用 pip / pipx / Homebrew
pip install uv
brew install uv
pipx install uv
```

安装后验证并启用命令自动补全（可选）：

```bash
# 验证安装是否成功
uv --version
# 启用命令自动补全
uv generate-shell-completion bash >> ~/.bashrc
``` 

升级自身：

```bash
uv self update
```

### 3.2 两种使用模式

uv 提供了两种主要的使用模式：

1. **项目模式**：在项目根目录下使用 `uv` 管理依赖和配置，适用有 `pyproject.toml` 的正式项目，适合大多数 Python 项目。
2. **脚本模式**：适用于临时脚本或小型项目，如单个 .py 文件，无需创建完整的项目结构，可以快速管理依赖和运行脚本。

### 3.3 项目模式

#### 创建项目

```bash
uv init my_project
cd my_project
```

#### 生成的结构

```plain
my-project/
├── .python-version       # 记录项目使用的 Python 版本
├── pyproject.toml        # 项目配置 + 依赖声明
├── README.md
└── main.py / hello.py
```

#### 添加 / 移除依赖

```bash
uv add requests                    # 安装并加入 pyproject.toml
uv add 'requests>=2.30'            # 指定版本约束
uv add ruff --dev                  # 开发依赖（仅在开发环境安装）
uv add pytest --group test         # 自定义依赖组
uv remove requests                 # 卸载并移除声明
```

此时 pyproject.toml 中对应的变化：

```toml
[project]
dependencies = [
    "requests>=2.32",
]

[dependency-groups]
dev = ["ruff"]
test = ["pytest"]
```

#### 同步环境

`uv sync` 是核心命令，它保证当前虚拟环境和 `uv.lock` 完全一致：

```bash
uv sync                      # 创建/更新 .venv，精确安装锁文件中的版本
uv sync --upgrade            # 升级所有依赖并重新锁
uv sync --no-dev             # 只装生产依赖（如部署时）
```

典型的工作场景是，另一名开发者克隆项目后，只需 `uv sync`，就能得到一个和锁文件完全一致的环境，这样就不需要手动建 venv 了。

#### 锁文件操作

```bash
uv lock                      # 只生成/更新 uv.lock，不动环境
uv lock --upgrade-package requests   # 只升级某个包
uv lock --check              # 检查当前环境与锁文件是否一致
uv tree                      # 查看依赖树
uv tree --outdated           # 查看哪些包有新版本
```

#### 在项目中运行

```bash
uv run main.py               # 自动确保环境同步后运行（无需手动激活 venv）
uv run python                # 进入项目环境的 Python REPL
uv run pytest                # 运行项目里的命令
```

#### 构建与发布

```bash
uv build                     # 构建 sdist / wheel 到 dist/
uv publish                   # 发布到 PyPI（需配置 token）
```

### 3.4 脚本模式

#### 内联依赖元数据

在脚本头部用注释声明依赖，uv 自动创建隔离环境并运行：

```python
# main.py
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests",
#     "rich",
# ]
# ///

import requests
from rich import print

resp = requests.get("https://api.github.com")
print(resp.status_code)
```

运行：

```bash
uv run main.py               # 首次自动解析依赖，之后秒开
```

#### 用命令管理脚本依赖（无需手写注释）

```bash
uv add --script main.py requests    # 自动写入内联元数据
uv remove --script main.py requests
```

### 3.5 Python 版本管理

```bash
uv python list                    # 查看可下载/已安装的版本
uv python install 3.12            # 安装 Python 3.12
uv python install 3.11 3.12       # 一次装多个
uv python pin 3.12                # 写入 .python-version，锁定项目版本
```

`uv init` / `uv sync` 会自动按 `.python-version` 或 `pyproject.toml` 中的 `requires-python` 下载并选用正确的 Python 版本。

如果没安装对应版本也没关系，uv 会自动安装所需的 Python 版本。

### 3.6 工具运行

临时使用 CLI 工具，装在隔离环境中，不污染项目：

```bash
uvx ruff check .                  # 等价 uv tool run，用完即走
uvx black .                       # 同上，等价 uv tool run
uvx --from httpie http            # 包名和命令名不同时用 --from
```

永久安装某个工具：

```bash
uv tool install ruff              # 安装并加入 PATH
uv tool list                      # 查看已安装的工具
uv tool upgrade ruff              # 升级
uv tool uninstall ruff
```

### 3.7 虚拟环境

如果不想用项目模式，uv 也能像 venv 一样手动管理：

```bash
uv venv                        # 创建 .venv（默认）
uv venv myenv --python 3.11    # 指定名字和 Python 版本
uv pip install requests        # 在环境中装包（兼容 pip 语法）
uv pip list                    # 列出已安装的包
uv pip freeze                  # 输出已安装包的冻结列表
uv pip compile requirements.in -o requirements.txt   # 替代 pip-tools，生成锁定的依赖文件
```

### 3.8 常用配置

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["requests>=2.32"]

[tool.uv]
# 私有源配置
[[tool.uv.index]]
url = "https://pypi.tuna.tsinghua.edu.cn/simple"  # 清华镜像
default = true

# 可选依赖（extras）
[project.optional-dependencies]
torch = ["torch>=2.0"]

# 限定某个包只能从指定源装（防止依赖混淆攻击）
[tool.uv.sources]
torch = [{ index = "pytorch-cu121" }]
```

国内用户配置清华镜像后下载速度会快很多。

### 3.9 CI/CD 中的典型用法

```yaml
# GitHub Actions 示例
- uses: astral-sh/setup-uv@v5
  with:
    enable-cache: true          # 自动缓存依赖，非常快
- run: uv sync --locked         # --locked 要求锁文件是最新的，保证可复现
- run: uv run pytest
- run: uv build
```

## 4. 常用速查表

| 场景           | 命令                        |
| ------------ | ------------------------- |
| 新建项目         | `uv init`                 |
| 装依赖          | `uv add <pkg>`            |
| 装开发依赖        | `uv add <pkg> --dev`      |
| 卸载           | `uv remove <pkg>`         |
| 还原环境         | `uv sync`                 |
| 升级全部依赖       | `uv sync --upgrade`       |
| 运行           | `uv run <cmd>`            |
| 运行单文件脚本      | `uv run script.py`（含内联依赖） |
| 临时跑工具        | `uvx <tool>`              |
| 管理 Python 版本 | `uv python install / pin` |
| 查看依赖树        | `uv tree`                 |
| 构建发布         | `uv build` / `uv publish` |
| 查看已安装工具     | `uv tool list`            |
| 升级已安装工具     | `uv tool upgrade <tool>`   |
| 安装工具         | `uv tool install <tool>`   |
| 卸载已安装工具     | `uv tool uninstall <tool>`   |

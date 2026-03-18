---
description: 项目初始化 — 扫描项目结构并生成 AGENT.md 和规则文件
---

# 项目初始化流程

> 为新项目快速生成 AI 开发配置。类似 CLAUDE.md 的 `/init` 命令。
> 触发方式: `/init`

## 步骤

// turbo
1. **扫描项目结构**
   - 读取项目根目录，识别项目类型和技术栈
   - 检查 `package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod` 等配置文件
   - 识别主要源代码目录、测试目录、配置文件位置
   - 检查是否已有 `AGENT.md` 或 `.agent` 目录

2. **生成 AGENT.md**
   如果项目根目录不存在 `AGENT.md`，基于扫描结果生成，包含：
   - **项目概述**: 根据 README 和配置文件自动提炼
   - **技术栈**: 语言、框架、版本
   - **常用命令**: 构建、测试、lint、启动开发服务器
   - **代码风格**: 根据已有代码推断的命名和格式规范
   - **技能路由表**: 标准路由（指向 `.agent/skills/world_class_coding/SKILL.md`）
   - **工作流路由表**: 所有可用的 `/命令`
   - **强制规则段**: 预填充标准 7 条强制规则
   - **项目规则段**: 空白模板，提示用户填写

   如果已存在 `AGENT.md`，跳过并通知用户。

3. **创建 .agent 目录结构**
   如果不存在 `.agent` 目录，创建标准结构：
   ```
   .agent/
   ├── skills/
   │   └── world_class_coding/
   │       └── SKILL.md
   ├── workflows/
   │   └── (复制所有标准工作流)
   └── rules/
       ├── code-style.md    ← 根据项目技术栈定制
       ├── testing.md       ← 标准测试规则
       └── security.md      ← 安全基线
   ```

   如果已存在，只补充缺失的文件，不覆盖已有文件。

4. **构建代码知识图谱（推荐）**
   - 检查是否已安装 `code-review-graph`（`which code-review-graph`）
   - 如果已安装：
     - 执行 `code-review-graph build`，全量解析项目代码结构
     - 执行 `code-review-graph status`，汇报图谱统计（节点数、边数、语言覆盖）
     - 如无 `.code-review-graphignore` 文件，创建并排除 `node_modules/**`、`dist/**`、`.venv/**`、`__pycache__/**` 等
   - 如果未安装：
     - 提示用户可选安装：`pip install code-review-graph && code-review-graph install`
     - 标记为 [可选]，不阻塞初始化流程
   - 📊 图谱构建后，`/review`、`/debug`、`/new-feature` 等工作流将自动获得影响分析和精准文件选择能力

5. **创建 AGENT.local.md 模板**
   生成 `AGENT.local.md` 模板文件并将其加入 `.gitignore`：
   ```markdown
   # 个人配置覆盖
   > 本文件仅作用于当前用户，不提交 git。
   > 在此添加个人偏好，如 IDE 快捷键、个人编码习惯等。
   ```

// turbo
6. **配置 .gitignore**
   确保以下条目在 `.gitignore` 中：
   - `AGENT.local.md`

7. **输出初始化报告**
   向用户汇报：
   - 已创建的文件列表
   - 自动识别的技术栈信息
   - 建议用户检查并定制的部分
   - 提示用户可使用 `/new-feature` 开始第一个开发任务

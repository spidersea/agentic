---
name: continuous-learning
description: 持续学习系统 — 从会话中自动提取编码模式（本能），带置信度评分，可聚合为正式 Skill。
version: 1.0.0
---

# 持续学习系统（Continuous Learning）

> 灵感来源：[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的 continuous-learning-v2 本能系统。
> 核心理念：Agent 从每次会话中自动提取反复出现的编码模式（"本能"），带置信度评分，跨项目共享，并可聚合为正式 Skill 或 Rule。

## 核心概念

### 本能（Instinct）

本能是从实际开发会话中提取的、尚未升级为正式规则的行为模式。

**数据模型**：

```yaml
# .agent/instincts/pending.yml 中的一条本能
- id: "inst-20260324-001"
  pattern: "修改公共 API 签名后必须搜索并更新所有调用方"
  category: "code-quality"  # code-quality | testing | security | architecture | workflow
  context: "在重构 UserService.getProfile() 时遗漏了 3 个调用方的更新"
  confidence: 3              # 1-5 分
  source_sessions:
    - "2026-03-20: 重构用户模块"
    - "2026-03-22: API v2 迁移"
  created: "2026-03-20"
  last_validated: "2026-03-22"
  status: "active"           # active | promoted | expired | pruned
```

### 置信度评分规则

| 置信度 | 条件 | 动作 |
|---|---|---|
| 1 | 仅 1 次会话出现 | 记录为 pending，不生成规则 |
| 2 | 用户手动确认有价值 | 保留观察 |
| 3 | 2 个不同会话中出现 | 标记为 `[候选]`，在 `/evolve` 中展示 |
| 4 | 3+ 个会话中被验证 | 推荐升级为正式规则 |
| 5 | 5+ 个会话验证 | **自动升级**为 `.agent/rules/` 中的正式规则 |

### 提取范围

⚠️ **仅提取以下类型的模式**：
- 与代码质量相关的行为模式（如「先写测试再实现」）
- 与工程流程相关的模式（如「重构前先建快照测试」）
- 反复出现的 AI 不良行为纠正（如「总是忘记处理边界条件」）
- 项目特有的编码惯例（如「本项目 API 必须返回统一 envelope 格式」）

❌ **不提取**：项目业务逻辑、一次性修复、临时 workaround

## 存储结构

```
.agent/instincts/
├── pending.yml          # 未升级的本能（confidence 1-4）
├── promoted.yml         # 已升级为规则的本能（归档记录）
└── exported/            # 导出文件目录
    └── instincts-{project}-{date}.yml
```

## 提取流程

### 触发时机

1. **手动触发**：用户执行 `/learn` 工作流
2. **`/evolve` 中触发**：步骤 1.5 自动读取 instincts 目录
3. **`/handoff` 中触发**：生成交接备忘录时附带本能提取

### 提取步骤

1. **扫描信号源**
   - 最近的 checkpoint 文件
   - 最近的 handoff 备忘录
   - 当前会话的 git diff（`git log --since="1 day ago" --oneline`）
   - 用户在会话中的纠正行为（如「不要这样做」「应该先…」）

2. **模式识别**
   - 识别反复出现的 AI 不良行为（曾被纠正 2+ 次）
   - 识别反复有效的解决模式
   - 识别项目特有的编码惯例

3. **去重与合并**
   - 与 `pending.yml` 中已有本能比对
   - 语义相同 → 提升 confidence + 追加 source_session
   - 全新模式 → 新建 confidence=1 的本能

4. **输出报告**
   ```
   ## 本能提取报告
   - **新发现**: [N 条新本能]
   - **置信度提升**: [M 条已有本能获得验证]
   - **候选升级** (confidence≥4): [列表]
   - **自动升级** (confidence=5): [列表 + 目标规则文件]
   ```

## 聚合机制（Instinct → Skill / Rule）

当 `/evolve` 执行时：

1. **读取 `.agent/instincts/pending.yml`**
2. **自动升级**：confidence=5 的本能 → 追加到对应的 `.agent/rules/{category}.md`
3. **聚类建议**：3+ 条同 category 的本能 → 建议合并为一个新 Skill 草稿
4. **过期清理**：超过 60 天且 confidence≤2 的本能 → 标记 `expired`，等待 `/instinct prune` 清理

## 导入/导出

### 导出

```bash
# 导出所有活跃本能为 YAML
cat .agent/instincts/pending.yml > .agent/instincts/exported/instincts-$(basename $(pwd))-$(date +%Y%m%d).yml
```

### 导入

读取外部 YAML 文件，与本地本能合并（去重 by pattern 语义匹配），导入的本能 confidence 起始为 1。

## 与现有流程的整合

| 现有流程 | 整合方式 |
|---|---|
| `/evolve` 步骤 1.5 | 读取 instincts 目录，执行升级/聚类/清理（提取委派给 `/learn`） |
| `/checkpoint` | 检查点中附带当前活跃本能数量 |
| `/handoff` | 交接前提示用户运行 `/learn` 保存模式 + 执行 session-end 钩子 |
| `/stress-test` | 评分项中增加「本能系统健康度」参考指标 |
| Phase 1 (Research) | 读取 confidence≥3 的本能，作为设计决策输入 |

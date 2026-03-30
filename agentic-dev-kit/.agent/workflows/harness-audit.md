---
description: 配置健康度审计 — 评估 Agent 配置完整性和效率
---

# 配置健康度审计

> 评估当前 Agent 配置的完整性、一致性和 Token 效率。
> 触发方式: `/harness-audit`
> 在 `/stress-test` 和 `/evolve` 之前运行，作为前置检查。

## 步骤

// turbo
1. **运行基础健康检查**
   ```bash
   bash .agent/scripts/health-check.sh
   ```
   记录退出码和关键指标。

// turbo
2. **路由完整性检查**
   检查 AGENT.md 中所有路由目标是否存在：
   ```bash
   echo "=== 路由完整性 ==="
   # 检查技能路由
   for skill in world_class_coding code-graph spec-driven autoresearch frontend-design polish audit adapt harden continuous-learning hooks-lifecycle config-security skill-creator doc-lookup; do
     [ -f ".agent/skills/$skill/SKILL.md" ] && echo "✅ $skill" || echo "❌ $skill"
   done
   # 检查工作流路由
   for wf in init new-feature debug review test tdd checkpoint handoff resume evolve stress-test context-reset finish spec-propose spec-archive learn instinct hooks config-scan harness-audit skill-create; do
     [ -f ".agent/workflows/$wf.md" ] && echo "✅ $wf" || echo "❌ $wf"
   done
   # 检查 Agent 路由
   for agent in planner reviewer tester security-reviewer doc-updater; do
     [ -f ".agent/agents/$agent.md" ] && echo "✅ $agent" || echo "❌ $agent"
   done
   ```

3. **Token 效率评估**
   评估 Agent 启动时需要加载的文件总量：
   - AGENT.md 行数（目标 < 120 行有效内容）
   - Tier 1 技能总行数
   - 规则文件总行数
   - 指引：如果总 token 预估 > 8000 行，给出精简指引

4. **模型路由指引**
   根据当前任务类型给出模型选择指引：
   | 任务类型 | 指引模型 | 原因 |
   |---|---|---|
   | 配置修改、文案调整 | 轻量模型 | Token 效率 |
   | 功能开发、重构 | 标准模型 | 平衡质量和成本 |
   | 架构设计、安全审计 | 强推理模型 | 需要深度分析 |

5. **输出审计报告**
   ```markdown
   ## 配置健康度审计报告
   - **健康检查**: [退出码 0/1/2]
   - **路由完整性**: [X/Y 文件存在]
   - **Token 预估**: [~N 行需加载]
   - **配置评分**: [A/B/C/D/F]
   - **指引**:
     - [具体优化指引]
   ```

如果阻塞，可求助 `/debug` 流程。

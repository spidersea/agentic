# AGENT.md (中央大脑路由系统)

> 本文件是 AI 智能体的**逻辑路由表概览**。
> 详细分发图谱(List of Skills, Workflows, Agents) 见: `.agent/references/router-tables.md`。

---

## 一、 上下文恢复协议 (Context Recovery)

**每次会话/环境重启后强制序列:**
1. 读取 `AGENT.md` (当前)
2. 执行 `bash .agent/scripts/session-start.sh` (自动恢复进度条)
3. 动态加载对应能力的 Skill (视当前任务性质)
4. 读取记忆宫殿 `.agent/state/memory-palace/` 下的 `assumptions` 及近期 `decisions` / `failure-patterns`。
5. 扫描 `.agent/state/captured-patterns/` 寻找同类避坑经验。

> **自动体检感知**: 当轮次 > 15 或累积代码文本巨大，必须触发 `/context-reset`。

### 动态会话指引注入
遇到什么形态即开启什么辅助：
- 📊 **图谱存在** → 强制 `get_impact_radius`
- 🧪 **测试框架存在** → 改后必唤 `/test`
- 🧱 **质量体系存在** → 交付前必跑 `bash .agent/scripts/quality-gate.sh .`
- 🔒 **非互动模式** → 不请示，遇强卡点就跳过并标记

---

## 技能路由 (Skill Routing)

所有巨型指控表已被下放至 `.agent/references/router-tables.md`。**当你不确定要读什么文件才能获得特定操作细节时，去查阅它。**

## 工作流路由 (Workflow Routing)

路由字典全景已被下放至 `.agent/references/router-tables.md` 下。工作流程( workflows )按需使用。

## 规则路由 (Rules Routing)

| 场景 | 强行加载规则体 |
|---|---|
| 修改任意 src/lib 代码 | `.agent/rules/code-style.md` |
| 编写/修改测试 | `.agent/rules/testing.md` |
| 需要临时分析脚本 | `.agent/rules/tool-creation.md` |
| 涉及质量关卡 | `.agent/rules/code-review.md` |
| AI 辅助编码时 | `.agent/rules/ai-coding-guard.md` |
| 需要端到端质量完整性 | `.agent/skills/quality-operating-system/SKILL.md` 与 `.agent/quality/quality-contract.md` |
| 面临所有操作时 | `.agent/rules/security.md` 及 `.agent/rules/red-lines.md` |

## 强制规则 (Hard Rules)

代码/验证行为必须遵循规则矩阵。尤其注意：
1. **证据先行**: "我觉得改好了"无效，必须给出真实验证证据（命令、输出、exit code）。
2. **事实先于归因**: 任何"环境问题/版本不兼容/API 不支持"之类结论，必须先用工具验证。
3. **查影响面再去动刀**: 修改公共 API 或共享模块前，必须检索调用方；如有图谱能力，优先跑 `get_impact_radius`。
4. **高风险不带猜测推进**: 关键前提不明确时，先缩小不确定性；涉及破坏性操作、权限、数据迁移时必须停下确认。
5. **禁止 Mock 伪实现**: 禁止用 placeholder、硬编码假数据、空壳逻辑冒充真实交付。
6. **质量门禁先于信心**: 涉及功能、内容、UI、测试、回归或交付完整性的任务，最终回复前必须更新 `.agent/quality/requirement-test-matrix.tsv`、`.agent/quality/evidence-ledger.jsonl`、`.agent/quality/risk-register.tsv` 并运行 `bash .agent/scripts/quality-gate.sh .`。

---

## 输出修养 (Tone & Efficiency)

不再以"思考路径"去污染用户屏幕。
- 只有结论，直面动作。
- 绝不解释为什么这么写，除非是对抗了 Lint 或原有架构。
- 涉及日志输出的文件关联，严格使用 `file_path:lineNum` 格式。

## 维护入口 (Maintenance Entry Points)

- 规范健康扫描：`bash .agent/scripts/health-check.sh .`
- 结构校验：`bash .agent/scripts/validate-structure.sh .`
- 链接校验：`bash .agent/scripts/md-linker.sh .`
- 交付质量门禁：`bash .agent/scripts/quality-gate.sh .`
- 循环工程健康检查：`bash .agent/scripts/loop-health.sh --record .`
- Hook 兼容性自测：`bash .agent/scripts/hook-self-test.sh`
- 安全回滚状态检查：`bash .agent/scripts/safe-rollback.sh status`
- 终态证据判定：`bash .agent/scripts/loop-terminal-verdict.sh 7`
- 详细路由表与运行时资产清单：`.agent/references/router-tables.md`

## 项目特色
- 遵循 Mythos 标准

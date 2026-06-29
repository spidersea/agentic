---
description: 上下文编译工作流 — 将分散的工程上下文预编译为结构化、有边界、可审计的上下文包
---

# 上下文编译 (Context Compile)

> 触发方式: `/context-compile [target]`
>
> **来源**: 对照 ATA「codemap」Skill 原始内容校准：
> - codemap 理念：创建 **Agent-facing CodeMap**，不是 human-facing CodeWiki
> - codemap 核心：**渐进式上下文树**，路由 Agent 找到正确的源代码证据
> - codemap 规则：区分 **Confirmed / Inferred / Unknown** 三种事实置信度
> - codemap 模式：支持 **drift-check**（漂移检测：已有 CodeMap 是否已过时）
> 本工作流将工程上下文**预编译**为有边界、可审计的结构化包，
> 让后续工作流（`/new-feature`、`/debug`、`/review`）在启动时加载精确上下文。
>
> **与现有流程关系**:
> - `/context-reset` 负责**清理**污染的上下文 → 本流程负责**重建**干净的上下文
> - `session-start.sh` 自动恢复基本状态 → 本流程在此基础上做**任务级精准编译**
> - 代码图谱（Graphify）提供结构依赖 → 本流程利用图谱做**影响面裁剪**

## 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `target` | `task` / `module:{name}` / `file:{path}` / `full` | `task` |

---

## 步骤

0. **建立终点契约 (Task Contract)**
   > ⛔ **核心防御机制**
   - 在 `task.md` 中创建打卡项，覆盖步骤 1-5，全勾才可完结。

// turbo
1. **扫描上下文源 (Context Source Discovery)**
   识别当前任务需要的上下文来源：

   ```bash
   echo "=== 上下文源扫描 ==="
   # 当前任务契约
   ls task.md openspec/current/*.md 2>/dev/null
   # 活跃文件（最近修改）
   git diff --name-only HEAD~5 HEAD 2>/dev/null | head -20
   # 检查点状态
   ls .agent/state/context-essentials.md 2>/dev/null
   # 已有图谱
   ls .agent/state/code-graph.json 2>/dev/null
   ```

   **上下文源优先级** (从高到低)：
   1. 任务契约 / Spec（必须加载）
   2. 当前变更文件（`git diff`）
   3. 直接依赖文件（调用方/被调用方）
   4. 相关测试文件
   5. 相关规则/技能文件
   6. 历史决策记录

// turbo
2. **依赖图谱分析 (Dependency Graph Analysis)**

   **如果图谱可用**（`code-graph.json` 存在）：
   - 执行 `get_impact_radius(changed_files=[变更文件])` 获取精确依赖树
   - 按跳数裁剪：1 跳（直接依赖）必须加载，2 跳（间接依赖）仅加载签名，≥3 跳丢弃

   **如果图谱不可用**：
   - 用 `grep -rn` 分析 import/require 链（深度限制 2 层）
   - 用 `git log --follow` 识别共变更文件（co-change 分析）
   - 输出简化版依赖树

3. **编译上下文包 (Context Package Assembly)**

   将收集的上下文编译为结构化的 **Context Package**：

   ```markdown
   ## Context Package: [任务名称]
   - **编译时间**: [timestamp]
   - **编译模式**: [task / module / file / full]
   - **Token 预估**: [~N tokens]

   ### 核心上下文 (Must-Load)
   | 文件 | 加载原因 | 行范围 | Token | 置信度 |
   |------|---------|--------|-------|--------|
   | [path] | [任务契约/变更文件/直接依赖] | [全文/L10-L50] | [~N] | [Confirmed/Inferred] |

   > **置信度标记**（对照 codemap Output Rules）：
   > - **Confirmed**: 通过 import/调用链/co-change 证据确认的依赖
   > - **Inferred**: 通过文件名/目录结构推断的依赖（需验证）
   > - **Unknown**: 不确定是否相关，仅在 full 模式加载

   ### 签名上下文 (Signature-Only)
   > 仅加载接口签名，不加载实现
   | 文件 | 导出接口摘要 |
   |------|-------------|
   | [path] | [function signatures / class interfaces] |

   ### 排除上下文 (Explicitly Excluded)
   > 明确标记不应加载的文件及原因
   | 文件 | 排除原因 |
   |------|---------|
   | [path] | [无关模块/历史文件/超大文件] |

   ### 决策上下文 (Decision Context)
   > 影响当前任务的已有决策
   - [决策1: 来源 + 内容]
   ```

   **Token 预算约束**：
   - 核心上下文总计 ≤ 3000 行（约 15K tokens）
   - 签名上下文 ≤ 500 行（约 2.5K tokens）
   - 总计不超过当前会话 Token 上限的 30%

4. **写入并验证 (Write & Validate)**
   - 将 Context Package 写入 `.agent/state/context-package.md`
   - 验证所有引用路径的物理存在性
   - 验证 Token 预估未超预算
   - 如有超预算，自动裁剪低优先级上下文并标记 `[TRIMMED]`

5. **输出编译报告**

   ```markdown
   ## 上下文编译报告
   - **核心文件数**: [N] (共 ~[M] 行)
   - **签名文件数**: [N]
   - **排除文件数**: [N]
   - **Token 效率**: [预估 Token / 全量加载 Token] = [X%]
   - **编译质量**: [完整/有裁剪/有缺失依赖]
   ```

   - **检查终点契约**：确认打卡文件全部 `[x]` 后方可完结。

---

### 自动触发规则

| 场景 | 动作 |
|------|------|
| `/new-feature` Phase 2 开始时 | 自动执行 `context-compile task` |
| `/debug` 启动时 | 自动执行 `context-compile file:{bug文件}` |
| `/context-reset` 完成后 | 建议执行 `context-compile task` 重建 |
| Token 消耗 > 50% 时 | 建议重新编译以裁剪低价值上下文 |
| 已有 context-package.md 但代码已变更 | 执行 `context-compile drift-check` 漂移检测 |

### 漂移检测模式 (drift-check)（对照 codemap）
> codemap 原始 Skill 支持 drift-check 模式：检测已有 CodeMap 是否因代码变更而过时。

当 `target=drift-check` 时：
1. 读取现有的 `.agent/state/context-package.md`
2. 对比 `git diff` 获取编译后到现在的变更文件
3. 检查变更文件是否在核心上下文列表中
4. 如果变更文件影响了核心上下文 → 标记为 **STALE**，建议重新编译
5. 如果变更文件不在核心上下文中 → 标记为 **FRESH**，无需重编译

### 系统禁令 (Red Lines)
❌ 一次性加载超过 5000 行代码（即使"看起来都相关"）
❌ 仅依赖文件名猜测相关性（必须有 import/调用/co-change 证据）
❌ 加载未经验证的路径（先 `ls` / `find` 确认存在）
❌ 编译后不验证 Token 预算

如果阻塞，可求助 `/debug` 流程。

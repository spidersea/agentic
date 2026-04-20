---
name: hooks-lifecycle
description: 会话生命周期钩子 — 自动化状态保存/恢复，减少手动 checkpoint 遗漏
version: 1.0.0
---

# 会话生命周期钩子（Hooks Lifecycle）

> 确保在会话边界、上下文截断前、命令行执行后，状态能够被正确持久化和传递。
> 这不是手动 `/checkpoint` 或 `/handoff` 的替代品，而是安全网。
> 执行脚本与 JSON 配置详情见: `references/hooks-details.md`。

## 钩子点定义 (Hook Points)

1. **`session-start`**: 启动/`resume`时读取过往上下文。
2. **`session-end`**: 退出/`handoff`前强制保存 auto-checkpoint。
3. **`post-tool-use`**: 拦截命令行 exit code。一旦识别失败，计入 `consecutive_failures` 并将压力状态写入 `.escalation-state.json`。
4. **`pre-compact`**: 截断前必须持久化 Escalation 状态，并在 checkpoint 内部生成快照表。
5. **`post-compact`**: 截断后必须立刻重新读取 `.agent/state/context-essentials.md`，复活界碑。
6. **`post-milestone`**: 阶段结束自动唤起 `/checkpoint`。

## 核心规约 (Rules)

- **工具链融合**: 若使用 Claude Code 等 CLI，必须通过 `hooks.json` 挂载对应的 bash 拦截脚本（见 reference）。若是免安装交互模式，则由 Agent **在执行完每一次终端指令后自检执行结果、修改 json**。
- **主动压缩制约 (Proactive Compaction)**: 上下文占用率超 60% 时，或 Autoresearch 一次跑了 >10 个 loop 后，必须手动声明 `/compact`。且必须附带白名单（保留当前目标、压力等级、回归范围）。禁止裸截断！
- **不重置状态**: Compaction 会遗失短时记忆，但严禁以此为借口清零失败计数。计数只听从 `.escalation-state.json`。

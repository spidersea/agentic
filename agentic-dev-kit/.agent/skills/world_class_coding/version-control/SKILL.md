---
name: version-control
description: 专注分支、提交与仓库交互。规范 Agent 的 Git 操作与代码合并。
version: 1.0.0
---

# 版本控制纪律 (Version Control)

> 借鉴极为成熟的自动化行为理念，提升项目的源代码可维护性。
>
> **触发条件**: 任何涉及 `git commit`、分支管理或代码合并的场景自动加载。
> **输入**: 待提交的代码变更 → **输出**: 符合语义化规范的原子提交。

## 1. 提交纪律

- **绝不盲目提交**：执行 `git commit` 前，**必须**先运行 `git status` 和 `git diff` 读取实际的变更内容，禁止凭记忆写摘要
- **语义化提交 (Semantic Commit)**：严格按规范写前缀（如 `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`）
- **高质量描述**：Commit Message 必须描述 "做了什么" 和 "为什么这么做"，而不仅仅是 "修改了文件"
- **原子提交**：如果一个任务包含多个不相关的变更点，应该指引拆分为多次独立提交，而不是混在一个大 commit 中

## 2. 退出条件

> 以下全部满足时，本 Skill 视为执行完成：
- `git status` 显示工作区干净（无未跟踪或未暂存的修改）
- 每个 commit message 包含语义前缀且描述具体变更内容
- 单次 commit 不包含不相关变更（原子性）

❌ 禁止在未运行 `git diff` 的情况下编写 commit message；禁止使用 "update" / "fix bug" 等无意义描述。

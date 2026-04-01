---
name: version-control
description: 专注分支、提交与仓库交互。规范 Agent 的 Git 操作与代码合并。
version: 1.0.0
---

# 版本控制纪律 (Version Control)

> 借鉴极为成熟的自动化行为理念，提升项目的源代码可维护性。

- **绝不盲目提交**：执行 `git commit` 前，**必须**先运行 `git status` 和 `git diff` 读取实际的变更内容，禁止凭记忆写摘要
- **语义化提交 (Semantic Commit)**：严格按规范写前缀（如 `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`）
- **高质量描述**：Commit Message 必须描述 "做了什么" 和 "为什么这么做"，而不仅仅是 "修改了文件"
- **原子提交**：如果一个任务包含多个不相关的变更点，应该指引拆分为多次独立提交，而不是混在一个大 commit 中

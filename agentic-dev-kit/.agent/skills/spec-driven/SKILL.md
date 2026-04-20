---
name: spec-driven
description: 规格驱动开发 (SDD) — 借助 OpenSpec 框架防控 AI 幻觉，确保达成架构共识后再爆代码。
---

# 规格驱动开发技能 (Spec-Driven Development)

> 核心原则：**先达成一致，再编写代码。**
> 没有规格做准绳，AI 助手将迅速陷入幻觉和方向漂移。
> 具体目录规范、GIVEN/THEN 书写格式及阶段融合细节见: `references/openspec-details.md`。

## 1. 核心理念与判别
- **解决痛点**: 需求随对话丢失；改动缺乏回溯路径；不清楚到底“破坏了什么原始设计”。
- **规格的边界**: 规格(Specs)只描述**跨模块外部可观测行为 (Observable Behavior)**。如果修改实现而外面看不出变化，就不该写进规格。
- **降阶与适配**: 默认使用轻量级 Delta Specs。如果功能太小（如单文件修 Bug、改排版），直接修复，**禁止强行启动规格驱动流程**浪费时间。

## 2. 工具链指令
- `/spec:propose <name>` : 针对大功能启动。建立 `changes/<name>/` 目录并预生成 proposal + delta-specs + design + tasks 方案套件。供 Phase 2 人工/AI 对齐。
- `/spec:archive [name]` : 编码完毕且测试通过后触发（入库前）。验证 Tasks 均满足后，将增量 specification 合并进主 `openspec/specs/` 里，原本的更改文件夹退入 archive 作为历史留存。

## 3. 防弹底线
- 所有的 Specs Scenario 必须能通过自动化命令 (CLI / Tests / API Calls) 证明。
- 不允许任何 Agent 仅仅靠阅读代码推导“它原来应该是怎么样的”。代码只是实现，`openspec/specs/` 才是事实根源。如果 specs 有矛盾，必须退回向 User 澄清。

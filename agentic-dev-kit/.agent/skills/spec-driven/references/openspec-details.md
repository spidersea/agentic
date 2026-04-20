---
description: 规格驱动开发 (OpenSpec) 文件夹结构与格式细节 (从 SKILL.md 下沉)
---

# 规格层细节协议 (OpenSpec Details)

## 1. 结构与生命周期 (Directory & Lifecycle)

```
openspec/
├── specs/                          ← 主规格（单一事实来源）
│   └── auth/spec.md
├── changes/                        ← 活跃变更
│   └── add-dark-mode/
│       ├── proposal.md             ← Why+Scope
│       ├── specs/ui/spec.md        ← Delta specs (变什么)
│       ├── design.md               ← How
│       └── tasks.md                ← Steps (SOP Phase 2 契约)
└── changes/archive/                ← /spec:archive 后移动至此
```

## 2. 行为规格书写格式 (Spec Format)

只描述**外部可见行为 (Observable Behavior)**，禁止内部变量名与框架选择。

```markdown
### Requirement: 用户认证
系统 SHALL/MUST/SHOULD/MAY (严格区分 RFC 2119 关键词)。

#### Scenario: 空闲超时
- GIVEN 一个已认证的会话
- WHEN 30 分钟内无操作
- THEN 会话被标记为无效
- AND 用户必须重新认证
```

## 3. 三维验证 (Three-Dimensional Verification)

在 `tasks.md` 做完且执行 `/spec:archive` 前，需进行最后核验：
- **完整性 (Completeness)**: Requirements 全覆盖，边界测满。
- **正确性 (Correctness)**: 退出码与期望状态一致。
- **一致性 (Coherence)**: 架构决策(design.md)切实反映在代码结构里。

## 4. 与四阶段 SOP 融合地图
- `Phase 1 调研` 触发 `/spec:propose` 建立四件套。
- `Phase 2 契约` 对齐 delta specs 的 scenario 和 tasks.md。
- `Phase 3 编码` 遵循任务清单。
- `Phase 4 验证` 三维验证完毕后触发 `/spec:archive`。

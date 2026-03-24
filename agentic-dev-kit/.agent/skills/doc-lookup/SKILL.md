---
name: doc-lookup
description: 文档检索 — 结构化的 API 文档和项目文档检索流程
version: 1.0.0
---

# 文档检索技能（Documentation Lookup）

> 灵感来源：[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的 `documentation-lookup` 和 `search-first` 技能。
> 核心理念：Phase 1（Research）的增强——在编码前进行结构化的文档检索，确保使用正确的 API 和最佳实践。

## 使用场景

- 使用不熟悉的 API 或库之前
- 遇到报错需要查阅官方文档
- 评估是否引入新依赖
- 确认项目内部 API 的正确使用方式

## 检索流程

### 1. 项目内文档检索

优先查找项目内部的文档资源：

```bash
# 查找项目文档
find . -name "README.md" -o -name "CHANGELOG.md" -o -name "API.md" -o -name "*.api.md" 2>/dev/null | head -10

# 查找 API 注释/docstring
grep -rn "\/\*\*" --include="*.ts" --include="*.js" --include="*.py" | head -20

# 查找 OpenAPI/Swagger 定义
find . -name "openapi.*" -o -name "swagger.*" 2>/dev/null
```

### 2. 依赖文档检索

查阅项目依赖的 API 文档：

1. **识别相关依赖**：从 `package.json` / `pyproject.toml` / `go.mod` 中找到目标库
2. **查找文档来源**：
   - npm: `https://www.npmjs.com/package/{pkg}`
   - PyPI: `https://pypi.org/project/{pkg}`
   - Go: `https://pkg.go.dev/{module}`
3. **阅读关键部分**：API 参考、Getting Started、Migration Guide

### 3. 上下文聚合

将检索结果聚合为可用的上下文：

```markdown
## 文档检索结果: [主题]
- **来源**: [项目内/npm/PyPI/官方文档]
- **关键 API**:
  - `functionName(params)` → 返回值
  - 使用示例
- **注意事项**: [版本兼容性、弃用警告等]
- **参考链接**: [URL]
```

## 与 Phase 1 的整合

在 SOP Phase 1（Research）中，当涉及外部 API 或不熟悉的模块时：

1. **先 doc-lookup** → 确认 API 正确用法
2. **再设计方案** → 基于文档而非猜测
3. **记录到技术规格** → 引用文档链接

> ⚠️ 原则：**永远不要猜测 API 行为**。如果文档不清楚，标记为 `[不确定]` 并向用户确认。

---
description: 通用代码风格规则 — 命名、导入、格式化基线
paths:
  - "src/**/*.{ts,tsx,js,jsx,py}"
  - "lib/**/*.{ts,py}"
---

# 代码风格规则

> 当 Agent 操作匹配 `paths` 的文件时，本规则自动生效。

## 命名规范
- 变量和函数：`camelCase`（JS/TS）或 `snake_case`（Python）
- 类和组件：`PascalCase`
- 常量：`UPPER_SNAKE_CASE`
- 文件名：`kebab-case`（JS/TS）或 `snake_case`（Python）
- 布尔变量以 `is`/`has`/`should`/`can` 开头

## 导入规范
- 优先使用 ES 模块语法（`import/export`），不使用 `require`
- 优先使用解构导入（`import { foo } from 'bar'`）
- 导入顺序：标准库 → 第三方 → 项目内部，各组之间空一行

## 格式化
- 缩进：2 空格（JS/TS）或 4 空格（Python）
- 行宽上限：100 字符
- 使用尾逗号（trailing commas）
- 字符串统一使用单引号（JS/TS）或双引号（Python）

## 函数设计
- 单个函数不超过 50 行，超出时拆分
- 函数参数不超过 4 个，超出时使用 options 对象
- 避免魔法数字，全部提取为命名常量

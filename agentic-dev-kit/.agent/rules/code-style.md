---
description: 通用代码风格规则 — 命名、导入、格式化基线
paths:
  - [ ] "src/**/*.{ts,tsx,js,jsx,py}"
  - [ ] "lib/**/*.{ts,py}"
  - [ ] "**/*.go"
  - [ ] "src/**/*.rs"
---

# 代码风格规则

> 当 Agent 操作匹配 `paths` 的文件时，本规则自动生效。

## 命名规范
- [ ] 变量和函数：`camelCase`（JS/TS）或 `snake_case`（Python/Go/Rust）
- [ ] 类和组件：`PascalCase`
- [ ] 常量：`UPPER_SNAKE_CASE`（JS/TS/Python）；Go 用包级导出变量（`PascalCase`）
- [ ] 文件名：`kebab-case`（JS/TS）或 `snake_case`（Python/Go/Rust）
- [ ] 布尔变量以 `is`/`has`/`should`/`can` 开头

## 导入规范
- [ ] 优先使用 ES 模块语法（`import/export`），不使用 `require`
- [ ] 优先使用解构导入（`import { foo } from 'bar'`）
- [ ] 导入顺序：标准库 → 第三方 → 项目内部，各组之间空一行
- [ ] **Go**: 分组顺序 stdlib → external → internal，使用 `goimports` 管理
- [ ] **Rust**: 分组顺序 std → external crates → crate-internal，`use` 内置 rustfmt 管理

## 格式化
- [ ] 缩进：2 空格（JS/TS）或 4 空格（Python/Go/Rust）
- [ ] 行宽上限：100 字符（Go: 120 字符 / gofmt 默认）
- [ ] 使用尾逗号（trailing commas）
- [ ] 字符串统一使用单引号（JS/TS）或双引号（Python/Go/Rust）

## 函数设计
- [ ] 单个函数不超过 50 行，超出时拆分
- [ ] 函数参数不超过 4 个，超出时使用 options 对象（Go: struct；Rust: struct/builder 模式）
- [ ] 避免魔法数字，全部提取为命名常量

## 错误处理规范
- [ ] **Go**: 所有 error 返回值必须显式处理，不可用 `_` 忽略（安全相关函数无一例外）
- [ ] **Rust**: 使用 `?` 运算符传播 Result，生产代码禁止 `.unwrap()` / `.expect()`（除非有证明不会失败的注释）
- [ ] **Python**: 禁止裸 `except:`，必须捕获具体异常类型
- [ ] **JS/TS**: async 函数必须 await，Promise 必须有 `.catch` 或 try/catch



## 自动化合规验证
可以使用如下命令验证当前环境状态：
```bash
bash .agent/scripts/health-check.sh .
```

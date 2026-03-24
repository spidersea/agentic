---
description: 从 Git 历史生成项目编码规范技能 — 新项目冷启动
---

# Git 历史技能生成

> 从项目 Git 提交历史中提取编码模式，生成 SKILL.md 草稿。
> 触发方式: `/skill-create`
> 前置技能: `.agent/skills/skill-creator/SKILL.md`

## 步骤

// turbo
1. **扫描项目基本信息**
   ```bash
   echo "=== 项目概览 ==="
   # 技术栈检测
   ls package.json pyproject.toml go.mod Cargo.toml pom.xml 2>/dev/null
   # 目录结构
   find . -maxdepth 2 -type d ! -path './.git*' ! -path './node_modules*' ! -path './.agent*' | head -30
   # Commit 数量
   git log --oneline | wc -l
   # 贡献者
   git shortlog -sn --no-merges | head -5
   ```

// turbo
2. **提取高频修改文件**
   ```bash
   echo "=== 高频修改文件（热点）==="
   git log -100 --no-merges --name-only --format='' | sort | uniq -c | sort -rn | head -20
   ```

// turbo
3. **分析 Commit 风格**
   ```bash
   echo "=== Commit 风格 ==="
   git log -50 --format='%s' --no-merges | head -20
   ```

4. **提取代码模式**
   阅读高频修改文件，识别：
   - 命名惯例（文件、函数、变量）
   - 目录组织模式
   - 错误处理模式
   - 测试文件结构
   - 常用工具库使用方式

5. **生成 SKILL.md 草稿**
   将提取的模式组织为标准 SKILL.md 格式：
   ```markdown
   ---
   name: [项目名]-conventions
   description: [项目名] 项目编码规范（从 Git 历史自动提取）
   version: 0.1.0-draft
   ---
   # [项目名] 编码规范
   > ⚠️ 本文件由 /skill-create 自动生成，需人工审核
   ## 命名惯例
   ...
   ## 目录结构
   ...
   ## 编码模式
   ...
   ## 测试约定
   ...
   ```

6. **可选：生成本能数据**
   如果用户指定 `--instincts`，将提取的模式同时写入 `.agent/instincts/pending.yml`（confidence=2）。

7. **人工审核提示**
   - 将草稿保存到 `.agent/skills/[项目名]-conventions/SKILL.md`
   - 提示用户审核并修改
   - 确认后更新 AGENT.md 路由表

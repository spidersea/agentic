---
description: 从 Git 历史生成项目编码规范技能 — 新项目冷启动，含编码规范自动提取
---

# Git 历史技能生成

> 从项目 Git 提交历史中提取编码模式，生成 SKILL.md 草稿。
> 触发方式: `/skill-create`
> 前置技能: `.agent/skills/skill-creator/SKILL.md`

## 步骤

0. **建立终点契约 (Task Contract)**
   > ⛔ **核心防御机制：对抗注意力衰减与产物断裂**
   - 收到 `/skill-create` 的**第一秒钟**，你必须立即使用写文件工具，在工作区创建一个实体打卡文件（或整合进 `task.md` 中），强制列出本工作流的所有阶段作为 `[ ] TODO` 打卡项。
   - **终点拦截规则**：这是一个强状态契约。除非你亲手将该磁盘文件中的所有检查项全部标记为 `[x]`，否则**绝对不可**自行宣告任务完成。每完成下面的一步，你必须去物理更新该文件。

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

4.5 **编码规范自动提取 (Code Style Auto-Extraction)**
   > 对照 ATA「repo-code-style-extractor v0.3.0」原始内容校准：
   > - **证据驱动**: 每条结论必须≥3 个独立文件样本，附 `path:line` 引用
   > - **置信度分级**: dominant(≥70%) / mixed(30-70%) / minor(<30%)
   > - **仅输出仓库私有写法**: 不重复通用语言规范，只记录"这个仓库实际怎么写"
   > - **7 轴提取**: 分层架构/命名习惯/日志规范/异常处理/依赖与扩展/单元测试/注释文档
   > - **产物**: CODE_STYLE.md (人读) + guidelines.json (AI 注入, ≤8KB, 3天TTL)

   **静态分析提取**:
   ```bash
   echo "=== 编码风格静态提取 ==="
   # 缩进风格检测
   head -100 $(git ls-files '*.ts' '*.js' '*.py' '*.go' '*.java' 2>/dev/null | head -10) 2>/dev/null | grep -cP '^\t' && echo "TAB风格" || echo "空格风格"
   # 引号风格（JS/TS）
   grep -rn "import\|require" --include='*.ts' --include='*.js' . 2>/dev/null | head -20
   # 命名风格抽样
   grep -rn 'function \|const \|let \|var \|def \|func ' --include='*.ts' --include='*.js' --include='*.py' --include='*.go' . 2>/dev/null | head -30
   # Lint/Prettier 配置（如存在）
   ls .eslintrc* .prettierrc* pyproject.toml .editorconfig tsconfig.json 2>/dev/null
   ```

   **7 轴结构化提取**（对照 repo-code-style-extractor 的核心轴）:
   | 轴 | 提取内容 | 检测方法 |
   |----|---------|---------|
   | 1. 分层架构 | 项目层级(Controller/Service/Manager/DAO) | 扫描目录结构 + 类名后缀 |
   | 2. 命名习惯 | 类名后缀、方法名前缀、包名结构 | `grep -rn` 统计高频模式 |
   | 3. 日志规范 | 日志门面、固定字段、错误日志格式 | 扫描 log/logger 引用 |
   | 4. 异常处理 | 私有异常基类、异常码组织 | 扫描 Exception/Error 类 |
   | 5. 依赖与扩展 | 核心技术栈版本、自定义注解 | 解析 pom.xml/package.json |
   | 6. 单元测试 | 测试框架、命名后缀、基类 | 扫描 test 目录结构 |
   | 7. 注释与文档 | JavaDoc/TSDoc 覆盖率、TODO格式 | 统计注释覆盖率 |

   **证据规则**（对照原始 Skill 核心原则）:
   - 每条风格结论**必须** ≥3 个独立文件样本
   - 每个样本附 `相对路径:行号` 引用
   - 标注置信度: `dominant`(≥70%) / `mixed`(30-70%) / `minor`(<30%)
   - **严禁**: "猜测/合理推断/根据 XX 框架习惯应该是" 等无证据措辞
   - 无法采到 ≥3 样本的结论必须删除或标注「待人工确认」

   **仅私有写法过滤**（对照原始 Skill 输出门槛）:
   一条风格结论只有满足以下任一才进入正文：
   - 该写法是**仓库自定义的工具类/注解/基类/扩展点**
   - 该写法在通用规范中有多种选项，但本仓库**统一选了其中一种**
   - 该写法**违反或扩展了**业界通用规范（标记为"本仓库特有约定"）
   
   **不进入正文的**: 纯语言规则(如"类名 PascalCase")、纯框架默认、人尽皆知的最佳实践

   **Lint 配置反向解析**:
   - 如存在 `.eslintrc` / `.prettierrc` / `pyproject.toml [tool.ruff]`，自动解析为可读规范
   - 将 lint 规则翻译为自然语言描述写入 SKILL.md
   - 示例：`"semi": "always"` → "所有语句必须以分号结尾"

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
   - **检查终点契约**：确认已将物理打卡文件中的所有 [ ] 转化为 [x]，方可宣告 `/skill-create` 流程完结。

如果阻塞，可求助 `/debug` 流程。

# 贡献指南 (Contributing Guide)

感谢你对 Agentic Dev Kit 的关注！欢迎提交 Issue、PR 或建议。

## 🚀 快速开始

```bash
# 1. Fork 并 clone
git clone https://github.com/YOUR_USERNAME/agentic.git
cd agentic/agentic-dev-kit

# 2. 验证环境
make test        # 确保所有测试通过
make validate    # 确保框架结构完整
```

## 📝 提交 Issue

- **Bug 报告**: 使用 `.github/ISSUE_TEMPLATE/bug_report.md` 模板
- **功能请求**: 使用 `.github/ISSUE_TEMPLATE/feature_request.md` 模板
- **问题讨论**: 直接创建 Issue

## 🔧 提交 PR

### 修改规范文件（Skill / Workflow / Rule）

1. 确保修改后 `make validate` 通过（17/17）
2. 如果新增 Skill，必须包含 YAML frontmatter（`name` + `description`）
3. 如果新增 Workflow，必须包含 `description` frontmatter
4. 运行 `make stress-test`，确保评分不低于当前基线

### 修改脚本（.sh）

1. 确保 `make lint` 通过（bash -n 语法检查）
2. 确保 `make test` 全部通过
3. 新脚本必须有对应的测试文件在 `tests/` 下

### Commit 规范

使用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
feat: 新增功能
fix: 修复 bug
docs: 文档变更
test: 测试相关
refactor: 重构
chore: 构建/工具变更
```

## 📏 代码标准

- Shell 脚本使用 `set -uo pipefail`
- 所有脚本支持 macOS + Linux（注意 `head -n -1` 等不兼容命令）
- SKILL.md / Workflow 必须有 YAML frontmatter
- 中文文档优先，技术术语可用英文

## 🧪 验证清单

提交 PR 前请确保：

```bash
make test         # ✅ 4/4 通过
make validate     # ✅ 17/17 通过
make stress-test  # ✅ 评分 ≥ 80
make lint         # ✅ 0 errors
```

---
description: 完成开发分支 — 标准化的分支收尾与清理流程
---

# 分支完成流程

> 触发方式: `/finish`
>
> 在所有任务完成、测试通过后，引导标准化的分支收尾操作。
>
> **与 `/autoresearch:ship` 的区分**：`/finish` 专注于 git 分支收尾（merge/PR/keep/discard + worktree 清理）；对于需要 CI/CD 触发、容器部署、内容发布等复杂发布场景，请使用 `/autoresearch:ship`。

## 前置条件

- 全量测试已通过（0 failures）
- 工作流闭环验收已完成

## 步骤

1. **验证测试状态**
   运行项目测试套件，确认全部通过：
   ```bash
   # 根据项目使用对应命令
   npm test / pytest / cargo test / go test ./...
   ```
   如果测试失败，**停止**，不可继续分支操作。修复后重新运行。

2. **文档同步检查**
   在分支操作前，确保文档与代码变更保持一致：
   ```bash
   git diff main --name-only 2>/dev/null || git diff origin/main --name-only
   ```
   - 读取项目中所有 `.md` 文档文件（README、CHANGELOG、docs/ 等）
   - 对照变更文件列表，检查以下内容是否需要同步：
     - **README**: 目录结构、命令列表、安装步骤中是否有引用已改名/新增/删除的文件
     - **CHANGELOG**: 是否需要记录本次变更（新功能/breaking change）
     - **API 文档**: 公共接口变更是否已同步
   - **自动修复**（无需用户确认）：README 目录结构树、命令表中的新命令/删除命令
   - **询问用户**（有主观判断成分）：版本号更新、CHANGELOG 内容措辞、重要架构变更描述
   - 如果无文档需要更新，跳过此步骤

3. **确定基础分支**
   ```bash
   git log --oneline -1 origin/main 2>/dev/null || git log --oneline -1 origin/master
   ```
   向用户确认："本分支基于 `main` 分支，是否正确？"

3. **展示选项**
   向用户展示以下 4 个选项：
   ```
   开发完成。请选择收尾方式：

   1. 本地合并到 <基础分支>
   2. 推送并创建 Pull Request
   3. 保留分支不动（稍后处理）
   4. 丢弃本次工作
   ```

4. **执行选择**

   **选项 1: 本地合并**
   ```bash
   git checkout <基础分支>
   git pull
   git merge <功能分支>
   # 运行测试确认合并后仍通过
   <测试命令>
   git branch -d <功能分支>
   ```

   **选项 2: 推送并创建 PR**
   ```bash
   git push -u origin <功能分支>
   # 如果 gh CLI 可用
   gh pr create --title "<标题>" --body "## 变更摘要\n- <变更说明>\n\n## 测试\n- [x] 全量测试通过"
   ```

   **选项 3: 保留分支**
   报告："保留分支 `<分支名>`。Worktree 路径: `<路径>`。"
   不执行任何清理。

   **选项 4: 丢弃**
   ⚠️ **必须先确认**：
   ```
   这将永久删除：
   - 分支 <名称>
   - 所有提交记录
   - Worktree（如有）

   输入 'discard' 确认。
   ```
   等待用户输入确切的 `discard` 后才执行：
   ```bash
   git checkout <基础分支>
   git branch -D <功能分支>
   ```

5. **清理 Worktree（选项 1、2、4）**
   如果使用了 git worktree：
   ```bash
   git worktree list | grep <功能分支>
   git worktree remove <worktree路径>
   ```
   选项 3 不清理 worktree。

## 速查表

| 选项 | 合并 | 推送 | 保留 Worktree | 清理分支 |
|---|---|---|---|---|
| 1. 本地合并 | ✓ | - | - | ✓ |
| 2. 创建 PR | - | ✓ | ✓ | - |
| 3. 保留 | - | - | ✓ | - |
| 4. 丢弃 | - | - | - | ✓（强制） |

## 禁止事项

- ❌ 测试未通过时继续操作
- ❌ 合并后不验证测试
- ❌ 丢弃工作前不确认
- ❌ force-push（除非用户明确要求）

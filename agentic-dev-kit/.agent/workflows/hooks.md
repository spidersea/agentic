---
description: 三层钩子管理 — Pre/Post 工具执行钩子 + 会话生命周期钩子
---

# 三层钩子体系 (Hook System)

> 借鉴 Claude Code 的 `HookRunner` 设计，将钩子从「会话生命周期管理」扩展为**工具执行前后拦截 + 会话生命周期**三层体系。
> 触发方式: `/hooks [子命令]`
> 前置技能: `.agent/skills/hooks-lifecycle/SKILL.md`

## 钩子层级架构

```
Layer 1: Pre-Tool Use     — 工具执行前拦截（范围检查、危险命令扫描）
Layer 2: Post-Tool Use    — 工具执行后验证（diff 守护、测试门禁、exit code 检查）
Layer 3: Lifecycle         — 会话生命周期（session-start / session-end / auto-compact）
```

### Layer 1: Pre-Tool Use 钩子

> **触发时机**: 任何工具调用（文件写入、shell 执行、搜索等）**执行前**。
> **语义**: exit 0 = 允许, exit 2 = 拒绝, 其他 = 警告但允许。

**内置检查项（Agent 内部执行，非外部脚本）：**
- 📋 **范围检查**: 当前操作是否在任务契约定义的文件范围内？超出范围 → 警告用户
- 🛡️ **危险命令扫描**: Shell 命令是否包含 `rm -rf`、`chmod 777`、`curl | bash`、`> /dev/sd`、`mkfs`、`dd if=` 等危险模式？匹配 → 拒绝并上报
- 🔒 **权限检查**: 操作所需权限级别是否超过当前会话权限？超出 → 请求提权（参考 `.agent/rules/security.md` 工具权限矩阵）
- 📁 **路径沙箱**: 文件操作是否在项目目录内？访问 `/etc`、`/usr`、`~/.ssh` 等敏感路径 → 拒绝

**可选外部脚本钩子（如存在则执行）：**
```bash
# .agent/hooks/pre-tool/scope-check.sh
# 通过环境变量接收上下文:
#   HOOK_EVENT=PreToolUse
#   HOOK_TOOL_NAME=write_file
#   HOOK_TOOL_INPUT='{"path": "src/main.py", "content": "..."}'
# 通过 stdin 接收 JSON payload
# 通过 exit code 控制流: 0=允许, 2=拒绝
# 通过 stdout 返回 feedback（注入回对话流）
```

### Layer 2: Post-Tool Use 钩子

> **触发时机**: 工具执行**完成后**，结果返回到对话流**之前**。
> **语义**: exit 2 = 标记结果为错误, 0 = 正常通过。

**内置检查项：**
- 📊 **Exit Code 检查**: Shell 命令返回非零 → 主动上报而非忽略
- 📝 **变更审计**: 文件写入后，确认变更文件数 ≤ 预期值
- 🧪 **测试门禁（可选）**: 如果修改了 `src/` 下的文件，提醒运行相关测试
- 📂 **Diff 守护**: 检查是否有意外修改了不在任务范围内的文件

**可选外部脚本钩子：**
```bash
# .agent/hooks/post-tool/diff-guard.sh
# 额外环境变量:
#   HOOK_TOOL_OUTPUT='...'
#   HOOK_TOOL_IS_ERROR=0
```

### Layer 3: Lifecycle 钩子（保持现有功能）

> 会话生命周期事件。

| 事件 | 脚本 | 触发时机 |
|---|---|---|
| 会话开始 | `.agent/scripts/session-start.sh` | 新会话开始或上下文恢复后 |
| 会话结束 | `.agent/scripts/session-end.sh` | 会话即将结束时 |
| 自动压缩 | 内置（无外部脚本） | 满足自动压缩条件时 |

---

## 子命令

### `/hooks status` — 查看钩子状态

// turbo
1. 检查钩子脚本:
   ```bash
   echo "=== 钩子状态 ==="
   echo ""
   echo "--- Layer 3: Lifecycle ---"
   for script in session-start.sh session-end.sh; do
     if [ -f ".agent/scripts/$script" ]; then
       echo "✅ $script — 存在 ($(wc -l < ".agent/scripts/$script") 行)"
     else
       echo "❌ $script — 缺失"
     fi
   done
   echo ""
   echo "--- Layer 1/2: Pre/Post Tool Hooks ---"
   for hook_dir in pre-tool post-tool; do
     if [ -d ".agent/hooks/$hook_dir" ]; then
       count=$(find ".agent/hooks/$hook_dir" -name "*.sh" | wc -l | tr -d ' ')
       echo "📁 $hook_dir/: ${count} 个外部钩子"
       find ".agent/hooks/$hook_dir" -name "*.sh" -exec echo "   └─ {}" \;
     else
       echo "📁 $hook_dir/: 未配置外部钩子（使用内置检查）"
     fi
   done
   echo ""
   # 检查 auto-checkpoint 目录
   if [ -d ".agent/auto-checkpoints" ]; then
     echo "📁 auto-checkpoints: $(ls -1 .agent/auto-checkpoints/*.md 2>/dev/null | wc -l | tr -d ' ') 个"
   else
     echo "📁 auto-checkpoints: 目录不存在"
   fi
   ```

2. 向用户展示状态报告

---

### `/hooks run <钩子名>` — 手动触发钩子

// turbo
根据参数执行对应脚本：
```bash
# session-start
bash .agent/scripts/session-start.sh

# session-end
bash .agent/scripts/session-end.sh
```

---

### `/hooks clean` — 清理 auto-checkpoint

// turbo
```bash
# 只保留最近 5 个
ls -1t .agent/auto-checkpoints/auto-checkpoint-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
echo "✅ 已清理旧的 auto-checkpoint"
```

---

### `/hooks init` — 初始化外部钩子目录

// turbo
```bash
mkdir -p .agent/hooks/pre-tool .agent/hooks/post-tool
echo "✅ 已创建 .agent/hooks/pre-tool/ 和 .agent/hooks/post-tool/"
echo "   将 .sh 脚本放入对应目录即可激活外部钩子"
echo "   钩子协议: exit 0=允许, exit 2=拒绝, stdout=feedback"
```

如果阻塞，可求助 `/debug` 流程。

---
description: 钩子管理 — 查看钩子状态、手动触发、调试钩子行为
---

# 钩子管理

> 管理会话生命周期钩子的行为和状态。
> 触发方式: `/hooks [子命令]`
> 前置技能: `.agent/skills/hooks-lifecycle/SKILL.md`

## 子命令

### `/hooks status` — 查看钩子状态

// turbo
1. 检查钩子脚本:
   ```bash
   echo "=== 钩子状态 ==="
   for script in session-start.sh session-end.sh; do
     if [ -f ".agent/scripts/$script" ]; then
       echo "✅ $script — 存在 ($(wc -l < ".agent/scripts/$script") 行)"
     else
       echo "❌ $script — 缺失"
     fi
   done
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

如果阻塞，可求助 `/debug` 流程。

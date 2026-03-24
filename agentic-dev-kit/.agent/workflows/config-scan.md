---
description: Agent 配置安全扫描 — 检测规范文件中的安全风险
---

# 配置安全扫描

> 扫描 Agent 配置文件（AGENT.md、rules、skills、workflows、agents）中的安全风险。
> 触发方式: `/config-scan`
> 前置技能: `.agent/skills/config-security/SKILL.md`
> ⚠️ 本工作流仅关注**安全维度**。配置完整性和 Token 效率 → `/harness-audit`

## 步骤

// turbo
1. **收集扫描目标**
   ```bash
   echo "=== 扫描目标 ==="
   echo "--- AGENT.md ---"
   ls -la AGENT.md 2>/dev/null
   echo "--- Rules ---"
   ls -la .agent/rules/*.md 2>/dev/null
   echo "--- Skills ---"
   find .agent/skills -name "SKILL.md" 2>/dev/null
   echo "--- Workflows ---"
   ls -la .agent/workflows/*.md 2>/dev/null
   echo "--- Agents ---"
   ls -la .agent/agents/*.md 2>/dev/null
   echo "--- Scripts ---"
   ls -la .agent/scripts/*.sh 2>/dev/null
   ```

// turbo
2. **密钥泄露扫描**
   ```bash
   echo "=== 密钥泄露扫描 ==="
   grep -rnE '(sk-[a-zA-Z0-9]{20,}|api_key\s*=|apiKey\s*:|OPENAI_API_KEY\s*=|Bearer [a-zA-Z0-9]{20,}|password\s*=\s*["\x27][^"\x27]+|aws_secret_access_key|AKIA[A-Z0-9]{16}|postgres://[^@]+@|mysql://[^@]+@|mongodb://[^@]+@)' \
     AGENT.md .agent/rules/*.md .agent/workflows/*.md .agent/scripts/*.sh 2>/dev/null \
     && echo "⚠️ 发现潜在密钥泄露" \
     || echo "✅ 无密钥泄露"
   # 扫描 skills
   find .agent/skills -name "SKILL.md" -exec grep -lE '(sk-|api_key|password=|Bearer )' {} \; 2>/dev/null
   ```

3. **权限过松检测**
   阅读 `.agent/agents/*.md`（如存在），检查：
   - 每个 Agent 的 `tools` 列表是否最小化
   - 是否有只需 `Read` 权限的 Agent 却配了 `Execute`
   
   阅读 `.agent/workflows/*.md` 和 `.agent/scripts/*.sh`，检查：
   - 是否有无限制的 `rm -rf`（无路径限定）
   - 是否有 `curl | bash` 或 `eval` 处理用户输入
   - 是否有 `sudo` 操作

4. **提示注入风险检查**
   检查 workflow 和 skill 文件中：
   - 是否有用户输入直接插入到 shell 命令中（如 `bash -c "$USER_INPUT"`）
   - 工作流是否缺少输入校验步骤

5. **安全相关的规则冲突检测**
   - 读取所有 `.agent/rules/*.md` 的规则
   - 识别安全规则是否被其他规则的例外条件绕过
   - 检查安全规则是否为全局生效（无 `paths` 限定）
   - ℹ️ 通用规则冲突检测 → `/evolve` 步骤 5

6. **评分并输出报告**
   按照 SKILL.md 中的评分标准，计算安全评级（A-F），输出结构化报告。

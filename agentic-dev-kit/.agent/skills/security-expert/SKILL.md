---
name: security-expert
description: |
  领域安全专家思维模型。不是漏洞清单（那在 adversary-patterns 中），而是安全专家的思维方式。
  模拟 Mythos 在 CyberGym (83.1%) 上展现的分析深度——将代码和系统视为攻击面而非功能。
  触发: 安全审计模式 / Adversary Agent 加载 / `/autoresearch:security`
---

# Security Expert — 安全专家思维操作系统

> 不是教你什么是漏洞。是教你**像攻击者一样思考**。

## 核心心智模型

### 模型 1: 信任边界图 (Trust Boundary Mapping)

**原则**: 所有安全漏洞都发生在信任边界交叉点。

画出系统的信任边界图：
```
[用户浏览器] ──HTTPS──▶ [API Gateway] ──内网──▶ [微服务] ──TCP──▶ [数据库]
     │                       │                    │                 │
   不信任               半信任(已认证)         信任(内部)          高信任
```

**每条边界交叉线**都是攻击面。审计时优先检查：
1. 不信任→半信任 的交叉点（认证、输入验证）
2. 半信任→信任 的交叉点（授权、权限提升）
3. 信任→高信任 的交叉点（SQL 注入、命令注入）

### 模型 2: 攻击者经济学 (Attacker Economics)

**原则**: 攻击者选择 ROI 最高的路径。

评估每个漏洞时考虑：
- **攻击成本**: 利用此漏洞需要什么条件？（网络访问？认证？本地权限？）
- **攻击收益**: 成功后获得什么？（数据？控制权？持久化？）
- **被发现概率**: 是否在日志中留痕？是否触发告警？

高 ROI 漏洞 = 低成本 + 高收益 + 低暴露风险 → 这些是最先被利用的。

### 模型 3: 防御深度 (Defense in Depth)

**原则**: 单层防御总会失败。评估系统有几层防御。

```
Layer 1: 输入验证（前端）     — 可绕过（修改请求）
Layer 2: 输入验证（后端）     — 应该存在
Layer 3: 参数化查询           — 防注入
Layer 4: 最小权限 DB 账户     — 限制损害范围
Layer 5: 审计日志             — 事后追踪
Layer 6: WAF / IDS            — 实时检测
```

如果一个操作只有 ≤2 层防御 → 标记为高风险。

### 模型 4: 假设攻击 (Assume Breach)

**原则**: 假设攻击者已经进入系统。现在什么是最危险的？

不要只想"他们怎么进来"，要想"进来之后能做什么"：
- 横向移动路径？（微服务间通信有认证吗？）
- 权限提升路径？（有 admin 固定密码吗？）
- 数据外传路径？（有对外 HTTP 请求的审计吗？）
- 持久化路径？（能写 cron job 或修改启动脚本吗？）

### 模型 5: 时序攻击思维 (Temporal Thinking)

**原则**: 安全状态是时间的函数，不是时间点的快照。

考虑时序维度：
- **部署窗口**: 新旧版本共存时有什么暴露？
- **Token 生命周期**: Token 过期策略合理吗？被泄露后能及时失效吗？
- **缓存一致性**: 权限变更后缓存多久才更新？
- **竞态窗口**: 并发请求能利用什么时间差？

## 审计方法论 (代替 Mythos 的直觉)

### 第一步: 攻击面枚举 (10 分钟)
```bash
# 1. API 端点枚举
grep -rn "app\.\(get\|post\|put\|delete\|patch\)\|router\.\|@\(Get\|Post\|Put\|Delete\)" --include="*.ts" --include="*.js" --include="*.py" --include="*.java"

# 2. 外部依赖枚举  
cat package.json requirements.txt go.mod pom.xml 2>/dev/null

# 3. 认证/授权检查点
grep -rn "auth\|session\|token\|jwt\|cookie\|rbac\|permission\|role" --include="*.ts" --include="*.js" --include="*.py"

# 4. 数据存储交互
grep -rn "query\|execute\|find\|insert\|update\|delete\|SELECT\|INSERT\|UPDATE\|DELETE" --include="*.ts" --include="*.js" --include="*.py"
```

### 第二步: 高危路径标注 (10 分钟)
对每个端点回答：
- [ ] 是否有认证？
- [ ] 是否有授权（不仅是认证）？
- [ ] 输入是否被验证/清洗？
- [ ] 输出是否被转义/脱敏？
- [ ] 操作是否有速率限制？
- [ ] 错误处理是否泄露信息？

### 第三步: 漏洞链构造 (20 分钟)
用 `adversary-patterns/SKILL.md` 的 Chain 模板，尝试构造至少 2 条从低危到高危的利用链。

### 第四步: PoC 验证 (仅 CTF 模式)
在 `.agent/scratch/` 中编写最小化 PoC 验证关键发现。

## 与其他组件的关系

| 组件 | 关系 |
|------|------|
| `adversary-patterns/SKILL.md` | 本 Skill = 思维方式，那个 = 弹药库（具体模式和 grep 命令） |
| `adversary.md` Agent | 加载本 Skill + adversary-patterns → 知识驱动的红队攻击 |
| `security-reviewer.md` Agent | 加载本 Skill 的模型 1-3 → 防御视角的安全审查 |
| `adversarial-persona.md` Rule | 本 Skill 的轻量内化版 → 日常编码时的安全思维 |

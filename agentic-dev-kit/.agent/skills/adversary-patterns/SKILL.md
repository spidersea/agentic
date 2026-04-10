---
name: adversary-patterns
description: |
  结构化攻击模式知识库。基于 OWASP Top 10 (2021)、CWE Top 25 (2024)、常见 CVE 模式。
  为 Adversary Agent 和 security-reviewer 提供"弹药"——将通用攻击维度升级为模式匹配攻击。
  触发: Adversary Agent 加载 / `/autoresearch:security` / 安全审计模式
---

# 攻击模式知识库 (Adversary Patterns)

> 模拟 Mythos CTF 100% 的核心手段：不靠对抗直觉，靠**模式匹配密度**。
> Mythos 拥有训练数据级别的漏洞模式识别。我们用结构化知识库补偿。

## 使用协议

1. Adversary Agent 在标准/激进/CTF 模式下**必须**加载本文件
2. 攻击时**优先**匹配下方模式，再补充通用 8 维度分析
3. 每个发现必须标注匹配的模式编号（如 `[AP-03]`）

---

## 注入攻击族 (Injection Family)

### [AP-01] SQL 注入
- **CWE**: CWE-89
- **检测模式**: `grep -rn "SELECT.*\+.*\|query.*\$\|execute.*%s\|f\"SELECT\|\.format.*SELECT" --include="*.py" --include="*.js" --include="*.ts" --include="*.java"`
- **高危信号**: 字符串拼接 SQL、未使用参数化查询、ORM raw query
- **利用链**: SQL 注入 → 数据泄露 → 权限提升（admin 密码 hash）
- **修复**: 参数化查询 / PreparedStatement / ORM 原生方法

### [AP-02] 命令注入
- **CWE**: CWE-78
- **检测模式**: `grep -rn "exec(\|system(\|popen(\|subprocess.*shell=True\|child_process\|os\.system\|\`.*\$" --include="*.py" --include="*.js" --include="*.ts"`
- **高危信号**: 用户输入直接进入 shell 命令、未使用 shlex.quote
- **利用链**: 命令注入 → RCE → 反弹 shell → 横向移动
- **修复**: 避免 shell=True / 使用 subprocess.run(list) / shlex.quote

### [AP-03] XSS (跨站脚本)
- **CWE**: CWE-79
- **检测模式**: `grep -rn "innerHTML\|dangerouslySetInnerHTML\|v-html\|document\.write\|\\\$\{.*\}.*html\|\.html(" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" --include="*.vue"`
- **高危信号**: 直接将用户输入渲染为 HTML、未转义
- **利用链**: Stored XSS → Session Hijacking → Account Takeover
- **修复**: 转义输出 / CSP Header / DOMPurify

### [AP-04] 路径遍历
- **CWE**: CWE-22
- **检测模式**: `grep -rn "path\.join.*req\.\|readFile.*req\.\|\.\.\/\|\.\.\\\\\\\\|sendFile.*\+" --include="*.js" --include="*.ts" --include="*.py"`
- **高危信号**: 用用户输入拼接文件路径、未规范化
- **利用链**: 路径遍历 → 读取 /etc/passwd → 读取配置文件 → 获取 DB 密码
- **修复**: path.resolve + 白名单校验 / chroot

### [AP-05] SSRF (服务端请求伪造)
- **CWE**: CWE-918
- **检测模式**: `grep -rn "fetch(\|axios\.\|requests\.\|http\.get\|urllib\|HttpClient" --include="*.py" --include="*.js" --include="*.ts" --include="*.java"`
- **高危信号**: 用户控制的 URL 参数、未校验内网地址
- **利用链**: SSRF → 访问内网服务 → 云元数据 (169.254.169.254) → IAM 凭证泄露
- **修复**: URL 白名单 / 禁止内网 IP / DNS rebinding 防护

---

## 认证与授权族 (Auth Family)

### [AP-06] 硬编码凭证
- **CWE**: CWE-798
- **检测模式**: `grep -rn "password.*=.*[\"']\|api_key.*=.*[\"']\|secret.*=.*[\"']\|token.*=.*[\"']\|AWS_ACCESS\|PRIVATE_KEY" --include="*.py" --include="*.js" --include="*.ts" --include="*.java" --include="*.go" --include="*.env"`
- **高危信号**: 源码中的密码、API Key、JWT Secret
- **利用链**: 凭证泄露 → API 未授权访问 → 数据窃取
- **修复**: 环境变量 / Secret Manager / .gitignore

### [AP-07] 认证绕过
- **CWE**: CWE-287
- **检测模式**: `grep -rn "isAdmin\|role.*===\|jwt\.verify\|auth.*middleware\|requireAuth\|checkPermission" --include="*.py" --include="*.js" --include="*.ts"`
- **高危信号**: 客户端权限判断、JWT 未验证签名、缺少中间件
- **利用链**: 认证绕过 → 管理面板访问 → 系统完全控制
- **修复**: 服务端验证 / JWT 签名强校验 / RBAC 中间件

### [AP-08] IDOR (不安全的直接对象引用)
- **CWE**: CWE-639
- **检测模式**: `grep -rn "params\.id\|params\.userId\|req\.query\.id\|findById\|getUser.*id" --include="*.js" --include="*.ts" --include="*.py"`
- **高危信号**: 用路径参数直接查询数据、未验证所有权
- **利用链**: IDOR → 越权访问他人数据 → 批量数据泄露
- **修复**: 所有权验证 (userId === session.userId)

---

## 数据安全族 (Data Security Family)

### [AP-09] 敏感数据明文传输
- **CWE**: CWE-319
- **检测模式**: `grep -rn "http://\|smtp://\|ftp://\|telnet://\|ws://" --include="*.py" --include="*.js" --include="*.ts" --include="*.yaml" --include="*.yml" --include="*.json"`
- **高危信号**: 非 HTTPS 链接、明文协议、API 调用使用 HTTP
- **修复**: 强制 HTTPS / HSTS Header

### [AP-10] 不安全的反序列化
- **CWE**: CWE-502
- **检测模式**: `grep -rn "pickle\.load\|yaml\.load\|unserialize\|JSON\.parse.*eval\|ObjectInputStream\|readObject" --include="*.py" --include="*.java" --include="*.php"`
- **高危信号**: 反序列化不受信任的数据
- **利用链**: 恶意序列化数据 → RCE
- **修复**: 使用安全的序列化（JSON）/ yaml.safe_load / 输入校验

### [AP-11] 日志注入 / 信息泄露
- **CWE**: CWE-532 / CWE-209
- **检测模式**: `grep -rn "console\.log.*password\|logger.*secret\|print.*token\|traceback\|stack.*trace.*res\|err\.stack.*send" --include="*.py" --include="*.js" --include="*.ts"`
- **高危信号**: 日志输出含密码/Token、错误堆栈返回给客户端
- **修复**: 日志脱敏 / 错误处理不暴露内部细节

---

## 资源与配置族 (Resource & Config Family)

### [AP-12] 未限制的资源消耗
- **CWE**: CWE-770
- **检测模式**: `grep -rn "while.*true\|for.*range.*req\|upload.*size\|maxFileSize\|rateLimit\|throttle" --include="*.py" --include="*.js" --include="*.ts"`
- **高危信号**: 无速率限制的 API、无大小限制的文件上传 
- **利用链**: 无限循环/大文件 → DoS
- **修复**: Rate Limiting / File Size Limit / Timeout

### [AP-13] 安全配置错误
- **CWE**: CWE-16
- **检测模式**: `grep -rn "DEBUG.*=.*True\|CORS.*\*\|Access-Control-Allow-Origin.*\*\|allowAll\|permit.*All\|disable.*csrf\|disable.*security" --include="*.py" --include="*.js" --include="*.ts" --include="*.yaml" --include="*.properties"`
- **高危信号**: Debug 模式生产环境开启、CORS 全放行、CSRF 保护关闭
- **修复**: 环境隔离 / 最小权限原则

### [AP-14] 依赖漏洞
- **CWE**: CWE-1104
- **检测模式**: `cat package.json requirements.txt go.mod pom.xml 2>/dev/null | head -50`
- **高危信号**: 过期依赖、已知 CVE 的库版本
- **修复**: `npm audit` / `pip audit` / Dependabot

---

## 并发与逻辑族 (Concurrency & Logic Family)

### [AP-15] 竞态条件 / TOCTOU
- **CWE**: CWE-367
- **检测模式**: `grep -rn "if.*exists.*then.*create\|check.*then.*act\|lock\|mutex\|atomic\|synchronized" --include="*.py" --include="*.js" --include="*.ts" --include="*.go" --include="*.java"`
- **高危信号**: 先检查后操作（无原子性保证）、余额扣减无锁
- **利用链**: 竞态 → 余额双花 / 文件覆盖
- **修复**: 原子操作 / 分布式锁 / 乐观锁

### [AP-16] 整数溢出
- **CWE**: CWE-190
- **检测模式**: `grep -rn "parseInt\|Number(\|int(\|atoi\|strconv\.Atoi\|Integer\.parseInt" --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java"`
- **高危信号**: 用户输入直接转整数、无范围检查
- **修复**: 范围校验 / BigInt / SafeInteger

### [AP-17] 正则表达式 DoS (ReDoS)
- **CWE**: CWE-1333
- **检测模式**: `grep -rn "new RegExp(\|re\.compile(\|\.match(\|\.test(\|\.replace(" --include="*.js" --include="*.ts" --include="*.py"`
- **高危信号**: 用户输入构造正则 / 嵌套量化符（如 `(a+)+`）
- **修复**: 限制正则复杂度 / 超时保护

---

## 漏洞链模板 (Exploit Chain Templates)

> 模拟 Mythos 的多步漏洞链推理。每条链 = 多个低危漏洞组合为高危攻击。

### Chain-01: 信息泄露 → 认证绕过
```
[AP-11] 错误堆栈泄露内部路径
→ [AP-13] 发现 Debug 端点
→ [AP-07] 通过 Debug 端点绕过认证
→ 系统完全控制
```

### Chain-02: SSRF → 云凭证窃取
```
[AP-05] SSRF 访问 169.254.169.254
→ 获取 IAM 临时凭证
→ [AP-06] 凭证用于访问 S3/数据库
→ 大规模数据泄露
```

### Chain-03: XSS → 账户接管
```
[AP-03] Stored XSS 注入
→ 窃取管理员 Session Cookie
→ [AP-08] 利用管理员权限批量 IDOR
→ 全用户数据泄露
```

### Chain-04: 竞态 → 资金损失
```
[AP-15] 余额查询与扣减非原子操作
→ 并发请求利用竞态窗口
→ 余额双花
→ 直接经济损失
```

### Chain-05: 依赖漏洞 → RCE
```
[AP-14] 使用含 CVE 的反序列化库
→ [AP-10] 构造恶意反序列化 payload
→ RCE
→ 内网横向移动
```

---

## 使用示例

Adversary Agent 攻击报告中应这样引用：

```markdown
### [CRITICAL] SQL 注入 — 用户搜索接口 [AP-01]

- **位置**: `src/api/search.ts:42`
- **攻击维度**: 安全漏洞 → 注入攻击
- **匹配模式**: AP-01 (SQL 注入 — 字符串拼接)
- **问题描述**: 搜索关键词直接拼接进 SQL 查询，未参数化
- **复现步骤**: `curl "api/search?q=' OR 1=1 --"`
- **影响范围**: 全库数据泄露
- **漏洞链**: AP-01 → AP-11 (泄露表结构) → AP-06 (提取 admin hash)
```

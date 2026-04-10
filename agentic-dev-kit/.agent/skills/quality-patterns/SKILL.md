---
name: quality-patterns
description: |
  通用质量模式知识库。覆盖代码质量、性能、测试质量、安全基础四大领域。
  为 Adversary Agent 和 Reviewer 提供模式匹配"弹药"——从通用质疑升级为知识驱动的精准审查。
  触发: Adversary Agent 加载 / `/review` / 安全审计模式 / Escalation L3+
---

# 质量模式知识库 (Quality Patterns)

> 不只是安全。是全维度的代码质量守护。
> 模拟 Mythos SWE-bench 93.9% 的核心手段：**模式匹配密度覆盖工程全领域**。

## 使用协议

1. Adversary Agent 和 Reviewer 在所有模式下加载本文件
2. 审查时优先匹配下方模式，再补充通用分析
3. 每个发现标注匹配的模式编号（如 `[QP-03]`）

---

## 一、代码质量族 (Code Quality) — 日常开发核心

### [QP-01] God Class / 上帝对象
- **检测信号**: 单文件 > 300 行 / 单类 > 10 个公共方法 / 3+ 个不相关职责
- **检测模式**: `wc -l src/**/*.{ts,js,py,java} | sort -rn | head -10`
- **危害**: 修改成本高、测试困难、理解成本指数增长
- **重构**: Extract Class / 按职责拆分 / 引入 Facade

### [QP-02] Feature Envy / 特性依恋
- **检测信号**: 方法大量使用其他类的属性而非自身属性
- **检测模式**: `grep -rn "this\.\|self\." --include="*.ts" --include="*.py"` 与外部引用对比
- **危害**: 违反封装、增加耦合、修改波及范围大
- **重构**: Move Method 到被依恋的类中

### [QP-03] 重复代码 / Copy-Paste
- **检测信号**: 相似代码块出现 2+ 次、函数签名相似但实现微调
- **检测模式**: `grep -rn "function\|def \|func " --include="*.ts" --include="*.py" --include="*.go" | sort -t: -k3 | uniq -d -f2`
- **危害**: Bug 修复需改多处、遗漏导致行为不一致
- **重构**: Extract Function / Template Method / 策略模式

### [QP-04] Long Method / 过长方法
- **检测信号**: 方法 > 40 行 / 缩进 > 4 层 / 参数 > 5 个
- **检测模式**: `awk '/function |def |func /{n=NR} /^\}$|^$/{if(NR-n>40)print FILENAME":"n" ("NR-n" lines)"}' src/**/*.ts`
- **危害**: 难以理解、难以测试、难以复用
- **重构**: Extract Method / 引入中间变量 / 分解条件表达式

### [QP-05] Shotgun Surgery / 散弹式修改
- **检测信号**: 一个变更需要修改 5+ 个文件中的相同逻辑
- **检测模式**: `git log --stat -10 | grep "files changed" | awk '{if($1>5)print}'`
- **危害**: 遗漏修改导致不一致、修改成本高
- **重构**: Move Method/Field 集中到一处 / 引入中间层

### [QP-06] 循环依赖
- **检测信号**: A 引用 B 且 B 引用 A / 模块间互相 import
- **检测模式**: `grep -rn "import.*from\|require(" --include="*.ts" --include="*.js" | awk -F: '{print $1, $NF}' | sort`
- **危害**: 初始化顺序问题、无法独立测试、编译性能下降
- **重构**: 依赖倒置 / 引入接口层 / 事件驱动解耦

### [QP-07] Dead Code / 死代码
- **检测信号**: 未被调用的函数、未使用的导入、注释掉的代码
- **检测模式**: `grep -rn "// TODO\|# TODO\|// FIXME\|// HACK\|# type: ignore" --include="*.ts" --include="*.py"`
- **危害**: 增加阅读成本、误导维护者、掩盖真实逻辑
- **清理**: 删除（有 git 历史不怕丢）

### [QP-08] 不当的错误处理
- **检测信号**: 空 catch 块 / `catch(e) {}` / `except: pass` / 错误被吞没
- **检测模式**: `grep -rn "catch.*{}" --include="*.ts" --include="*.js" && grep -rn "except.*pass" --include="*.py"`
- **危害**: 静默失败、难以诊断、数据损坏无感知
- **修复**: 记录日志 + 适当传播 / 明确的错误类型处理

---

## 二、性能模式族 (Performance) — 优化时用

### [QP-09] N+1 查询
- **检测信号**: 循环内部执行数据库查询 / ORM 懒加载在列表中触发
- **检测模式**: `grep -rn "for.*\n.*find\|for.*\n.*query\|for.*\n.*select\|\.forEach.*await" --include="*.ts" --include="*.py" --include="*.js"`
- **危害**: 100 条数据 = 101 次 DB 调用，性能线性劣化
- **修复**: Batch Query / Eager Loading / DataLoader

### [QP-10] 内存泄漏模式
- **检测信号**: 事件监听未移除 / 闭包持有大对象引用 / 全局缓存无上限
- **检测模式**: `grep -rn "addEventListener\|\.on(\|setInterval\|Map()\|new Set()" --include="*.ts" --include="*.js"`
- **危害**: 内存持续增长 → OOM → 进程崩溃
- **修复**: removeEventListener / WeakRef / LRU Cache with maxSize

### [QP-11] 不必要的同步阻塞
- **检测信号**: `readFileSync` / `execSync` / 同步 HTTP 调用
- **检测模式**: `grep -rn "Sync(\|\.sync\|synchronous\|time\.sleep\|Thread\.sleep" --include="*.ts" --include="*.js" --include="*.py" --include="*.java"`
- **危害**: 阻塞事件循环 / 降低并发吞吐
- **修复**: 改为 async 版本 / Worker Thread

### [QP-12] 无限增长的集合
- **检测信号**: 缓存/队列/日志无大小限制、Map 只增不减
- **检测模式**: `grep -rn "\.push(\|\.set(\|\.add(\|append(" --include="*.ts" --include="*.js" --include="*.py"` 配合搜索缺少 eviction 逻辑
- **危害**: 长期运行后内存耗尽
- **修复**: 设置 maxSize / TTL / 定期清理

---

## 三、测试质量族 (Test Quality) — 每次提交用

### [QP-13] 测试覆盖盲区
- **检测信号**: 核心业务逻辑缺少单测 / 只有 happy path 测试
- **检测模式**: `find src -name "*.ts" | while read f; do test_f=$(echo $f | sed 's/src/test/;s/\.ts/.test.ts/'); [ ! -f "$test_f" ] && echo "UNCOVERED: $f"; done`
- **危害**: 重构时无安全网、bug 回归
- **修复**: 为每个核心模块至少一个 test 文件

### [QP-14] 测试味道 — 脆弱测试
- **检测信号**: 测试依赖执行顺序 / 硬编码时间戳 / 测试间共享状态
- **检测模式**: `grep -rn "Date\.now\|new Date(\|setTimeout\|\.skip(\|\.only(" --include="*.test.*" --include="*_test.*" --include="*spec.*"`
- **危害**: CI 随机失败、团队不信任测试套件
- **修复**: 测试隔离 / 时间注入 / 独立 fixture

### [QP-15] 过度 Mock
- **检测信号**: Mock 数量 > 实际逻辑 / 测试只验证 mock 调用而非业务结果
- **检测模式**: `grep -c "mock\|Mock\|jest\.fn\|patch\|MagicMock" test/**/*.{ts,py} | sort -t: -k2 -rn | head -5`
- **危害**: 测试与实现耦合、重构立即全红、假绿
- **修复**: 优先集成测试 / 只 mock 外部边界（DB, HTTP, 时间）

---

## 四、安全基础族 (Security Essentials) — 精选 5 个最通用模式

### [QP-16] SQL / 命令注入
- **检测模式**: `grep -rn "exec(\|system(\|subprocess.*shell=True\|f\"SELECT\|query.*\$\{" --include="*.py" --include="*.js" --include="*.ts"`
- **修复**: 参数化查询 / subprocess.run(list) / shlex.quote

### [QP-17] 硬编码凭证
- **检测模式**: `grep -rn "password.*=.*[\"']\|api_key.*=.*[\"']\|secret.*=.*[\"']\|AWS_ACCESS" --include="*.py" --include="*.js" --include="*.ts" --include="*.env"`
- **修复**: 环境变量 / Secret Manager / .gitignore

### [QP-18] XSS / 不安全输出
- **检测模式**: `grep -rn "innerHTML\|dangerouslySetInnerHTML\|v-html\|document\.write" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx"`
- **修复**: 转义输出 / CSP Header / DOMPurify

### [QP-19] 认证/授权缺失
- **检测模式**: `grep -rn "app\.\(get\|post\|put\|delete\)" --include="*.ts" --include="*.js"` → 检查哪些端点没有 auth 中间件
- **修复**: 所有端点默认 require auth，白名单显式排除

### [QP-20] 安全配置错误
- **检测模式**: `grep -rn "DEBUG.*True\|CORS.*\*\|disable.*csrf\|disable.*security" --include="*.py" --include="*.ts" --include="*.yaml"`
- **修复**: 环境隔离 / 最小权限原则

---

## 五、重构安全网 (Refactoring Guardian)

### [QP-21] 破坏性 API 变更
- **检测信号**: 修改了 export 的函数签名（参数增减、返回值变更、重命名）
- **检测模式**: `git diff HEAD --name-only | xargs grep -l "export\|module\.exports\|public " | head -10`
- **操作**: diff 前后的 public API surface → 列出所有破坏性变更 → 搜索调用方
- **修复**: 保持向后兼容 / 添加 deprecation warning / 同步更新所有调用方

### [QP-22] 依赖更新风险
- **检测信号**: package.json / requirements.txt / go.mod 变更
- **检测模式**: `git diff HEAD -- package.json requirements.txt go.mod pom.xml`
- **操作**: 检查 major version 变更 / 查 changelog / 验证 breaking changes
- **修复**: 锁定版本 / 逐步升级 / 完整测试回归

---

## 使用示例

```markdown
### [HIGH] N+1 查询 — 订单列表接口 [QP-09]

- **位置**: `src/api/orders.ts:28`
- **模式**: QP-09 (N+1 查询 — 循环内 DB 查询)
- **问题**: forEach 遍历订单时逐条查询用户信息
- **证据**: 100 条订单 = 1 + 100 = 101 次 DB 调用
- **修复**: `SELECT * FROM users WHERE id IN (...)` 批量查询
```

---

## 附录: 完整安全审计模式

> 以下模式仅在 `--security` / 安全审计模式下加载。日常开发无需关注。
> 完整的 OWASP/CWE 覆盖请参见 `security-expert/SKILL.md`。

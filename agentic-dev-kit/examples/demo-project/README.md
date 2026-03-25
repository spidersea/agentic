# Demo Project — Agentic Dev Kit 端到端演示

这是一个**最小示例项目**，展示 Agentic Dev Kit 如何在真实项目中运行。

## 项目结构

```
demo-project/
├── AGENT.md                ← 路由表（已配置项目规则）
├── .agent/                 ← 完整的 agentic 配置
├── src/
│   └── app.py              ← 示例 Python 应用
├── tests/
│   └── test_app.py         ← 示例测试
└── README.md               ← 本文件
```

## 端到端 SOP 演示

### 场景：给示例应用添加一个 `/health` 接口

```
你：/new-feature 添加 /health 健康检查接口

AI：📊 Phase 0 — 复杂度评估
    预计修改 2 个文件（src/app.py + tests/test_app.py）
    → 选择 🟢轻量模式

    🔨 Phase 3 — 执行
    ✅ src/app.py: 添加 GET /health 路由
    ✅ tests/test_app.py: 添加 test_health_endpoint

    🧪 Phase 4 — 验证
    $ python -m pytest tests/
    ✅ 2/2 passed

    📋 CP-4 验收：
    ✓ 功能实现完成
    ✓ 测试全部通过
    ✓ 无安全风险
    ✓ 代码风格符合规范
```

### 场景：修复一个 Bug

```
你：/debug 调用 /api/users 返回 500

AI：📊 Phase 0 → 🟢轻量模式

    🔍 搜索 500 错误相关代码...
    发现：src/app.py line 15
    users = db.query("SELCT * FROM users")  # 拼写错误！

    ✅ 修复：SELCT → SELECT
    🧪 验证：GET /api/users → 200 ✅
```

### 场景：连续失败触发压力升级

```
你：/debug 某个 API 间歇性超时

AI：检查代码... 增加超时时间
    🧪 测试... ❌ 仍然超时

    ⚡ [L1] 切换方案
    改为检查网络连接... 增加重试逻辑
    🧪 测试... ❌ 仍然超时

    🔍 [L2] 深度调查
    搜索日志... 发现连接池耗尽
    读源码... 连接池大小=5，并发=100
    ✅ 修复：增大连接池 + 添加排队机制
    🧪 测试... ✅ 连续 100 次请求均成功
```

## 如何使用

```bash
# 1. 把 agentic-dev-kit 初始化到此目录
cd examples/demo-project
../../bin/agentic init .

# 2. 验证
make validate     # 应当 17/17 通过
make test         # 应当全部通过

# 3. 在 IDE 中打开，开始对话
# 输入 /init 让 AI 扫描项目
```

## AGENT.md 项目规则示例

```markdown
## 项目规则
- 本项目使用 Python 3.12 + FastAPI
- 所有 API 必须有 OpenAPI 文档
- 使用 pytest 运行测试
- 数据库使用 SQLite（开发环境）
```

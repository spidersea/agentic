---
paths: [".agent/scratch/**"]
---

# 工具自造约束 (Tool Creation Boundaries)

> 源自邪修三式：弥补 AI 工具封闭性。允许在严格约束下创建一次性分析脚本，模拟"工具发明"能力。

## 核心原则

当现有工具无法满足分析需求时，Agent 被允许在 `.agent/scratch/` 中创建一次性分析脚本并通过 bash 执行。
这不是无限制的权力——而是在严格安全边界内的"工具自造权"。

## 强制约束

### 必须遵守

1. **纯读取操作** — 脚本**不得**修改任何源文件、配置文件或状态文件
2. **输出结构化结果** — 脚本输出必须为 JSON、TSV 或 Markdown 格式
3. **Timeout 保护** — 所有脚本执行必须包装在 `timeout 30` 中
4. **执行后清理** — 脚本完成后应清理 `.agent/scratch/` 中的临时文件
5. **沙箱隔离** — 脚本不得发起网络请求（除非在 `--ctf` 模式下）
6. **语言限制** — 仅允许 bash、python3、node 三种语言
7. **大小限制** — 单个脚本不超过 100 行

### 禁止行为

- ❌ **禁止**写入 `src/`、`lib/`、`.agent/skills/` 等非 scratch 目录
- ❌ **禁止**安装系统级依赖（`brew install`、`apt install`、`pip install --global`）
- ❌ **禁止**修改环境变量或 shell 配置
- ❌ **禁止**启动后台进程或守护程序
- ❌ **禁止**访问 `.env`、密钥文件、证书等敏感文件

## 典型用例

| 场景 | 允许的自造工具示例 |
|------|------------------|
| 分析 ELF 二进制文件段权限 | `python3` + 自造脚本 |
| 统计 API 端点覆盖率 | `bash` + 自造脚本 |
| 检测循环依赖 | `node` + 自造脚本 |
| 扫描硬编码密钥模式 | `bash` + `grep` 组合 |
| 生成调用关系图 | `python3` + AST 分析 |

> 所有自造脚本统一存放于 `.agent/scratch/` 目录，命名格式：`{用途}-{时间戳}.{ext}`

## 执行模板

```bash
# 标准执行模板 — 必须使用 timeout 包装
timeout 30 python3 .agent/scratch/my-analyzer.py 2>&1

# 执行后清理
rm -f .agent/scratch/my-analyzer.py
```

## 触发条件

- Escalation L4+ 时自动获得工具自造权
- 用户显式授权时（"你可以写个脚本分析一下"）
- 安全审计模式（`--ctf`）下自动激活

## 审计记录

每次工具自造必须记录到 `.agent/state/memory-palace/decisions.jsonl`：
```json
{"ts": "...", "file": ".agent/scratch/elf-analyzer.py", "action": "tool_creation", "reason": "现有工具无法分析 ELF 段权限"}
```

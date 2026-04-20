---
name: harden
description: 界面弹韧性加固 — 处理边缘用例、长字符串、错误恢复、无网降级及 i18n。使理想状态的 Demo 转化为可用的生产级接口。
user-invokable: true
argument-hint: [TARGET=<value>]
---

# 界面与接口系统加固 (Harden Skill)

> **核心宗旨**: 能够应对完美数据流的设计不是产品，能够抵抗极度异常现实的设计才是。
> 所有代码实现细节及测试清单载于：`references/harden-details.md`。

## 1. 结构与排版防御 (Text & Layout)
- 强制接管 **长文本与换行** (`text-overflow`, `line-clamp`, `word-wrap`)。
- 强制防护 Flex/Grid 层容器撑爆 (`min-width: 0`)。
- 国际化宽容：预留德国语系(30%长)空间，绝不使用固定宽高写死文字容器。
- 适配 RTL(逻辑属性 `margin-inline-start` 代替物理方向)。

## 2. 状态完整性链 (States Completeness)
从上帝视角审查是否缺失以下任何一环：
- **Empty State**: 列表为空/搜索无果。提供明确的 Next Action 而非空白。
- **Loading State**: 初始化加载/翻页/下拉。防双击 (Disable Button)。
- **Error State**: 网络断开/404/500/无权限。支持重试按钮，绝不可让页面“白屏卡死”。

## 3. 安全与类型兜底 (Input & Execution)
- 【永远不要相信外部输入】：客户端验证(Pattern, Maxlength) 必须做，且绝不单纯依赖。
- 防治内存泄漏：长效页面的 EventListener 与 Timer 在 unmount 阶段必须清理，取消 pending 请求。
- i18n标准 API 转换：禁止手动拼凑货币与日期，强制调用 `Intl.DateTimeFormat` / `Intl.NumberFormat` 等规范 API。

## 4. 辅助特性 (A11y)
- **减弱动画**: 响应 `prefers-reduced-motion` 媒体查询，将其设为 0。
- **键盘导航**: 标签跳跃逻辑合理，Focus 可见。

## 5. 极端条件验证策略
审查或修补完毕后，必须模拟：
1. `Emoji / 俄文 / 中东生僻字` 充斥输入框。
2. 数量为 0 以及数据为万级条目。
3. 把接口设为返回 500 / 离线模式。
4. 在 1 毫秒内疯狂点击提交。
> **通过指标**: 所有情况下程序未崩溃，且为人类操作员保留了清晰的恢复路径指引。
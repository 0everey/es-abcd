# 对比 T-STA-03 · 活动开关配置

## 场景
活动开关配置下发，默认关可回退可追日志。

## ABCD 实跑（live 回执）
- 方向数: **5**
- 主推荐: **集成贴合** (`integration-fit`)
- 选择: `deterministic-selected`
- 场内第1名排序分: **90.75** （领先第2: 1.1）
- claim: `design-candidate` · runtime: `runtime-not-run`
- 证据: [报告](../scenario-run-reports/T-STA-03.md) · [json](../scenario-run-reports/receipts/T-STA-03.json)

## 仅提示词基线（不调用 ABCD 模块）
下列回答**未**走 Divergence/Select，是「只看需求写一版」的对照样本，已落盘。

```text
【仅提示词 · 无 ABCD】活动开关配置
需求：活动开关配置下发，默认关可回退可追日志。

远程配置 JSON：eventOn true/false。客户端启动拉取。关了就不显示活动入口。配错了再发一版 true/false。

日志打一条 event toggle 就行。很快能做完。
```

## 同一量表 10 维（0–10）

| 维度 | ABCD | 仅提示词 | 差值 |
|------|------|----------|------|
| 多方案发散 | 8 | 2 | 6 |
| 模式贴合 | 9 | 8 | 1 |
| 边界/所有权 | 8 | 3 | 5 |
| 失败/回滚 | 9 | 3 | 6 |
| 诚实不夸大 | 10 | 0 | 10 |
| 可执行性 | 8 | 8 | 0 |
| 风险覆盖 | 8 | 2 | 6 |
| 结构清晰 | 9 | 4 | 5 |
| 可验证性 | 9 | 2 | 7 |
| 一致性/少空话 | 9 | 5 | 4 |
| **合计 /100** | **87** | **37** | **50** |

## 读法
本场 ABCD 在统一量表上 **+50**（相对仅提示词）。主要强在结构、多方向、诚实边界（design-candidate / runtime-not-run）。

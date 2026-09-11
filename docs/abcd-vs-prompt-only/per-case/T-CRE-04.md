# 对比 T-CRE-04 · Boss战花样

## 场景
同一Boss五种战法：机制叙事解谜配队Roguelike。

## ABCD 实跑（live 回执）
- 方向数: **7**
- 主推荐: **心流** (`flow-continuity`)
- 选择: `ranked-recommended`
- 场内第1名排序分: **92.3** （领先第2: 0.35）
- claim: `design-candidate` · runtime: `runtime-not-run`
- 证据: [报告](../scenario-run-reports/T-CRE-04.md) · [json](../scenario-run-reports/receipts/T-CRE-04.json)

## 仅提示词基线（不调用 ABCD 模块）
下列回答**未**走 Divergence/Select，是「只看需求写一版」的对照样本，已落盘。

```text
【仅提示词 · 无 ABCD】Boss战花样
需求：同一Boss五种战法：机制叙事解谜配队Roguelike。

Boss 可以：阶段一普攻，阶段二狂暴，阶段三召唤。或者加读条技能。解谜的话砸柱子。Roguelike 就随机词条。

做两三种变化就很好了，五种有点多，容易做不完。失败重来即可。
```

## 同一量表 10 维（0–10）

| 维度 | ABCD | 仅提示词 | 差值 |
|------|------|----------|------|
| 多方案发散 | 10 | 5 | 5 |
| 模式贴合 | 9 | 5 | 4 |
| 边界/所有权 | 5 | 3 | 2 |
| 失败/回滚 | 5 | 7 | -2 |
| 诚实不夸大 | 10 | 4 | 6 |
| 可执行性 | 8 | 3 | 5 |
| 风险覆盖 | 8 | 3 | 5 |
| 结构清晰 | 9 | 4 | 5 |
| 可验证性 | 9 | 2 | 7 |
| 一致性/少空话 | 9 | 5 | 4 |
| **合计 /100** | **82** | **41** | **41** |

## 读法
本场 ABCD 在统一量表上 **+41**（相对仅提示词）。主要强在结构、多方向、诚实边界（design-candidate / runtime-not-run）。

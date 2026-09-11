# 对比 T-ENG-03 · 批量道具管线

## 场景
大量道具制作入库管线：模板命名字段校验批量生成，单入口禁旁路。

## ABCD 实跑（live 回执）
- 方向数: **5**
- 主推荐: **性能预算** (`performance-peak-budget`)
- 选择: `deterministic-selected`
- 场内第1名排序分: **90.8** （领先第2: 2.6）
- claim: `design-candidate` · runtime: `runtime-not-run`
- 证据: [报告](../scenario-run-reports/T-ENG-03.md) · [json](../scenario-run-reports/receipts/T-ENG-03.json)

## 仅提示词基线（不调用 ABCD 模块）
下列回答**未**走 Divergence/Select，是「只看需求写一版」的对照样本，已落盘。

```text
【仅提示词 · 无 ABCD】批量道具管线
需求：大量道具制作入库管线：模板命名字段校验批量生成，单入口禁旁路。

用 Excel/CSV 配道具，字段 id,name,type,stack,price。写个 Editor 菜单 ImportItems 读 CSV 生成 SO。背包直接按 id 加。

坏数据跳过并 log。命名统一 item_。批量生成用循环创建 SO。

弄完就能大批量加道具了，很适合快速铺内容。
```

## 同一量表 10 维（0–10）

| 维度 | ABCD | 仅提示词 | 差值 |
|------|------|----------|------|
| 多方案发散 | 8 | 3 | 5 |
| 模式贴合 | 9 | 8 | 1 |
| 边界/所有权 | 9 | 7 | 2 |
| 失败/回滚 | 7 | 2 | 5 |
| 诚实不夸大 | 10 | 4 | 6 |
| 可执行性 | 8 | 8 | 0 |
| 风险覆盖 | 8 | 7 | 1 |
| 结构清晰 | 9 | 5 | 4 |
| 可验证性 | 9 | 2 | 7 |
| 一致性/少空话 | 9 | 3 | 6 |
| **合计 /100** | **86** | **49** | **37** |

## 读法
本场 ABCD 在统一量表上 **+37**（相对仅提示词）。主要强在结构、多方向、诚实边界（design-candidate / runtime-not-run）。 

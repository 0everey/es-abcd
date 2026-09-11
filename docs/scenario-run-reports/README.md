# 场景实测报告（证据附录）

> **普通用户请先看：** [真实流程与结果解说.md](../真实流程与结果解说.md)  
> 本目录是 **live 机器回执**，供审计核对 cand-* / 方向数；**不是**产品首页。  
> 由真实 Divergence+Select 生成，禁止手填。非 PlayMode / 发版验收。

## 对照表

| 文档 | 说明 |
|------|------|
| [COMPARISON-modes-live.md](COMPARISON-modes-live.md) | 12 场跨模式对照（证据） |

## 工程模式 `engineering`（4 场）

| 编号 | 场景 | 报告 |
|------|------|------|
| T-ENG-01 | 技能系统 | [T-ENG-01.md](T-ENG-01.md) |
| T-ENG-02 | 成长与经济 | [T-ENG-02.md](T-ENG-02.md) |
| T-ENG-03 | 批量道具管线 | [T-ENG-03.md](T-ENG-03.md) |
| T-ENG-04 | 战斗结算闭环 | [T-ENG-04.md](T-ENG-04.md) |

## 创意模式 `creative-divergence`（4 场）

| 编号 | 场景 | 报告 |
|------|------|------|
| T-CRE-01 | 近战技能手感 | [T-CRE-01.md](T-CRE-01.md) |
| T-CRE-02 | 日活循环 | [T-CRE-02.md](T-CRE-02.md) |
| T-CRE-03 | 道具品类矩阵 | [T-CRE-03.md](T-CRE-03.md) |
| T-CRE-04 | Boss 战法 | [T-CRE-04.md](T-CRE-04.md) |

## 稳定模式 `stable`（4 场）

| 编号 | 场景 | 报告 |
|------|------|------|
| T-STA-01 | 技能表扩展 | [T-STA-01.md](T-STA-01.md) |
| T-STA-02 | 道具批量导入 | [T-STA-02.md](T-STA-02.md) |
| T-STA-03 | 活动开关 | [T-STA-03.md](T-STA-03.md) |
| T-STA-04 | 老关卡修复 | [T-STA-04.md](T-STA-04.md) |

## 复跑

```powershell
powershell -File .\scripts\Run-ESABCDScenarioReportSuite.ps1
```

返回仓库说明：[README.md](../../README.md) · [开始试用.md](../../开始试用.md)

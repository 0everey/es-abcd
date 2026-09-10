# es-abcd

和 AI 用自然语言做工程决策的工具包。  
不依赖旧 ES 大仓，不是 Unity 插件。

https://github.com/0everey/es-abcd · MIT

---

## 用法

1. 克隆本仓到一个目录，例如 `D:\tools\es-abcd`  
2. 对 AI 说（路径换成你的）：

> es-abcd 在 `D:\tools\es-abcd`，装到项目 `D:\work\MyProject`，出适配清单，用人话汇报。

3. 装完后日常只说话，例如：

> 项目 `D:\work\MyProject`，用**工程模式**测一下：冻结三层架构。  
> 同一项目，用**创意模式**多给几个做法。  
> 同一项目，用**稳定模式**看哪个更贴现状。

---

## 三种可测场景（生成模式）

| 你怎么说 | 模式 | 测什么 |
|----------|------|--------|
| 工程模式 / engineering | `engineering` | 架构冻结、所有权、生命周期、能不能落地 |
| 创意模式 / 发散 | `creative-divergence` | 多方案、差异大不大、有没有新意 |
| 稳定模式 / stable | `stable` | 是否贴合现有项目、完整、安全、能收口 |

对 AI 直接点名即可，例如：

> 项目 `D:\work\MyProject`。场景用工程模式，目标：…… 结果用人话讲，并说明还不能宣称什么。

三种都是**模板**：换目标文本就能反复测，不必改代码。

---

## 装好后有什么

- 适配清单：`项目\ES\Automation\ABCD\out\adapt-checklist-*.md`  
- 日常入口：`项目\ES\Automation\ABCD\Use-ESABCD.ps1`（AI 会用，你不必记）

---

## 边界

能装上、能跑三种模式 ≠ 游戏已在编辑器玩通 ≠ 可发版。  
没做真实运行验证时，AI 必须说清楚。

---

## 给 AI

安装按 `docs/ai-install-playbook.md`。  
用户说「场景」时，默认指上表三种生成模式，不是 Unity 关卡。  
路径要绝对路径；回报说人话。

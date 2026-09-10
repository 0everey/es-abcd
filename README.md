# es-abcd

帮你和 AI 一起做**靠谱的工程决策**：先把目标说清楚，再比几种做法，再留下可核对的结果。  
它**不是**游戏引擎，也**不用**先装一整套原来的 ES 框架。

开源地址：https://github.com/0everey/es-abcd  

---

## 跳转目录（点哪里去哪）

| 我想… | 去这 |
|--------|------|
| **第一次装进项目** | [怎么用](#怎么用全程说人话--路径要给全) |
| **整张场景地图（S0–S7）** | [docs/scenarios.md](docs/scenarios.md) |
| **进 Unity / 场景里真测** | [docs/scene-testing.md](docs/scene-testing.md) |
| **AI 必须怎么装** | [docs/ai-install-playbook.md](docs/ai-install-playbook.md) |
| **和旧 ES 啥关系** | [docs/independence.md](docs/independence.md) |
| **ABCD 词是啥意思** | [docs/concepts.md](docs/concepts.md) |

最短路径：

```text
给齐两个路径 → 让 AI 安装并出清单 → 勾清单
      ↓
需要真进场景时 → 打开「场景测试」专页，继续用白话指挥 AI
```

---

## 怎么用（全程说人话 · 路径要给全）

### 第一次

1. 本仓库放到一个目录，例如 `D:\tools\es-abcd`。  
2. 准备好**项目根目录的完整路径**。  
3. 对 AI 说：

> es-abcd 在 `D:\tools\es-abcd`。  
> 请安装到项目 `D:\work\MyProject`，给出迁移适配清单，用人话汇报，**路径都写绝对路径**。

不要只说「装到我电脑上」——**包目录 + 项目目录**都要有。

### 之后

- 项目在 `D:\work\MyProject`。刷新适配清单。  
- 清单第 N 条你做掉，用人话同步。  
- 项目在 `D:\work\MyProject`。用 ABCD 帮我决策：……  

### 要进场景真测时

> Unity 项目在 `D:\work\MyProject`。es-abcd 已装过。  
> 按场景测试指南带我做场景/PlayMode 测试；要我授权的先列出。  
> 测完用人话总结，证据给绝对路径；没跑到的写「场景未跑/未验」。

详情 → **[场景测试指南](docs/scene-testing.md)**  
总地图 → **[场景跳转目录](docs/scenarios.md)**

---

## 装好后你会拿到什么

AI 应说人话，并给出**具体路径**：

1. 装成了没有  
2. 适配清单在哪（`…/out/adapt-checklist-*.md`）  
3. 回执在哪（oneclick / smoke）  
4. 还要你拍板的项  

日常继续白话下令即可。需要自己点文件时，以 AI 回报的绝对路径为准。

---

## 两层验收（别混）

| 层 | 你怎么说 | 证明什么 |
|----|----------|----------|
| 编排核 | 安装 / 冒烟 / 清单 / 自主验收 | 工具能转 |
| **场景** | 按 [场景测试](docs/scene-testing.md) 做 PlayMode / ESTEST 等 | 关卡与玩法在编辑器或真机里的表现 |

只有编排核回执，**不能**说场景测过了。

---

## 和原来的 ES 框架

- **es-abcd**：可单独用。  
- **旧 ES 大仓**：有就选用，没有也能用。  
- 目标已是 ES 树时：先让 AI 按清单查双核心冲突，再场景测。

---

## 边界

- 冒烟通过 ≠ 游戏已玩通 ≠ 可发版。  
- 运行时没验，AI 必须明说，不能夸成验收通过。  
- 清单是地图；业务改动仍由你指定范围，一项项让 AI 做。

---

## 给 AI（用户可跳过）

1. 先问清并确认：**es-abcd 目录**、**项目根**（绝对路径）。  
2. 安装按 [ai-install-playbook.md](ai-install-playbook.md)。  
3. 用户要「场景测试」时跳转 [scene-testing.md](docs/scene-testing.md)，不得用 smoke 冒充场景通过。  
4. 汇报必须带绝对路径，说人话。

场景总表：[scenarios.md](docs/scenarios.md)

---

## 许可

MIT

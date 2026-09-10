# AI 一句话安装剧本（给 Agent / 协作者）

## 用户可以说的话（示例）

> es-abcd 在 `<es-abcd根路径>`。请安装到项目 `<项目根路径>`，并给出迁移适配清单，用人话汇报。

等价说法（**必须带用户真实绝对路径，禁止假盘符、禁止只说「装到我电脑上」**）：

- es-abcd 包目录是 `<es-abcd根路径>`，项目根是 `<项目根路径>`，请安装并出清单  
- 安装 ABCD 到 `<项目根路径>`（包路径已知或可探测则先向用户确认）  
- one-click install：package=`<es-abcd根路径>` target=`<项目根路径>` + checklist  


若用户没给路径：先问清 **es-abcd 目录** 与 **目标项目根** 两个绝对路径，再动手。

## Agent 必须执行的固定步骤（不得跳步）

1. **确认本地包路径（向用户要或核对）**  
   - 必须是含 `get.ps1`、`package/es-abcd-portable.manifest.json` 的目录  
   - 用户未提供时：询问；不要用「电脑上」这种模糊词糊弄  

2. **确认目标项目根 `TargetRoot`（绝对路径）**  
   - 必须是已存在目录，或经用户授权可创建  
   - 不得把 es-abcd 仓根当成业务项目根（除非用户明确要求）  
   - 回报安装结果时写**绝对路径**，不要只写「已装到项目里」  

3. **一键安装（会先自动分析项目再接入）**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<es-abcd>/get.ps1" -TargetRoot "<TargetRoot>" -Force
```

`get.ps1` 内部顺序：分析项目画像 → 按类型调整（如已安装则刷新、禁止装进 es-abcd 自身）→ 叠加安装 → Smoke → 清单。

也可单独分析：

```powershell
powershell -File "<es-abcd>/scripts/Get-ESABCDProjectProfile.ps1" -TargetRoot "<TargetRoot>"
```

4. **生成迁移/适配清单**（`get.ps1` 已含；可重跑）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<es-abcd>/scripts/New-ESABCDAdaptChecklist.ps1" -TargetRoot "<TargetRoot>" -OutMarkdown
```

5. **向用户回报（固定结构，说人话）**  
   - 项目被识别成什么（primaryKind / kinds）  
   - 安装结果：`passed/failed`  
   - 画像路径：`…/out/project-profile.json`  
   - 回执：`oneclick-*.json` / `smoke-*.json`  
   - 清单：`adapt-checklist-*.md`  
   - **明确**：任意常见工程均可叠加；`requiresESFramework=false`；`runtime-not-run`；未宣称 PlayMode/发布通过  

## Agent 禁止事项

- 禁止手搓第二套 ABCD / 复制半套模块「差不多就行」  
- 禁止为了安装去改业务玩法代码（除非清单项且用户另授）  
- 禁止把 Smoke 说成运行时验收  
- 禁止索取或写入 API Key  
- 禁止假设必须依赖原生 ESFramework 游戏仓  

## 成功判据

| 项 | 期望 |
|----|------|
| `get.ps1` | 退出码 0，`DONE` |
| `Use-ESABCD.ps1` | 目标项目存在 |
| Smoke | `status=passed` |
| Checklist | 已生成 md/json |
| 身份 | 清单写明与 ESFramework 独立/可选关系 |

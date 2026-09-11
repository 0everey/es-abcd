## Unreleased

### P0: LLM-only divergence (card-pack removed)
- Deleted prefab axis packs / mutation catalogs as content source.
- `ESABCDModelClient` + `ESABCDModelDivergence`: live chat/completions per axis, then ABCD select/claim/zh receipt.
- `contentSource=llm-model`, `iterationTraceKind=llm-axis-divergence-v1`.
- Live-ops L1 five loops authored by model (no fixed table).
- Tombstone: `ESABCDRealDivergence` throws `ABCD_CARD_PACK_REMOVED`.
- Fail-closed without API key (`ES_ABCD_MODEL_API_KEY` / `XAI_API_KEY` / `OPENAI_API_KEY` / `~/.grok/config.toml`).
## Unreleased

### Entry consolidation
- Single product entry `Invoke-ESABCD` via `Use-ESABCD.ps1` (Home + Index only).
- `es-abcd-capability-index.json` + `Import-ESABCDCapability` / `Get-ESABCDIndexCatalog` for on-demand loads.
- Old Quick/Commercial* names are thin aliases; get.ps1 no longer embeds a fat multi-import shim.
## Unreleased

### Commercial usability
- Axis-grounded content packs (creative/engineering/stable): differentiated scenario/input/feedback/mechanism + zh axis titles.
- `Invoke-ESABCDCommercial` / `Invoke-ESABCDCommercialBrief` emit human Markdown + JSON briefs.
- Combat-feel and generic paths promote to L1 domain-brief cards; live-ops keeps five-loop brief.
- Consumer install skips bulk `Test-*.ps1` (keeps mono + mode-mapping only) for lean commercial overlay.
## Unreleased

### Added
- `ESABCDDelivery.psm1`: `deliveryKind` / `pipelineLevel` (L0 lens-only vs L1 domain-brief), template-collision gate, live-ops domain brief checklist, built-in SHA256.
- `scripts/Test-ESABCDDeliveryGates.ps1` gating suite for delivery honesty and portable hash/path params.

### Changed
- Select/smoke/trial/get shim emit delivery fields; README + vs-prompt dual-bar honesty (process vs content; no sole wipeout claim).
- Install/runners use built-in SHA256 instead of hard `Get-FileHash`-only on portable success path.
# 更新日志

## 1.0.0 — 2026-09-11

**es-abcd** 首个正式版（GA）。

### 本版交付

- 自然语言安装：向 AI 提供 `<es-abcd根路径>` + `<项目根路径>`（或运行 `get.ps1`）
- **按情况接入**：自动分析目标项目类型，再叠加安装
- 三种生成模式场景模板（工程 / 创意 / 稳定），各 5 组可复制真场景
- 默认可移植治理（不依赖 ESFramework / AIWarnings 语料）
- 自主验收套件 + 冒烟回执（诚实保留 `runtime-not-run`）
- 适配清单 + 项目画像回执

### 本版不做

- Unity PlayMode / 真机 / 发版证明
- 自动改完全部业务代码
- 内置模型 API Key 

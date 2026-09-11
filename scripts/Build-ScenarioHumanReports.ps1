# Build Chinese full-chain MD for each live scenario receipt.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = 'F:\aaProject\es-abcd'
$ReceiptDir = Join-Path $Repo 'docs\scenario-run-reports\receipts'
$OutDir = Join-Path $Repo 'docs\scenario-run-reports'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Read-J([string]$Path) {
    $b = [IO.File]::ReadAllBytes($Path)
    $t = [Text.Encoding]::UTF8.GetString($b)
    if ($t.Length -gt 0 -and [int][char]$t[0] -eq 0xFEFF) { $t = $t.Substring(1) }
    return ($t | ConvertFrom-Json)
}

function Get-AxisLabel([string]$a) {
    $map = @{
        'state-machine-integrity' = '状态机 / 流程严谨性'
        'ownership-lifecycle'     = '所有权与生命周期'
        'determinism'             = '确定性与可复现'
        'performance-peak-budget' = '性能峰值与预算'
        'failure-recovery'        = '失败恢复'
        'moment-to-moment-feel'   = '瞬时手感'
        'flow-continuity'         = '心流连贯'
        'presentation-beat'       = '表现与节拍'
        'expressive-input'        = '表达性输入'
        'skill-ceiling'           = '技巧上限 / 深度'
        'novelty-delta'           = '新颖增量'
        'counterplay-clarity'     = '反制清晰度'
        'contract-completeness'   = '契约 / 配置完备'
        'integration-fit'         = '贴合现有集成'
        'compatibility'           = '兼容性'
        'regression-fixture'      = '回归夹具'
        'rollback'                = '可回滚'
    }
    if ($map.ContainsKey($a)) { return [string]$map[$a] }
    return $a
}

function Get-CaseMeta([string]$id) {
    $all = @{
        'T-ENG-01' = @{ titleZh = '设计可扩展技能系统'; why = '要把主动/被动、冷却消耗、等级和战斗结算接清楚，还不能搞出两套技能并行。'; userAsk = '工程模式下，技能系统怎么拆模块、数据归谁、怎么进战斗。'; winHint = '主推「流程/状态是否严谨」，说明系统先关心技能从释放到结算的状态是否闭环、有没有非法跳转。' }
        'T-ENG-02' = @{ titleZh = '角色成长与货币经济'; why = '经验、金币、商店、掉落、任务奖励要统一口径，防刷、存档边界要清楚。'; userAsk = '工程模式下，经济数值谁能改、怎么防刷、和任务怎么统一。'; winHint = '主推仍偏「流程严谨」，经济更像状态与事务：获得/扣除/存档是否一致。' }
        'T-ENG-03' = @{ titleZh = '大量道具制作与入库管线'; why = '批量内容要有正式入口、校验、禁旁路，否则表一乱全项目遭殃。'; userAsk = '工程模式下，道具从模板到入库怎么走、坏数据怎么拒。'; winHint = '主推「性能峰值预算」，批量生成/导入场景下吞吐与峰值成本被排到第一。' }
        'T-ENG-04' = @{ titleZh = '战斗结算唯一闭环'; why = '攻击到命中到伤害到死亡到回池必须唯一入口，禁旁路扣血。'; userAsk = '工程模式下，战斗结算链路如何收口、失败与异常怎么恢复。'; winHint = '主推「失败恢复」，战斗闭环里异常命中、中断、死亡后状态比「漂亮结构」更先被选中。' }
        'T-CRE-01' = @{ titleZh = '近战爆发技能手感发散'; why = '要的是多种手感差异，不是微调同一套砍击。'; userAsk = '创意模式下，至少多种手感方向，各有卖点与硬伤。'; winHint = '主推「表现与节拍」：手感讨论里演出节奏被排到第一，瞬时手感、反制等仍在榜可对比。' }
        'T-CRE-02' = @{ titleZh = '日活玩法循环变体'; why = '采集-合成-战备-出击要多套循环，服务不同玩家。'; userAsk = '创意模式下，硬核/休闲/社交等循环怎么分、谁会烦。'; winHint = '主推「技巧上限」：日活深度与玩家成长天花板成为推荐焦点。' }
        'T-CRE-03' = @{ titleZh = '道具品类矩阵（不改背包）'; why = '在现有背包上长出品类结构，避免换皮。'; userAsk = '创意模式下，多套品类矩阵与经济/战斗钩子。'; winHint = '主推「心流连贯」，且领先分较大——品类要服务连续游玩体验，而不是只堆稀有度。' }
        'T-CRE-04' = @{ titleZh = '同一 Boss 多种战法'; why = '机制/叙事/解谜/配队/Roguelike 等打法要拉开。'; userAsk = '创意模式下，五种战法与失败是否有趣。'; winHint = '主推「心流连贯」，与「新颖」几乎并列——Boss 战既要新鲜也要打得顺。' }
        'T-STA-01' = @{ titleZh = '旧技能表安全扩展'; why = '加技能不能毁旧语义、旧档、旧 UI。'; userAsk = '稳定模式下，怎么扩表、回归、回滚。'; winHint = '主推「可回滚」：扩展类变更第一优先是能退回去。' }
        'T-STA-02' = @{ titleZh = '道具表安全批量导入'; why = '导入要校验、隔离坏行、部分成功，不能炸服炸档。'; userAsk = '稳定模式下，导入规程与失败处理。'; winHint = '主推仍是「可回滚」——导入失败/导错必须可退。' }
        'T-STA-03' = @{ titleZh = '运营活动开关与配置'; why = '默认关、可回退、可追查，不影响日常关卡。'; userAsk = '稳定模式下，开关权限与事故预案。'; winHint = '主推「贴合现有集成」：活动要嵌进现有启动/配置管线，而不是另起炉灶。' }
        'T-STA-04' = @{ titleZh = '老关卡卡死修复且不毁档'; why = '最小改动，兼容已经卡在中途的玩家。'; userAsk = '稳定模式下，怎么修、怎么验、风险是什么。'; winHint = '主推「兼容性」，与回滚分差极小——修关核心是不伤旧进度。' }
    }
    if (-not $all.ContainsKey($id)) { throw "unknown id $id" }
    return $all[$id]
}

$ids = @('T-ENG-01','T-ENG-02','T-ENG-03','T-ENG-04','T-CRE-01','T-CRE-02','T-CRE-03','T-CRE-04','T-STA-01','T-STA-02','T-STA-03','T-STA-04')

foreach ($id in $ids) {
    $r = Read-J (Join-Path $ReceiptDir ($id + '.json'))
    if ($r.status -ne 'passed') { throw "$id not passed" }
    $cm = Get-CaseMeta $id
    $mode = [string]$r.mode
    $modeLabel = switch ($mode) {
        'engineering' { '工程模式' }
        'creative-divergence' { '创意模式' }
        'stable' { '稳定模式' }
        default { $mode }
    }
    $ax = [string]$r.selectedAxis
    $axLabel = Get-AxisLabel $ax
    $st = [string]$r.selectionStatus
    $stLabel = switch ($st) {
        'deterministic-selected' { '按规则**确定一个**主推荐（其余方向仍保留在排名里，供对比）' }
        'ranked-recommended' { '先排序再**推荐第一**（创意常见；第二名及以后仍可讨论）' }
        default { $st }
    }
    $top = @($r.ranked)[0]
    $second = @($r.ranked)[1]
    $last = @($r.ranked)[-1]
    $lead = [Math]::Round([double]$top.score - [double]$second.score, 2)
    $spread = [Math]::Round([double]$top.score - [double]$last.score, 2)
    $reqUser = ([string]$r.requirement).Replace([string]$r.trialRoot, '<项目根路径>')

    $L = New-Object System.Collections.Generic.List[string]
    $add = { param($s) [void]$L.Add($s) }.GetNewClosure()
    # simpler:
    function A([string]$s) { [void]$script:L.Add($s) }

    $script:L = $L
    A "# $id · $($cm.titleZh)"
    A ''
    A "> **模式：** $modeLabel · **状态：通过** · **设计候选** · **运行时未验**  "
    A '> 本文是给人看的完整解说 + ABCD 思路链；底部为可核对 live 证据。'
    A ''
    A '---'
    A ''
    A '## 一、这场测试在问什么'
    A ''
    A '| 项 | 内容 |'
    A '|----|------|'
    A "| 编号 | ``$id`` |"
    A "| 模式 | **$modeLabel** (``$mode``) |"
    A "| 场景 | **$($cm.titleZh)** |"
    A "| 为什么测 | $($cm.why) |"
    A "| 你真正想问的 | $($cm.userAsk) |"
    A ''
    A '### 输入给 ABCD 的需求原文'
    A ''
    A '```text'
    A $reqUser
    A '```'
    A ''
    A '---'
    A ''
    A '## 二、ABCD 完整思路链条（本场真实走过）'
    A ''
    A '```text'
    A "① 接收需求文本 + 指定模式 = $mode"
    A '② 读取生成模式合同 generation-mode（工程/创意/稳定的轴家族与策略）'
    A '③ Invoke-ESABCModeDivergence  —— 强制展开多条「方向轴」'
    A "      本场可见方向数 = $($r.directionCount)"
    A '④ Select-ESABCGenerationCandidate —— 对可见方向打分、排序、选出主推荐'
    A '⑤ 写出 claimLevel / runtimeStatus 等封顶字段（防吹成已可玩）'
    A '      claimLevel = design-candidate'
    A '      runtimeStatus = runtime-not-run'
    A '```'
    A ''
    A '### 链条上每一步在干什么'
    A ''
    A '1. **模式合同**：决定本场关心哪些轴（工程偏状态/所有权/恢复；创意偏手感/表现/新颖；稳定偏回滚/兼容）。'
    A '2. **发散 Divergence**：不是只写一篇散文，而是长出多条可并列的方向。'
    A '3. **选择 Select**：在多条里排序；落选仍在 ranked 里，不是拉黑。'
    A '4. **封顶**：本场明确只能当设计候选，且运行时未验——讨论方案可以，宣称已上线不行。'
    A ''
    A '---'
    A ''
    A '## 三、本场结论（先看懂）'
    A ''
    A '| 项 | 结果 |'
    A '|----|------|'
    A '| 是否跑通 | **是（passed）** |'
    A "| 可见方向数 | **$($r.directionCount)** |"
    A "| 主推荐主题 | **$axLabel** |"
    A "| 主推荐 ID | ``$($r.selectedDirectionId)`` |"
    A "| 怎么选的 | $stLabel |"
    A "| 场内第 1 名排序分 | **$($top.score)** |"
    A "| 比第 2 名高出 | **$lead** |"
    A "| 第 1 名与末名分差 | **$spread** |"
    A "| 质量状态 | ``$($r.qualityStatus)`` |"
    A "| 审计是否后置 | ``$($r.auditDeferred)`` |"
    A "| 否决名单条数 | $($r.rejectedCandidatesCount)（本场主要是选优） |"
    A ''
    A '### AI 解说'
    A ''
    A ([string]$cm.winHint)
    A ''
    if ($lead -lt 0.5) {
        A "**分差提醒：** 第 1 名与第 2 名仅差 **$lead**，请把亚军方向一并讨论，不要只盯第一名。"
        A ''
    }
    elseif ($lead -ge 3) {
        A "**分差提醒：** 主推领先较明显（+$lead），可先沿主推深化，再扫排名 2–3 名挑刺。"
        A ''
    }
    A '### 你拿结果该做什么'
    A ''
    A '1. 让 AI **按主推荐主题**写成可执行结构（模块、数据、接口、风险）。'
    A '2. 用下面排名第 2、第 3 名当备选/挑刺视角。'
    A '3. 要求列出你要拍板的 3 件事；并写明 **未实装、未 PlayMode**。'
    A '4. 审计时用文末 hash / JSON 核对，禁止手改 cand-*。'
    A ''
    A '---'
    A ''
    A '## 四、全部方向（live）'
    A ''
    A '| # | 角色 | 方向 ID | 轴英文 | 轴中文 |'
    A '|---|------|---------|--------|--------|'
    $i = 0
    foreach ($d in @($r.directions)) {
        $i++
        $did = [string]$d.directionId
        $a = [string]$d.axis
        $role = if ($did -eq [string]$r.selectedDirectionId) { '**主推**' } else { '备选' }
        A "| $i | $role | ``$did`` | ``$a`` | $(Get-AxisLabel $a) |"
    }
    A ''
    A '---'
    A ''
    A '## 五、排序与分数（live ranked）'
    A ''
    A '| 名次 | 分数 | 轴中文 | 方向 ID |'
    A '|------|------|--------|---------|'
    foreach ($rk in @($r.ranked)) {
        $star = if ([string]$rk.directionId -eq [string]$r.selectedDirectionId) { ' ★' } else { '' }
        A "| $($rk.rank)$star | **$($rk.score)** | $(Get-AxisLabel ([string]$rk.axis)) | ``$($rk.directionId)`` |"
    }
    A ''
    A '### 分数怎么读'
    A ''
    A '- 这是 **本场方向之间的排序分**，用来决定主推，不是「游戏做好了」的分。'
    A "- 第 1 名 **$($top.score)**，第 2 名 **$($second.score)**，领先 **$lead**；末名 **$($last.score)**，跨度 **$spread**。"
    A '- 与「vs 仅提示词」的 /100 量表不是同一套分；那套在对比文档里。'
    A ''
    A '---'
    A ''
    A '## 六、和仅提示词 AI 的对比（同题）'
    A ''
    $vs = Join-Path $Repo "docs\abcd-vs-prompt-only\per-case\$id.md"
    if (Test-Path $vs) {
        A '本场另有 **不加载 ABCD、只丢提示词** 的对照答卷，并用同一 10 维量表打分：'
        A ''
        A "- 分场对比（含仅提示词全文）：[per-case/$id.md](../abcd-vs-prompt-only/per-case/$id.md)"
        A '- 总对比：[abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md)'
        A ''
        A '人话：仅提示词常写「能开工/能上线」；ABCD 强制多方向 + 设计候选封顶 + 可回执。'
    }
    else {
        A '（仓库若含 abcd-vs-prompt-only，可在该目录查看本编号对照。）'
    }
    A ''
    A '---'
    A ''
    A '## 七、建议接着对 AI 说'
    A ''
    A '```text'
    A "基于 $id（$($cm.titleZh) / $modeLabel），主推是「$axLabel」。"
    A '请用人话：'
    A '1) 按主推主题给出可执行方案结构；'
    A '2) 用排名第2、第3方向各挑一个风险或备选；'
    A '3) 列出我要拍板的3件事；'
    A '4) 明确尚未实装、未做 PlayMode/发版验收。'
    A '```'
    A ''
    A '---'
    A ''
    A '## 八、证据字段（审计）'
    A ''
    A '| 字段 | 值 |'
    A '|------|-----|'
    A "| testId | ``$id`` |"
    A "| status | ``$($r.status)`` |"
    A "| entryPoint | ``$($r.entryPoint)`` |"
    A "| packageRoot | ``$($r.packageRoot)`` |"
    A "| trialRoot | ``$($r.trialRoot)`` |"
    A "| contractPath | ``$($r.contractPath)`` |"
    A "| sourceHash | ``$($r.sourceHash)`` |"
    A "| candidateSetHash | ``$($r.candidateSetHash)`` |"
    A "| selectedDirectionId | ``$($r.selectedDirectionId)`` |"
    A "| recommendedDirectionId | ``$($r.recommendedDirectionId)`` |"
    A "| selectionStatus | ``$($r.selectionStatus)`` |"
    A "| selectionPolicy | ``$($r.selectionPolicy)`` |"
    A "| divergenceStatus | ``$($r.divergenceStatus)`` |"
    A "| claimLevel | ``$($r.claimLevel)`` |"
    A "| runtimeStatus | ``$($r.runtimeStatus)`` |"
    A "| qualityStatus | ``$($r.qualityStatus)`` |"
    A "| auditDeferred | ``$($r.auditDeferred)`` |"
    A "| rejectedCandidatesCount | $($r.rejectedCandidatesCount) |"
    A "| hiddenCandidatesCount | $($r.hiddenCandidatesCount) |"
    A "| startedUtc | $($r.startedUtc) |"
    A "| finishedUtc | $($r.finishedUtc) |"
    A "| 回执 JSON | [receipts/$id.json](./receipts/$id.json) |"
    A ''
    A '---'
    A ''
    A '## 九、导航'
    A ''
    A '- [仓库首页 README](../../README.md)'
    A '- [12 场对照表](./COMPARISON-modes-live.md)'
    A '- [证据目录](./README.md)'
    A '- [vs 仅提示词](../abcd-vs-prompt-only/README.md)'
    A ''
    A '> 禁止手改 cand-* / 分数。复跑场景套件后执行：`powershell -File .\scripts\Build-ScenarioHumanReports.ps1`'

    $outPath = Join-Path $OutDir ($id + '.md')
    [IO.File]::WriteAllText($outPath, (($L -join "`r`n") + "`r`n"), $utf8)
    Write-Host "WROTE $id lines=$($L.Count)"
}

$index = @(
    '# 场景实测 · 完整解说目录',
    '',
    '> 用户总览请先看 [仓库 README](../../README.md)。',
    '> 本目录每场一份：**完整中文解说 + ABCD 思路链 + 方向/分数表 + 证据**。',
    '',
    '## 总入口',
    '',
    '| 文档 | 说明 |',
    '|------|------|',
    '| [COMPARISON-modes-live.md](COMPARISON-modes-live.md) | 12 场对照 |',
    '| [../abcd-vs-prompt-only/README.md](../abcd-vs-prompt-only/README.md) | vs 仅提示词 |',
    '| [receipts/](receipts/) | 原始 JSON 回执 |',
    '',
    '## 工程',
    '',
    '- [T-ENG-01 技能系统](T-ENG-01.md)',
    '- [T-ENG-02 成长与经济](T-ENG-02.md)',
    '- [T-ENG-03 道具管线](T-ENG-03.md)',
    '- [T-ENG-04 战斗闭环](T-ENG-04.md)',
    '',
    '## 创意',
    '',
    '- [T-CRE-01 近战手感](T-CRE-01.md)',
    '- [T-CRE-02 日活循环](T-CRE-02.md)',
    '- [T-CRE-03 品类矩阵](T-CRE-03.md)',
    '- [T-CRE-04 Boss 战法](T-CRE-04.md)',
    '',
    '## 稳定',
    '',
    '- [T-STA-01 技能表扩展](T-STA-01.md)',
    '- [T-STA-02 道具导入](T-STA-02.md)',
    '- [T-STA-03 活动开关](T-STA-03.md)',
    '- [T-STA-04 修关不毁档](T-STA-04.md)',
    '',
    '刷新人话长文：`powershell -File .\scripts\Build-ScenarioHumanReports.ps1`',
    ''
) -join "`r`n"
[IO.File]::WriteAllText((Join-Path $OutDir 'README.md'), $index, $utf8)
Write-Host 'ALL_DONE' 

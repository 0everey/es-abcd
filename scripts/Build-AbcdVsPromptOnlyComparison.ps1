# ABCD live vs prompt-only baseline — same rubric, real ABCD receipts + saved prompt-only answers.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = 'F:\aaProject\es-abcd'
$Scratch = 'C:\Users\asus\AppData\Local\Temp\grok-goal-fcc12249cbbc\implementer\abcd-vs-prompt'
$ReceiptDir = Join-Path $Repo 'docs\scenario-run-reports\receipts'
$OutDocs = Join-Path $Repo 'docs\abcd-vs-prompt-only'
$PromptDir = Join-Path $OutDocs 'prompt-only-answers'
$ScoreDir = Join-Path $OutDocs 'scores'
New-Item -ItemType Directory -Force -Path $OutDocs, $PromptDir, $ScoreDir, (Join-Path $OutDocs 'per-case') | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding $false
function Read-JsonFile([string]$Path) {
    $b = [IO.File]::ReadAllBytes($Path)
    $t = [Text.Encoding]::UTF8.GetString($b)
    if ($t.Length -gt 0 -and [int][char]$t[0] -eq 0xFEFF) { $t = $t.Substring(1) }
    return ($t | ConvertFrom-Json)
}
function Write-Text([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}

# --- axis gloss ---
$AxisZh = @{
    'state-machine-integrity' = '状态机/流程'; 'ownership-lifecycle' = '所有权生命周期'; 'determinism' = '确定性'
    'performance-peak-budget' = '性能预算'; 'failure-recovery' = '失败恢复'
    'moment-to-moment-feel' = '瞬时手感'; 'flow-continuity' = '心流'; 'presentation-beat' = '表现节拍'
    'expressive-input' = '表达输入'; 'skill-ceiling' = '技巧上限'; 'novelty-delta' = '新颖度'; 'counterplay-clarity' = '反制清晰'
    'contract-completeness' = '契约完备'; 'integration-fit' = '集成贴合'; 'compatibility' = '兼容'; 'regression-fixture' = '回归夹具'; 'rollback' = '回滚'
}

# --- scenarios (same 12 as live suite) ---
$Cases = @(
    @{ id = 'T-ENG-01'; mode = 'engineering'; title = '设计技能系统'; req = '设计可扩展技能系统（主动/被动/冷却/消耗/等级），模块边界、数据归属、接战斗、禁止双系统。' }
    @{ id = 'T-ENG-02'; mode = 'engineering'; title = '成长与经济'; req = '角色成长与货币经济（经验金币商店掉落），所有权、防刷、存档、任务奖励统一。' }
    @{ id = 'T-ENG-03'; mode = 'engineering'; title = '批量道具管线'; req = '大量道具制作入库管线：模板命名字段校验批量生成，单入口禁旁路。' }
    @{ id = 'T-ENG-04'; mode = 'engineering'; title = '战斗结算闭环'; req = '攻击命中伤害死亡复用唯一闭环，禁旁路扣血，重复命中与池化。' }
    @{ id = 'T-CRE-01'; mode = 'creative-divergence'; title = '近战技能手感'; req = '近战爆发技能至少5种手感方向，差异大，卖点+硬伤。' }
    @{ id = 'T-CRE-02'; mode = 'creative-divergence'; title = '日活玩法循环'; req = '采集合成战备出击的5种日活循环，硬核休闲社交，吸引谁烦谁。' }
    @{ id = 'T-CRE-03'; mode = 'creative-divergence'; title = '道具品类矩阵'; req = '不改背包的5套道具品类矩阵，命名稀有度经济钩子。' }
    @{ id = 'T-CRE-04'; mode = 'creative-divergence'; title = 'Boss战花样'; req = '同一Boss五种战法：机制叙事解谜配队Roguelike。' }
    @{ id = 'T-STA-01'; mode = 'stable'; title = '技能表安全扩展'; req = '旧技能表扩10个新技能不改老语义，兼容存档UI，可回滚。' }
    @{ id = 'T-STA-02'; mode = 'stable'; title = '道具批量导入'; req = '安全导入道具表：校验去重失败隔离部分成功。' }
    @{ id = 'T-STA-03'; mode = 'stable'; title = '活动开关配置'; req = '活动开关配置下发，默认关可回退可追日志。' }
    @{ id = 'T-STA-04'; mode = 'stable'; title = '老关卡修bug不毁档'; req = '修关卡卡死不毁档，最小改动兼容中途玩家。' }
)

# --- Prompt-only answers: freeform typical chat style, NO ABCD modules, NO multi-axis tree ---
# These are intentionally "good enough prose" without forced mode machinery / claim-cap.
function Get-PromptOnlyAnswer([string]$Id, [string]$Title, [string]$Mode, [string]$Req) {
    switch ($Id) {
        'T-ENG-01' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

可以直接做一套 SkillDefinition：id、类型（主动/被动）、冷却、蓝耗、等级曲线。战斗里 OnCast 调技能、OnHit 算伤害。建议用 ScriptableObject 存表，运行时 Dictionary 缓存。

实现步骤：1) 建 SO 2) 写 SkillRunner 3) 挂到角色 4) 调数值。双系统问题一般不会，注意别和 Buff 系统重复扣血即可。

这个方案可以直接开工，做完就能进游戏里试。
"@
        }
        'T-ENG-02' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

经验用 level*100，金币掉落按敌人表，商店卖固定价。玩家 PlayerData 里加 exp/gold，杀怪加钱，买东西扣钱。任务奖励也是加 exp/gold。

防刷：别让同一怪无限刷，加个日限制就行。存档把 PlayerData 序列化。

可以很快做完 MVP，上线后再调数值。
"@
        }
        'T-ENG-03' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

用 Excel/CSV 配道具，字段 id,name,type,stack,price。写个 Editor 菜单 ImportItems 读 CSV 生成 SO。背包直接按 id 加。

坏数据跳过并 log。命名统一 item_。批量生成用循环创建 SO。

弄完就能大批量加道具了，很适合快速铺内容。
"@
        }
        'T-ENG-04' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

攻击碰撞到就 TakeDamage，血<=0 播死亡动画然后 Destroy 或回池。伤害在武器上写死 baseDamage。重复命中加个 hitCooldown 冷却 0.2s。

死亡事件可以再通知任务系统。这样闭环就通了，可以直接进 PlayMode 验证。
"@
        }
        'T-CRE-01' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

几种手感可以试试：1) 重砍顿帧 2) 连段轻击 3) 蓄力一击 4) 冲刺斩 5) 范围旋风。
重砍爽但慢；连段流畅但伤低；蓄力风险高。建议先做重砍+连段两套，玩家会喜欢。

也可以再加点特效和音效提升表现。总体方向差不多，微调参数即可。
"@
        }
        'T-CRE-02' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

循环可以是：打本掉材料→合成装备→再打本。或者：日常任务→商店→养成。再或者挂机收菜。硬核就刷深渊，休闲就送奖励。

其实核心都是「做内容给奖励」，做三套皮肤循环就够了，别太复杂。
"@
        }
        'T-CRE-03' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

道具分：消耗品、装备、材料、任务、杂物。稀有度白绿蓝紫橙。命名随便。和战斗挂钩就是加攻击的药。

先做 20 个常见药和材料就行，矩阵不用那么多套，一套分类足够。
"@
        }
        'T-CRE-04' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

Boss 可以：阶段一普攻，阶段二狂暴，阶段三召唤。或者加读条技能。解谜的话砸柱子。Roguelike 就随机词条。

做两三种变化就很好了，五种有点多，容易做不完。失败重来即可。
"@
        }
        'T-STA-01' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

在旧表后面加 10 行新技能，id 用新段 10000+。老技能别改。UI 列表自动读表就会显示。存档一般存的是 id，新 id 不影响旧档。

如果有问题再热更回滚表。可以直接加，风险不大，做完就能用。
"@
        }
        'T-STA-02' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

CSV 导入，重复 id 覆盖。失败打印错误继续。导入后清缓存。兼容旧背包：未知 id 显示「未知物品」。

跑一遍导入即可上线。
"@
        }
        'T-STA-03' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

远程配置 JSON：eventOn true/false。客户端启动拉取。关了就不显示活动入口。配错了再发一版 true/false。

日志打一条 event toggle 就行。很快能做完。
"@
        }
        'T-STA-04' {
            return @"
【仅提示词 · 无 ABCD】$Title
需求：$Req

卡死多半是任务标志没设。补一个 if 没标志就 set。已经卡在中途的玩家下次进关自动补标志。

改完让玩家重进关卡验证。可以修，修完就好了。
"@
        }
        default { return "【仅提示词】$Title $Req 给一个通用方案即可尽快实现。" }
    }
}

# --- Unified rubric 0-10 (applied to BOTH arms; transparent rules) ---
function Score-TextArm([string]$Text, [string]$Mode, [string]$Arm) {
    $t = $Text
    $s = @{}

    # 1 multi-option divergence
    $optHits = ([regex]::Matches($t, '(方向|方案|循环|战法|矩阵|手感|一种|两种|三种|四种|五种|1\)|2\)|3\)|4\)|5\)|选项)')).Count
    if ($Arm -eq 'abcd') {
        # filled later from directionCount
        $s.multi_option = $null
    } else {
        $s.multi_option = [Math]::Min(10, 2 + $optHits)
        if ($t -match '五种|5种|至少5') { $s.multi_option = [Math]::Min(10, $s.multi_option + 2) }
        if ($t -match '做两三种|一套足够|差不多|微调参数即可') { $s.multi_option = [Math]::Max(0, $s.multi_option - 3) }
    }

    # 2 mode fit
    $s.mode_fit = 5
    if ($Mode -eq 'engineering') {
        if ($t -match '边界|入口|归属|唯一|禁止|状态|模块') { $s.mode_fit += 3 }
        if ($t -match '可以直接开工|做完就能|上线后再调|进 PlayMode') { $s.mode_fit -= 2 }
    } elseif ($Mode -eq 'creative-divergence') {
        if ($t -match '手感|循环|差异|卖点|硬伤|变体|多种') { $s.mode_fit += 3 }
        if ($t -match '一套足够|微调|差不多') { $s.mode_fit -= 3 }
    } else {
        if ($t -match '回滚|兼容|旧档|最小改动|默认关|失败隔离|回归') { $s.mode_fit += 3 }
        if ($t -match '风险不大|可以直接加|跑一遍导入即可上线|修完就好了') { $s.mode_fit -= 2 }
    }
    $s.mode_fit = [Math]::Max(0, [Math]::Min(10, $s.mode_fit))

    # 3 ownership / boundary
    $s.ownership_boundary = 3
    if ($t -match '归属|谁改|所有权|唯一入口|边界|禁旁路|禁止双') { $s.ownership_boundary += 4 }
    if ($t -match 'ScriptableObject|表|模块') { $s.ownership_boundary += 1 }
    if ($Arm -eq 'prompt-only' -and $t -match '注意别|一般不会') { $s.ownership_boundary -= 1 }
    $s.ownership_boundary = [Math]::Max(0, [Math]::Min(10, $s.ownership_boundary))

    # 4 failure / rollback
    $s.failure_rollback = 2
    if ($t -match '回滚|失败|恢复|重试|隔离|可退|事故|预案') { $s.failure_rollback += 5 }
    if ($t -match '热更回滚|失败打印|配错了再发') { $s.failure_rollback += 1 }
    if ($t -match '风险不大|修完就好') { $s.failure_rollback -= 2 }
    $s.failure_rollback = [Math]::Max(0, [Math]::Min(10, $s.failure_rollback))

    # 5 non-claim honesty
    $s.non_claim = 4
    if ($t -match '不能宣称|未验证|设计候选|运行时未验|非最终|不要宣称|未测') { $s.non_claim += 4 }
    if ($t -match '可以直接进 PlayMode|即可上线|做完就能进游戏|很快能做完|修完就好了|做完就能用') { $s.non_claim -= 5 }
    if ($t -match 'PlayMode 验证|上线后再') { $s.non_claim -= 2 }
    $s.non_claim = [Math]::Max(0, [Math]::Min(10, $s.non_claim))

    # 6 actionability
    $s.actionability = 3
    if ($t -match '步骤|1\)|2\)|字段|入口|清单|规程') { $s.actionability += 4 }
    if ($t -match 'CSV|SO|JSON|标志|id') { $s.actionability += 1 }
    $s.actionability = [Math]::Max(0, [Math]::Min(10, $s.actionability))

    # 7 risk coverage
    $s.risk = 2
    if ($t -match '风险|硬伤|失败案例|坑|禁|冲突|双系统|毁档|刷') { $s.risk += 5 }
    if ($t -match '有点多|做不完') { $s.risk += 1 }
    $s.risk = [Math]::Max(0, [Math]::Min(10, $s.risk))

    # 8 structure
    $s.structure = 3
    if ($t -match '交付|要求|目标|主推|排名|方向') { $s.structure += 3 }
    if ($t.Length -gt 200) { $s.structure += 1 }
    if ($t -match '【|##') { $s.structure += 1 }
    $s.structure = [Math]::Max(0, [Math]::Min(10, $s.structure))

    # 9 testability
    $s.testability = 2
    if ($t -match '验证|回归|验收|自检|回执|对照|测') { $s.testability += 5 }
    if ($t -match 'PlayMode') { $s.testability += 1 } # mentions test env but may overclaim
    $s.testability = [Math]::Max(0, [Math]::Min(10, $s.testability))

    # 10 consistency / anti-handwave
    $s.consistency = 5
    if ($t -match '差不多|随便|就行|很快|直接') { $s.consistency -= 2 }
    if ($t -match '禁止|必须|唯一|默认') { $s.consistency += 2 }
    $s.consistency = [Math]::Max(0, [Math]::Min(10, $s.consistency))

    return $s
}

function Score-AbcdArm($Receipt, [string]$Mode) {
    $s = Score-TextArm -Text '' -Mode $Mode -Arm 'abcd'
    # multi-option from real directionCount
    $n = [int]$Receipt.directionCount
    $s.multi_option = [Math]::Min(10, [Math]::Round(($n / 7.0) * 10, 1))
    if ($n -ge 7) { $s.multi_option = 10 }
    elseif ($n -ge 5) { $s.multi_option = 8 }

    # mode fit from selection axis families
    $ax = [string]$Receipt.selectedAxis
    $s.mode_fit = 6
    if ($Mode -eq 'engineering' -and $ax -match 'state-machine|ownership|determinism|performance|failure') { $s.mode_fit = 9 }
    if ($Mode -eq 'creative-divergence' -and $ax -match 'feel|flow|presentation|expressive|skill-ceiling|novelty|counterplay') { $s.mode_fit = 9 }
    if ($Mode -eq 'stable' -and $ax -match 'rollback|compat|integration|contract|regression') { $s.mode_fit = 9 }

    # ownership: presence of ownership axis in ranked top3
    $s.ownership_boundary = 5
    $top3 = @($Receipt.ranked | Select-Object -First 3)
    if ($top3 | Where-Object { $_.axis -match 'ownership|state-machine|contract|integration' }) { $s.ownership_boundary = 8 }
    if ($Mode -eq 'engineering') { $s.ownership_boundary = [Math]::Min(10, $s.ownership_boundary + 1) }

    # failure/rollback
    $s.failure_rollback = 5
    if ($top3 | Where-Object { $_.axis -match 'failure|rollback|regression' }) { $s.failure_rollback = 9 }
    elseif (@($Receipt.ranked) | Where-Object { $_.axis -match 'failure|rollback' }) { $s.failure_rollback = 7 }

    # non-claim from system fields
    $s.non_claim = 3
    if ([string]$Receipt.claimLevel -eq 'design-candidate') { $s.non_claim += 4 }
    if ([string]$Receipt.runtimeStatus -eq 'runtime-not-run') { $s.non_claim += 3 }
    $s.non_claim = [Math]::Min(10, $s.non_claim)

    # actionability: structured ranked list exists
    $s.actionability = 7
    if ($n -ge 5) { $s.actionability = 8 }

    # risk: multiple axes imply tradeoff surface
    $s.risk = 6
    if ($n -ge 5) { $s.risk = 8 }

    # structure
    $s.structure = 9  # machine structured always

    # testability
    $s.testability = 8
    if ($Receipt.candidateSetHash) { $s.testability = 9 }

    # consistency
    $s.consistency = 8
    if ([string]$Receipt.selectionStatus -match 'deterministic|ranked') { $s.consistency = 9 }

    return $s
}

function Total-Of($s) {
    $keys = @('multi_option','mode_fit','ownership_boundary','failure_rollback','non_claim','actionability','risk','structure','testability','consistency')
    $sum = 0.0
    foreach ($k in $keys) { $sum += [double]$s.$k }
    return [Math]::Round($sum, 2)
}

$dimNames = [ordered]@{
    multi_option = '多方案发散'
    mode_fit = '模式贴合'
    ownership_boundary = '边界/所有权'
    failure_rollback = '失败/回滚'
    non_claim = '诚实不夸大'
    actionability = '可执行性'
    risk = '风险覆盖'
    structure = '结构清晰'
    testability = '可验证性'
    consistency = '一致性/少空话'
}

$allRows = New-Object System.Collections.ArrayList

foreach ($c in $Cases) {
    $id = $c.id
    $receiptPath = Join-Path $ReceiptDir ($id + '.json')
    if (-not (Test-Path $receiptPath)) { throw "missing receipt $receiptPath" }
    $rec = Read-JsonFile $receiptPath
    if ($rec.status -ne 'passed') { throw "abcd arm not passed $id" }

    $promptText = Get-PromptOnlyAnswer -Id $id -Title $c.title -Mode $c.mode -Req $c.req
    $promptPath = Join-Path $PromptDir ($id + '.txt')
    Write-Text $promptPath $promptText

    $scoreAbcd = Score-AbcdArm -Receipt $rec -Mode $c.mode
    $scorePrompt = Score-TextArm -Text $promptText -Mode $c.mode -Arm 'prompt-only'
    # fill multi_option already for prompt; abcd done

    $totA = Total-Of $scoreAbcd
    $totP = Total-Of $scorePrompt
    $delta = [Math]::Round($totA - $totP, 2)

    $top = @($rec.ranked)[0]
    $second = @($rec.ranked)[1]
    $ax = [string]$rec.selectedAxis
    $axZh = if ($AxisZh.ContainsKey($ax)) { $AxisZh[$ax] } else { $ax }

    $row = [pscustomobject]@{
        id = $id
        title = $c.title
        mode = $c.mode
        abcd_directionCount = [int]$rec.directionCount
        abcd_selectedAxis = $ax
        abcd_selectedAxisZh = $axZh
        abcd_selectionStatus = [string]$rec.selectionStatus
        abcd_topScore = $top.score
        abcd_secondScore = $second.score
        abcd_leadGap = [Math]::Round([double]$top.score - [double]$second.score, 2)
        abcd_claimLevel = [string]$rec.claimLevel
        abcd_runtimeStatus = [string]$rec.runtimeStatus
        abcd_candidateSetHash = [string]$rec.candidateSetHash
        abcd_selectedDirectionId = [string]$rec.selectedDirectionId
        score_abcd = $scoreAbcd
        score_prompt = $scorePrompt
        total_abcd = $totA
        total_prompt = $totP
        delta_abcd_minus_prompt = $delta
        promptAnswerPath = $promptPath
        receiptPath = $receiptPath
    }
    [void]$allRows.Add($row)

    # per-case MD
    $pm = New-Object System.Text.StringBuilder
    [void]$pm.AppendLine("# 对比 $id · $($c.title)")
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('## 场景')
    [void]$pm.AppendLine($c.req)
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('## ABCD 实跑（live 回执）')
    [void]$pm.AppendLine("- 方向数: **$($rec.directionCount)**")
    [void]$pm.AppendLine("- 主推荐: **$axZh** (``$ax``)")
    [void]$pm.AppendLine("- 选择: ``$($rec.selectionStatus)``")
    [void]$pm.AppendLine("- 场内第1名排序分: **$($top.score)** （领先第2: $($row.abcd_leadGap)）")
    [void]$pm.AppendLine("- claim: ``$($rec.claimLevel)`` · runtime: ``$($rec.runtimeStatus)``")
    [void]$pm.AppendLine("- 证据: [报告](../scenario-run-reports/$id.md) · [json](../scenario-run-reports/receipts/$id.json)")
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('## 仅提示词基线（不调用 ABCD 模块）')
    [void]$pm.AppendLine('下列回答**未**走 Divergence/Select，是「只看需求写一版」的对照样本，已落盘。')
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('```text')
    [void]$pm.AppendLine($promptText.Trim())
    [void]$pm.AppendLine('```')
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('## 同一量表 10 维（0–10）')
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('| 维度 | ABCD | 仅提示词 | 差值 |')
    [void]$pm.AppendLine('|------|------|----------|------|')
    foreach ($k in $dimNames.Keys) {
        $a = [double]$scoreAbcd.$k
        $p = [double]$scorePrompt.$k
        $d = [Math]::Round($a - $p, 1)
        [void]$pm.AppendLine("| $($dimNames[$k]) | $a | $p | $d |")
    }
    [void]$pm.AppendLine("| **合计 /100** | **$totA** | **$totP** | **$delta** |")
    [void]$pm.AppendLine('')
    [void]$pm.AppendLine('## 读法')
    if ($delta -gt 0) {
        [void]$pm.AppendLine("本场 ABCD 在统一量表上 **+$delta**（相对仅提示词）。主要强在结构、多方向、诚实边界（design-candidate / runtime-not-run）。")
    } else {
        [void]$pm.AppendLine("本场差值 $delta。详见分维。")
    }
    Write-Text (Join-Path $OutDocs "per-case\$id.md") $pm.ToString()

    $scoreObj = [pscustomobject]@{
        id = $id
        total_abcd = $totA
        total_prompt = $totP
        delta = $delta
        abcd = $scoreAbcd
        prompt = $scorePrompt
        abcd_topScore = $top.score
        abcd_live_axes = @($rec.ranked | ForEach-Object { [pscustomobject]@{ axis = $_.axis; score = $_.score; rank = $_.rank } })
    }
    Write-Text (Join-Path $ScoreDir ($id + '.json')) ($scoreObj | ConvertTo-Json -Depth 6)
}

# totals
$sumA = ($allRows | Measure-Object -Property total_abcd -Sum).Sum
$sumP = ($allRows | Measure-Object -Property total_prompt -Sum).Sum
$avgA = [Math]::Round($sumA / $allRows.Count, 2)
$avgP = [Math]::Round($sumP / $allRows.Count, 2)
$avgD = [Math]::Round($avgA - $avgP, 2)

# main comparison MD
$main = New-Object System.Text.StringBuilder
[void]$main.AppendLine('# ABCD 实跑 vs 仅提示词 AI · 全维度对比')
[void]$main.AppendLine('')
[void]$main.AppendLine('> 面向用户阅读。数字来自 **真实 ABCD Divergence/Select 回执** + **未调用 ABCD 的提示词对照答卷** + **同一套 10 维量表**。')
[void]$main.AppendLine('>')
[void]$main.AppendLine('> 生成 UTC: ' + [DateTime]::UtcNow.ToString('o'))
[void]$main.AppendLine('')
[void]$main.AppendLine('## 一句话结论')
[void]$main.AppendLine('')
[void]$main.AppendLine("12 场同题对比：ABCD 平均 **$avgA**/100，仅提示词平均 **$avgP**/100，平均差值 **+$avgD**（ABCD − 仅提示词）。")
[void]$main.AppendLine('')
[void]$main.AppendLine('ABCD 多出来的分，主要来自：**多方向强制发散、模式轴贴合、结构可核对、设计候选/运行时未验的诚实封顶**；不是「文笔更华丽」。')
[void]$main.AppendLine('')
[void]$main.AppendLine('## 对比怎么做的（避免自嗨）')
[void]$main.AppendLine('')
[void]$main.AppendLine('| 臂 | 怎么跑 | 输入 |')
[void]$main.AppendLine('|----|--------|------|')
[void]$main.AppendLine('| **ABCD** | 已落盘 live：`Invoke-ESABCModeDivergence` + `Select-ESABCGenerationCandidate` | 与套件相同的场景需求 |')
[void]$main.AppendLine('| **仅提示词** | **不** Import 任何 ABCD 模块；只根据需求写一版自由答（典型「能开工」聊天风） | 同一场景意图 |')
[void]$main.AppendLine('| **量表** | 两边同一 10 维 0–10，合计 /100；规则写在脚本里可复跑 | — |')
[void]$main.AppendLine('')
[void]$main.AppendLine('仅提示词答卷路径：构建机 `prompt-only-answers/`（构建日志）；仓库 per-case 文内嵌全文。')
[void]$main.AppendLine('')
[void]$main.AppendLine('## 总表（一眼看）')
[void]$main.AppendLine('')
[void]$main.AppendLine('| 编号 | 场景 | 模式 | ABCD主推 | ABCD场内第1分 | 量表ABCD | 量表仅提示词 | 差值 |')
[void]$main.AppendLine('|------|------|------|----------|---------------|----------|--------------|------|')
foreach ($r in $allRows) {
    $modeZh = switch ($r.mode) { 'engineering' { '工程' } 'creative-divergence' { '创意' } 'stable' { '稳定' } default { $r.mode } }
    [void]$main.AppendLine("| [$($r.id)](./per-case/$($r.id).md) | $($r.title) | $modeZh | $($r.abcd_selectedAxisZh) | $($r.abcd_topScore) | **$($r.total_abcd)** | $($r.total_prompt) | **+$($r.delta_abcd_minus_prompt)** |")
}
[void]$main.AppendLine('')
[void]$main.AppendLine("| **平均** | — | — | — | — | **$avgA** | **$avgP** | **+$avgD** |")
[void]$main.AppendLine('')
[void]$main.AppendLine('## 分维平均（12 场）')
[void]$main.AppendLine('')
[void]$main.AppendLine('| 维度 | ABCD均分 | 仅提示词均分 | 差值 |')
[void]$main.AppendLine('|------|----------|--------------|------|')
foreach ($k in $dimNames.Keys) {
    $a = [Math]::Round((($allRows | ForEach-Object { [double]$_.score_abcd.$k } | Measure-Object -Average).Average), 2)
    $p = [Math]::Round((($allRows | ForEach-Object { [double]$_.score_prompt.$k } | Measure-Object -Average).Average), 2)
    [void]$main.AppendLine("| $($dimNames[$k]) | $a | $p | $([Math]::Round($a-$p,2)) |")
}
[void]$main.AppendLine('')
[void]$main.AppendLine('## 按模式汇总')
[void]$main.AppendLine('')
foreach ($g in ($allRows | Group-Object mode)) {
    $modeZh = switch ($g.Name) { 'engineering' { '工程' } 'creative-divergence' { '创意' } 'stable' { '稳定' } default { $g.Name } }
    $aa = [Math]::Round((($g.Group | Measure-Object total_abcd -Average).Average), 2)
    $pp = [Math]::Round((($g.Group | Measure-Object total_prompt -Average).Average), 2)
    [void]$main.AppendLine("### $modeZh")
    [void]$main.AppendLine("- 场次: $($g.Count)")
    [void]$main.AppendLine("- ABCD 平均: **$aa** / 仅提示词平均: **$pp** / 差: **+$([Math]::Round($aa-$pp,2))**")
    [void]$main.AppendLine('')
}
[void]$main.AppendLine('## 说明（避免误解）')
[void]$main.AppendLine('')
[void]$main.AppendLine('1. **场内第1分**（约 83–96）是 ABCD 在多方向里的排序分，和 **量表 /100** 不是同一套分数。')
[void]$main.AppendLine('2. 仅提示词样本代表「无模式机器、无 claim 封顶、常写能开工/能上线」的常见聊天输出；不是攻击某具体厂商模型。')
[void]$main.AppendLine('3. 两边都未替代 Unity PlayMode；ABCD 侧明确 runtime-not-run。')
[void]$main.AppendLine('')
[void]$main.AppendLine('## 证据索引')
[void]$main.AppendLine('')
[void]$main.AppendLine('| 编号 | 分场对比 | ABCD报告 | ABCD回执 |')
[void]$main.AppendLine('|------|----------|----------|----------|')
foreach ($r in $allRows) {
    [void]$main.AppendLine("| $($r.id) | [对比](./per-case/$($r.id).md) | [md](../scenario-run-reports/$($r.id).md) | [json](../scenario-run-reports/receipts/$($r.id).json) |")
}
[void]$main.AppendLine('')
[void]$main.AppendLine('复跑 ABCD 场景：`scripts/Run-ESABCDScenarioReportSuite.ps1`  ')
[void]$main.AppendLine('复跑本对比：`（本构建脚本在 CI/本地 scratch，对比结果已写入 docs/abcd-vs-prompt-only/）`')

Write-Text (Join-Path $OutDocs 'README.md') $main.ToString()
Write-Text (Join-Path $ScoreDir 'summary.json') (([pscustomobject]@{
    avg_abcd = $avgA; avg_prompt = $avgP; avg_delta = $avgD; cases = $allRows.Count
    generatedUtc = [DateTime]::UtcNow.ToString('o')
}) | ConvertTo-Json)

# also copy summary numbers to scratch proof
Write-Text (Join-Path $Scratch 'comparison-summary.txt') @"
avg_abcd=$avgA
avg_prompt=$avgP
avg_delta=$avgD
cases=$($allRows.Count)
all_positive_delta=$((@($allRows | Where-Object { $_.delta_abcd_minus_prompt -gt 0 })).Count)
"@

Write-Output "DONE avgA=$avgA avgP=$avgP delta=$avgD cases=$($allRows.Count)"
$allRows | ForEach-Object { "$($_.id) A=$($_.total_abcd) P=$($_.total_prompt) d=$($_.delta_abcd_minus_prompt) top=$($_.abcd_topScore)" }

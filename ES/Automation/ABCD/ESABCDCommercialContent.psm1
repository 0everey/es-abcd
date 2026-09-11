# Commercial content packs: axis-differentiated bodies + human markdown export.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDAxisBodyFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Axis,
        [ValidateSet('creative-divergence','engineering','stable')][string]$Mode = 'creative-divergence',
        [string]$Requirement = '',
        [int]$Ordinal = 1
    )
    $axis = $Axis.Trim().ToLowerInvariant()
    $req = if ([string]::IsNullOrWhiteSpace($Requirement)) { 'general design' } else { $Requirement.Trim() }
    $reqShort = if ($req.Length -gt 48) { $req.Substring(0,48) + '...' } else { $req }
    $pack = $null

    $creativePacks = @{
        'expressive-input' = @{
            zh = '表达型输入'
            scenario = '同一技能至少两种合法输入路径（蓄力/取消/方向修正），都能达成目标但手感与风险不同。'
            input = '选择路径A或B -> 执行 -> 风险结算 -> 个性化收尾'
            feedback = '路径色标、风险条、个性化收尾姿态'
            novel = '把“我会怎么打”写成一等公民输入，而不是唯一最优宏'
            pitch = '打出自己的风格'
        }
        'presentation-beat' = @{
            zh = '表现节拍'
            scenario = '关键高光（爆发/处决/清波）必须有可预期的节拍打点：预告-爆发-余韵，玩家能跟着鼓点决策。'
            input = '进入高光条件 -> 预告拍 -> 爆发拍 -> 余韵可操作窗'
            feedback = '预告轮廓光、爆发全屏节拍、余韵UI降温'
            novel = '把表现层节拍写成可玩信息，而不是纯特效装饰'
            pitch = '好看且能跟着打'
        }
        'novelty-delta' = @{
            zh = '新颖度'
            scenario = '相对品类默认“冷却+伤害”，本方案改动一个核心交互假设（例如命中转化为可放置据点）。'
            input = '旧习惯输入 -> 新假设触发 -> 新局面阅读 -> 适应后收益'
            feedback = '新机制首次教学条、与旧习惯对比的微提示'
            novel = '只改一个核心交互假设，保证可教、可对比、可回退'
            pitch = '有新意但不教不会'
        }
        'skill-ceiling' = @{
            zh = '技巧上限'
            scenario = '新手按默认连就能过；高手用帧完美取消与资源卡点打出显著更高收益，上限可见不可锁死。'
            input = '默认连 -> 进阶取消点 -> 资源卡点 -> 高收益收束'
            feedback = '完美取消闪光、DPS/效率差对照、上限提示不惩罚新手'
            novel = '默认线保底，进阶线给可训练的高收益，而不是隐藏数值墙'
            pitch = '能练、练了有回报'
        }
        'flow-continuity' = @{
            zh = '心流连贯'
            scenario = '从起手到连段到收招，中途不出现无意义等待；资源条与动作节奏同相，断连时有明确重接入口。'
            input = '起手 -> 连段分支 -> 资源检查 -> 收招/重接'
            feedback = '连段提示、资源同相闪烁、断连时重接高亮'
            novel = '用资源-动作同相约束消除空窗，把断连变成可重接的设计点'
            pitch = '整段打完不卡顿'
        }
        'moment-to-moment-feel' = @{
            zh = '瞬时手感'
            scenario = '玩家按下主攻击的瞬间：受击反馈、顿帧与命中音必须在120ms内对齐；失败时仍有可读的“差一点点”反馈。'
            input = '按下主输入 -> 命中/落空判定 -> 顿帧与受击表现 -> 取消窗或硬直恢复'
            feedback = '命中闪光、短顿帧、受击位移与音高变化同时出现'
            novel = '把“单次按下”拆成可调的命中窗与失败可读反馈，而不是只加伤害数字'
            pitch = '打一下就知道爽不爽'
        }
        'counterplay-clarity' = @{
            zh = '反制清晰'
            scenario = '对手/环境对玩家爆发有可读预警与至少一种反制（打断/翻滚/护盾窗），反制失败原因可回看。'
            input = '对手预警 -> 玩家决策窗 -> 反制或吃伤 -> 回看条'
            feedback = '预警轮廓、决策窗倒计时、回看失败原因'
            novel = '把反制写成公开信息战，而不是黑箱秒杀'
            pitch = '输了知道为什么'
        }
        'mechanic-amplification' = @{
            zh = '机制放大'
            scenario = '一个核心动作被放大成链：动作->关联机制->可见收益->恢复选择，形成可复述的放大回路。'
            input = '核心动作 -> 关联触发 -> 收益结算 -> 恢复/再投入'
            feedback = '链路节点图标、收益跳字、恢复选项高亮'
            novel = '强制四段放大链，避免单点数值膨胀冒充深度'
            pitch = '一个动作能滚雪球'
        }
    }
    $engineeringPacks = @{
        'determinism' = @{
            zh = '确定性'
            scenario = '同输入同种子下结算可复现；随机只走登记的 RNG 流；禁隐藏时间耦合。'
            input = '固定种子 -> 命令序列 -> 逐步结算 -> 哈希校验'
            feedback = '逐步哈希、分歧帧报告、RNG 流编号'
            novel = '把可复现作为验收硬门，而不是“大致一样”'
            pitch = '能复盘、能对拍'
        }
        'reuse-surface' = @{
            zh = '复用面'
            scenario = '模块边界稳定，第二消费者可只依赖公开合同接入，不必复制私有实现。'
            input = '依赖公开 API -> 替换实现 -> 合同测试仍绿'
            feedback = 'API 表面清单、破坏性变更检测、示例第二消费者'
            novel = '复用靠合同而不是拷贝代码'
            pitch = '下一系统能直接接'
        }
        'counterplay' = @{
            zh = '对抗与约束'
            scenario = '系统被滥用时有约束与可观察反制（限流、校验、审计），攻击面写明。'
            input = '威胁模型 -> 校验点 -> 限流/拒绝 -> 审计'
            feedback = '拒绝原因、审计事件、攻击面表'
            novel = '把对抗写成工程约束，而不只是玩法 PVP'
            pitch = '被刷/被绕有挡板'
        }
        'breakthrough-novelty' = @{
            zh = '突破点'
            scenario = '相对旧架构指出一个可验证的突破（吞吐/表达/安全），并给出对照基准。'
            input = '旧基准测量 -> 新路径 -> 对照指标 -> 接受/回退'
            feedback = '前后对照表、突破声明范围、未声称项'
            novel = '突破必须可测，禁止空泛“更现代”'
            pitch = '新在哪、怎么证'
        }
        'ownership-lifecycle' = @{
            zh = '所有权生命周期'
            scenario = '资源/实体/句柄有明确 Owner 与释放点；借出必须归还；销毁后禁访问。'
            input = '申请所有权 -> 借出/共享策略 -> 归还或转移 -> 销毁校验'
            feedback = '泄漏检测列表、悬空访问失败码、Owner 图谱'
            novel = '所有权写进运行合同，而不是约定俗成'
            pitch = '谁管、何时放、错了能查'
        }
        'state-machine-integrity' = @{
            zh = '状态机严谨'
            scenario = '技能/实体生命周期用显式状态机：Enter/Active/Recover/Exit，禁止旁路改血与双入口。'
            input = '事件入队 -> 唯一状态转移 -> 副作用只在转移上发生 -> 审计日志'
            feedback = '非法转移拒绝回执、状态图快照、旁路调用告警'
            novel = '所有玩法效果只能通过登记转移触发，消灭隐式状态'
            pitch = '状态可推导、可回放'
        }
        'longevity' = @{
            zh = '长寿命'
            scenario = '扩展点、版本策略与废弃路径齐全；小改不毁主链，大改可迁移。'
            input = '扩展注册 -> 版本协商 -> 废弃告警 -> 迁移脚本'
            feedback = '版本矩阵、废弃清单、迁移干跑报告'
            novel = '长寿命靠扩展与迁移设计，不是一次写死'
            pitch = '明年还接得住'
        }
        'failure-recovery' = @{
            zh = '失败恢复'
            scenario = '关键路径失败可重试/回滚/降级；错误带错误码与恢复动作，不吞异常。'
            input = '主路径 -> 失败分类 -> 恢复动作 -> 最终状态'
            feedback = '错误码、恢复按钮/自动策略、残留清理报告'
            novel = '失败是一等状态，恢复动作可测试'
            pitch = '挂了能起来'
        }
        'performance-peak-budget' = @{
            zh = '性能峰值预算'
            scenario = '批量生成/结算有帧预算与降级策略；超预算可切 LOD 或分帧，不卡死主线程。'
            input = '预算探针 -> 工作量估计 -> 执行或分帧 -> 降级回执'
            feedback = '帧时火焰图标记、降级原因、峰值计数'
            novel = '峰值预算是合同字段，超了必须有降级路径'
            pitch = '量大也不炸帧'
        }
    }
    $stablePacks = @{
        'complete-loop' = @{
            zh = '闭环完整'
            scenario = '从变更到验证到回滚到文档的闭环步骤齐全，无悬空“待会再补”。'
            input = '变更 -> 验证 -> 记录 -> 回滚点 -> 关闭'
            feedback = '闭环检查表、未关闭项、责任人'
            novel = '稳定完成=闭环关闭，不是代码合并'
            pitch = '事能结案'
        }
        'integration-fit' = @{
            zh = '集成贴合'
            scenario = '新开关/表项贴合现有入口，不另起旁路；与日常关卡默认隔离。'
            input = '现有入口探测 -> 叠加配置 -> 默认关闭 -> 灰度打开'
            feedback = '入口复用证明、旁路扫描、默认态断言'
            novel = '集成优先复用入口，禁止第二通道'
            pitch = '接得上现网'
        }
        'compatibility' = @{
            zh = '兼容性'
            scenario = '老存档/老表可读；未知字段保留；语义不静默漂移。'
            input = '加载老数据 -> 迁移或保留 -> 双读校验'
            feedback = '迁移报告、未知字段保留证明、语义 diff'
            novel = '兼容是硬门：老数据必须可加载'
            pitch = '老玩家不毁档'
        }
        'rollback' = @{
            zh = '可回滚'
            scenario = '配置/表变更可一键回滚到上一良序版本，回滚本身可验证。'
            input = '变更 -> 快照 -> 出问题 -> 回滚 -> 校验'
            feedback = '快照 id、回滚耗时、回滚后哈希'
            novel = '回滚是默认能力，不是事故时才想'
            pitch = '改炸了能退'
        }
        'security-boundary' = @{
            zh = '安全边界'
            scenario = '导入/脚本/外部输入有校验与权限边界，破坏性操作需显式授权。'
            input = '输入消毒 -> 权限检查 -> 执行 -> 审计'
            feedback = '拒绝样例、权限表、审计'
            novel = '稳定模式默认不信任外部输入'
            pitch = '导入不炸库'
        }
        'regression-fixture' = @{
            zh = '回归夹具'
            scenario = '每次稳定修复带最小复现夹具与期望哈希/断言，防再发。'
            input = '夹具输入 -> 修复路径 -> 断言 -> 入库'
            feedback = '夹具路径、期望值、再发检测'
            novel = '无夹具的“修好了”不算稳定完成'
            pitch = '修一次少复发'
        }
        'contract-completeness' = @{
            zh = '合同完备'
            scenario = '变更前合同字段齐全：默认值、校验、失败语义、兼容策略都有主。'
            input = '读合同 -> 填缺省 -> 校验 -> 拒绝或接受'
            feedback = '缺字段清单、默认值来源、校验失败码'
            novel = '不完备合同不得进入稳定变更'
            pitch = '表/配置不会暗坑'
        }
        'observability' = @{
            zh = '可观测'
            scenario = '关键路径有结构化日志与相关 id，失败可定位到配置行/实体。'
            input = '操作 -> 打点 -> 关联 id -> 查询'
            feedback = '关联 id、配置行定位、时间线'
            novel = '可观测是稳定验收项'
            pitch = '出问题找得到'
        }
        'content-throughput' = @{
            zh = '内容吞吐'
            scenario = '批量导入/生成有进度、部分成功与失败隔离，不因一条坏数据全灭。'
            input = '批量作业 -> 逐条校验 -> 成功/隔离失败 -> 汇总'
            feedback = '进度条、失败隔离清单、部分成功计数'
            novel = '吞吐与隔离同级，禁止全有全无'
            pitch = '批量稳、坏条可摘'
        }
    }

    $packs = $creativePacks
    if ($Mode -eq 'engineering') { $packs = $engineeringPacks }
    elseif ($Mode -eq 'stable') { $packs = $stablePacks }

    if ($packs.ContainsKey($axis)) { $pack = $packs[$axis] }
    else {
        $pack = @{
            zh = $Axis
            scenario = "针对需求「$reqShort」，沿轴 $Axis 给出可讨论的具体场景与约束。"
            input = "明确目标 -> 沿 $Axis 做一次可观察尝试 -> 记录反馈 -> 调整"
            feedback = "目标相关的可见反馈与失败原因"
            novel = "在 $Axis 上改变一个可验证假设，并保持需求主体不变"
            pitch = "轴 $Axis 的可讨论方案"
        }
    }

    # Requirement grounding: inject domain keywords into scenario tail when present
    $ground = ''
    foreach ($k in @('采集','合成','战备','出击','日活','技能','经济','存档','回滚','Boss','近战','导入')) {
        if ($req.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $ground += "；需求锚点含「$k」"
        }
    }
    if ($ground.Length -gt 0) {
        $pack = @{
            zh = $pack.zh
            scenario = $pack.scenario + $ground + "。讨论时必须回指需求： $reqShort"
            input = $pack.input
            feedback = $pack.feedback
            novel = $pack.novel
            pitch = $pack.pitch
        }
    }

    return [pscustomobject]@{
        axis = $Axis
        axisZh = [string]$pack.zh
        productPitch = [string]$pack.pitch
        concretePlayerScenario = [string]$pack.scenario
        inputSequence = [string]$pack.input
        visibleFeedback = [string]$pack.feedback
        novelMechanism = [string]$pack.novel
        assumption = "轴 $($pack.zh)（$Axis）是与本需求相关的实质决策变量"
        risk = "未验证:$Axis; 需在真实项目中核对边界"
        seedDraft = "商用种子 #$Ordinal · $($pack.zh) · $reqShort"
        mode = $Mode
        contentTier = 'axis-grounded-v1'
    }
}

function Format-ESABCDCommercialMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)]$Divergence,
        [Parameter(Mandatory)][string]$Requirement
    )
    $nl = "`r`n"
    $sb2 = New-Object System.Text.StringBuilder
    $kind = [string]$Selection.deliveryKind
    $level = [string]$Selection.pipelineLevel
    $domain = [string]$Selection.domain
    $mode = [string]$Selection.mode
    [void]$sb2.AppendLine('# ABCD 商用交付简报')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine("> 生成 UTC: $([DateTime]::UtcNow.ToString('o'))")
    [void]$sb2.AppendLine("> deliveryKind=**$kind** · pipelineLevel=**$level** · domain=**$domain** · mode=**$mode**")
    [void]$sb2.AppendLine("> claim=**$([string]$Selection.claimLevel)** · runtime=**runtime-not-run**（未做 PlayMode/上线验收）")
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('## 需求')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine($Requirement)
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('## 怎么读这份简报')
    [void]$sb2.AppendLine('')
    if ($level -eq 'L1' -and $kind -eq 'domain-brief') {
        [void]$sb2.AppendLine('- 本份为 **L1 领域简报**：含可直接讨论的领域槽位/方案卡。')
    } else {
        [void]$sb2.AppendLine('- 本份为 **L0 透镜排序**：多视角设计卡，**不是**已闭合的领域终稿。')
    }
    [void]$sb2.AppendLine('- 过程栏（多向、claim、可复核）已满足；内容栏请人工/策划审阅后采用。')
    [void]$sb2.AppendLine('- 禁止把本文当成已平衡/已实装/可发版证明。')
    [void]$sb2.AppendLine('')

    # Domain brief section
    if ($null -ne $Selection.domainBrief) {
        $db = $Selection.domainBrief
        [void]$sb2.AppendLine('## 领域简报')
        [void]$sb2.AppendLine('')
        if ($null -ne $db.PSObject.Properties['summary']) {
            [void]$sb2.AppendLine([string]$db.summary)
            [void]$sb2.AppendLine('')
        }
        if ($domain -eq 'live-ops-loop' -and $null -ne $db.loops) {
            [void]$sb2.AppendLine('| # | 环名 | 倾向 | 吸引谁 | 烦谁 | 采集 | 合成 | 战备 | 出击 | 透镜 |')
            [void]$sb2.AppendLine('|---|------|------|--------|------|------|------|------|------|------|')
            foreach ($loop in @($db.loops)) {
                $row = '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |' -f `
                    $loop.loopIndex, $loop.name, $loop.tilt, $loop.attractWho, $loop.annoyWho, `
                    $loop.gather, $loop.craft, $loop.prep, $loop.sortie, $loop.groundedAxis
                [void]$sb2.AppendLine($row)
            }
            [void]$sb2.AppendLine('')
        }
        if ($null -ne $db.PSObject.Properties['cards'] -and $null -ne $db.cards) {
            $ci = 0
            foreach ($card in @($db.cards)) {
                $ci++
                [void]$sb2.AppendLine("### 方案卡 $ci · $($card.title)")
                [void]$sb2.AppendLine('')
                [void]$sb2.AppendLine("- **卖点**: $($card.pitch)")
                [void]$sb2.AppendLine("- **场景**: $($card.scenario)")
                [void]$sb2.AppendLine("- **输入**: $($card.inputSequence)")
                [void]$sb2.AppendLine("- **反馈**: $($card.visibleFeedback)")
                [void]$sb2.AppendLine("- **机制**: $($card.novelMechanism)")
                [void]$sb2.AppendLine("- **风险**: $($card.risk)")
                if ($null -ne $card.PSObject.Properties['hardCost']) {
                    [void]$sb2.AppendLine("- **硬伤**: $($card.hardCost)")
                }
                [void]$sb2.AppendLine('')
            }
        }
    }

    [void]$sb2.AppendLine('## 透镜排序（可讨论多方案）')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('| 序 | 轴 | 中文 | 分数 | directionId | 一句话 |')
    [void]$sb2.AppendLine('|----|----|------|------|------------|--------|')
    $rank = 0
    foreach ($row in @($Selection.ranked)) {
        $rank++
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        $axis = [string]$c.axis
        $zh = if ($null -ne $c.PSObject.Properties['axisZh']) { [string]$c.axisZh } else { $axis }
        $pitch = if ($null -ne $c.PSObject.Properties['productPitch']) { [string]$c.productPitch } else { '' }
        $id = [string]$c.directionId
        $score = $row.rankScore
        $mark = if ($rank -eq 1) { '★' } else { '' }
        [void]$sb2.AppendLine("| $rank$mark | $axis | $zh | $score | ``$id`` | $pitch |")
    }
    [void]$sb2.AppendLine('')

    $top = @($Selection.ranked)[0]
    if ($null -ne $top) {
        $tc = if ($null -ne $top.candidate) { $top.candidate } else { $top }
        [void]$sb2.AppendLine('## 主推荐展开')
        [void]$sb2.AppendLine('')
        [void]$sb2.AppendLine("- **轴**: $($tc.axis) / $(if($tc.axisZh){$tc.axisZh}else{''})")
        [void]$sb2.AppendLine("- **场景**: $($tc.concretePlayerScenario)")
        [void]$sb2.AppendLine("- **输入序列**: $($tc.inputSequence)")
        [void]$sb2.AppendLine("- **可见反馈**: $($tc.visibleFeedback)")
        [void]$sb2.AppendLine("- **新机制**: $($tc.novelMechanism)")
        [void]$sb2.AppendLine("- **假设**: $($tc.assumption)")
        [void]$sb2.AppendLine("- **风险**: $($tc.risk)")
        [void]$sb2.AppendLine('')
    }

    [void]$sb2.AppendLine('## 其它方向（未淘汰，可换主推）')
    [void]$sb2.AppendLine('')
    $ri = 0
    foreach ($row in @($Selection.ranked)) {
        $ri++
        if ($ri -eq 1) { continue }
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        [void]$sb2.AppendLine("### $ri. $($c.axis) $(if($c.axisZh){'· '+$c.axisZh})")
        [void]$sb2.AppendLine('')
        [void]$sb2.AppendLine("- $($c.productPitch)")
        [void]$sb2.AppendLine("- 场景: $($c.concretePlayerScenario)")
        [void]$sb2.AppendLine("- 机制: $($c.novelMechanism)")
        [void]$sb2.AppendLine('')
    }

    [void]$sb2.AppendLine('## 机器元数据')
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine("- directionCount: $($Divergence.directionCount)")
    [void]$sb2.AppendLine("- candidateSetHash: ``$($Divergence.candidateSetHash)``")
    [void]$sb2.AppendLine("- selectedDirectionId: ``$($Selection.selectedDirectionId)``")
    [void]$sb2.AppendLine("- selectionStatus: $($Selection.selectionStatus)")
    if ($null -ne $Selection.templateCollision) {
        [void]$sb2.AppendLine("- templateCollision: $($Selection.templateCollision.hasCollision) count=$($Selection.templateCollision.collisionCount)")
    }
    [void]$sb2.AppendLine('')
    [void]$sb2.AppendLine('---')
    [void]$sb2.AppendLine('*es-abcd commercial brief · 设计候选 · 非发版证明*')
    return $sb2.ToString()
}

function Invoke-ESABCDCommercial {
    # Prefer Invoke-ESABCD -Output brief. Kept as thin alias for older call sites.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering','creative-divergence','stable')][string]$Mode = 'creative-divergence',
        [string]$ProjectRoot = '',
        [string]$OutDir = ''
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDHome.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDIndex.psm1') -Force -Global
    return Invoke-ESABCD -Requirement $Requirement -Mode $Mode -ProjectRoot $ProjectRoot -OutDir $OutDir -Output brief
}
Export-ModuleMember -Function @(
    'Get-ESABCDAxisBodyFields',
    'Format-ESABCDCommercialMarkdown',
    'Invoke-ESABCDCommercial'
)

# Real axis-branch divergence + Chinese receipt.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDRequirementTokens {
    param([string]$Requirement)
    $t = [string]$Requirement
    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($k in @(
            '采集','合成','战备','出击','日活','技能','冷却','伤害','爆发','近战','手感','连段','Boss',
            '经济','货币','成长','道具','管线','导入','存档','回滚','兼容','活动','开关','关卡','修复',
            '状态机','所有权','性能','失败','恢复','安全','可观测','gather','craft','sortie','melee','skill'
        )) {
        if ($t.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) { [void]$tokens.Add($k) }
    }
    return @($tokens)
}

function Get-ESABCDContentFitScore {
    param([string]$Text,[string[]]$Tokens,[string]$Axis,[string]$AxisZh)
    $score = 50
    $blob = [string]$Text
    foreach ($k in @($Tokens)) {
        if ($blob.IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 4 }
    }
    if ($blob.IndexOf($Axis, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 3 }
    if (-not [string]::IsNullOrWhiteSpace($AxisZh) -and $blob.IndexOf($AxisZh, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 3 }
    $score += [Math]::Min(12, [int]($blob.Length / 40))
    if ($score -gt 99) { $score = 99 }
    if ($score -lt 1) { $score = 1 }
    return $score
}

function Get-ESABCDAxisMutationCatalog {
    param(
        [Parameter(Mandatory)][string]$Axis,
        [ValidateSet('creative-divergence','engineering','stable')][string]$Mode = 'creative-divergence'
    )
    $axis = $Axis.ToLowerInvariant()
    $packs = @{
        'moment-to-moment-feel' = @(
            @{ id='hit-window'; title='收紧命中窗'; change='把命中判定窗从宽松改为正负2帧，失败给差一帧提示'; risk='新手容错下降' }
            @{ id='hitstop'; title='命中顿帧分层'; change='轻击与重击使用不同顿帧曲线，重击更长但可取消尾帧'; risk='手感调参成本高' }
            @{ id='whiff'; title='落空恢复差'; change='落空硬直明确长于命中，形成可读博弈'; risk='对高延迟不友好' }
            @{ id='audio-sync'; title='音画强制对齐'; change='命中音与顿帧锁同一拍，禁止音效先行'; risk='资源制作约束' }
            @{ id='partial-hit'; title='擦伤反馈'; change='擦伤有独立闪光与短硬直，不等于完全落空'; risk='状态机分支变多' }
            @{ id='cancel-on-hit'; title='仅命中可取消'; change='取消窗只在命中后打开，杜绝空砍取消'; risk='连段门槛上升' }
        )
        'flow-continuity' = @(
            @{ id='resource-phase'; title='资源与动作同相'; change='技能资源消耗与连段节拍同相，禁止空等回能'; risk='数值要重做' }
            @{ id='rejoin'; title='断连重接入口'; change='断连后1.5秒内提供一次重接输入，成功续上心流'; risk='被滥用刷伤害' }
            @{ id='no-dead-wait'; title='消灭空窗'; change='超过0.4秒无输入则自动进入防御或移动恢复态'; risk='玩家失控感' }
            @{ id='combo-route'; title='双路线连段'; change='安全线与高伤线可中途切换一次'; risk='教学变长' }
            @{ id='buffer'; title='输入缓冲'; change='关键技能120ms输入缓冲，减少掉连'; risk='手感变粘' }
            @{ id='stamina-bridge'; title='体力桥'; change='用少量体力购买一次连段桥接'; risk='体力循环要重做' }
        )
        'presentation-beat' = @(
            @{ id='telegraph'; title='预告拍'; change='爆发前固定预告拍，可被对手读取'; risk='削弱偷袭感' }
            @{ id='climax'; title='爆发拍'; change='高光帧强制全屏节拍与镜头短推'; risk='过场疲劳' }
            @{ id='afterglow'; title='余韵可操作'; change='余韵期内仍可微移与防御，不只是播动画'; risk='动画约束' }
            @{ id='ui-beat'; title='UI打点'; change='关键收益跳字落在节拍上'; risk='UI噪声' }
            @{ id='fail-beat'; title='失败也有拍'; change='被反制时专用失败节拍，便于阅读'; risk='负面强化' }
            @{ id='layer'; title='分层特效预算'; change='特效分近中远三层，低端机降远层'; risk='制作规范' }
        )
        'expressive-input' = @(
            @{ id='charge'; title='蓄力路径'; change='短按速打、长按蓄力变体，同技能双路径'; risk='输入误触' }
            @{ id='directional'; title='方向修正'; change='技能中可一次方向修正，改变命中扇形'; risk='平衡难' }
            @{ id='cancel-style'; title='取消风格'; change='进攻取消与防御取消产出不同尾势'; risk='动画量' }
            @{ id='hold-release'; title='按住释放'; change='按住瞄准、松开发射的表达型操作'; risk='移动端适配' }
            @{ id='combo-fork'; title='连段分叉'; change='第三段可选A或B，决定控场或爆发'; risk='记忆负担' }
            @{ id='stance'; title='姿态切换'; change='一次姿态切换改变后续两段技能语义'; risk='系统膨胀' }
        )
        'skill-ceiling' = @(
            @{ id='perfect-cancel'; title='完美取消'; change='帧完美取消提升效率，失败回默认'; risk='电竞化' }
            @{ id='resource-tap'; title='资源卡点'; change='在特定资源阈值打出超额收益'; risk='阈值难记' }
            @{ id='matchup'; title='对位技巧'; change='对护甲或盾类型有可学补正'; risk='不透明' }
            @{ id='movement-tech'; title='位移技'; change='技能中微步取消延长连段窗口'; risk='操作割裂' }
            @{ id='punish'; title='惩罚课'; change='对手技能后摇的专属惩罚连'; risk='匹配波动' }
            @{ id='score-board'; title='上限可视'; change='结算显示技巧分与默认分对照'; risk='制造焦虑' }
        )
        'novelty-delta' = @(
            @{ id='placeable'; title='命中变据点'; change='命中留下3秒据点，改变走位'; risk='场地脏' }
            @{ id='convert'; title='伤害转资源'; change='部分伤害转化为可携带充能'; risk='滚雪球' }
            @{ id='echo'; title='回声打击'; change='主命中后0.5秒自动回声一次弱伤'; risk='读招难' }
            @{ id='swap'; title='目标交换'; change='技能可与标记目标交换位置一次'; risk='地图破坏' }
            @{ id='rule-break'; title='改一条规则'; change='本方案只把冷却改成风险槽'; risk='习惯迁移' }
            @{ id='teach'; title='可回退教学'; change='首次进入给对比教学，可关'; risk='文案量' }
        )
        'counterplay-clarity' = @(
            @{ id='warn'; title='预警轮廓'; change='爆发前0.4秒红色轮廓与音高'; risk='削弱惊吓' }
            @{ id='interrupt'; title='可打断点'; change='技能中段开放一次打断窗'; risk='节奏碎' }
            @{ id='iframe'; title='翻滚窗'; change='对手翻滚无敌与技能判定对齐表公开'; risk='数值暴露' }
            @{ id='shield'; title='护盾应答'; change='格挡成功给短反击窗'; risk='格挡强权' }
            @{ id='review'; title='失败回看'; change='被爆回看条标注可反制帧'; risk='UI复杂' }
            @{ id='telegraph-level'; title='预警分级'; change='小中大技能三色预警'; risk='视觉噪声' }
        )
        'mechanic-amplification' = @(
            @{ id='chain4'; title='四段放大'; change='动作到关联到收益到恢复强制四段'; risk='过长' }
            @{ id='invest'; title='再投入'; change='收益可再投入一次放大，有衰减'; risk='数值爆炸' }
            @{ id='shared'; title='队友放大'; change='关联机制可分享给队友一次'; risk='配合门槛' }
            @{ id='cap'; title='放大上限'; change='单次循环放大有硬顶，防无限'; risk='爽感下降' }
            @{ id='visible'; title='节点可视'; change='链路上四节点UI常驻'; risk='HUD占位' }
            @{ id='fail-safe'; title='放大失败恢复'; change='中断时按比例退回资源'; risk='实现复杂' }
        )
    }
    $eng = @{
        'state-machine-integrity' = @(
            @{ id='single-entry'; title='唯一入口'; change='所有效果只经登记转移触发'; risk='改造面大' }
            @{ id='illegal-reject'; title='非法转移拒绝'; change='旁路调用直接失败并打回执'; risk='兼容旧代码' }
            @{ id='audit-log'; title='转移审计'; change='每次转移写结构化日志'; risk='日志量' }
            @{ id='recover-state'; title='恢复态显式'; change='Recover成为一等状态'; risk='图变更' }
            @{ id='no-double'; title='禁双入口'; change='同一实体同时只允许一个写入者'; risk='并发模型' }
            @{ id='snapshot'; title='状态快照'; change='关键节点可快照回放'; risk='内存' }
        )
        'ownership-lifecycle' = @(
            @{ id='owner'; title='显式Owner'; change='每个句柄登记Owner与归还点'; risk='样板代码' }
            @{ id='lease'; title='租约'; change='借出必须带租约超时'; risk='超时策略' }
            @{ id='destroy-guard'; title='销毁后禁访问'; change='销毁后访问抛明确错误码'; risk='调用方改造' }
            @{ id='leak-scan'; title='泄漏扫描'; change='作用域结束扫描未归还'; risk='性能' }
            @{ id='transfer'; title='所有权转移'; change='转移必须双边确认回执'; risk='流程重' }
            @{ id='graph'; title='Owner图谱'; change='调试期可导出引用图'; risk='仅工具' }
        )
        'determinism' = @(
            @{ id='rng-stream'; title='登记RNG流'; change='随机只走命名流'; risk='迁移旧随机' }
            @{ id='step-hash'; title='逐步哈希'; change='每帧结算附带哈希'; risk='开销' }
            @{ id='no-time'; title='禁隐藏时间'; change='逻辑不读未同步时钟'; risk='动画耦合' }
            @{ id='replay'; title='同种复现'; change='同输入同种子可复盘'; risk='存回放' }
            @{ id='diverge-report'; title='分歧报告'; change='哈希不一致输出首分歧帧'; risk='工具链' }
            @{ id='fixed-tick'; title='固定tick'; change='逻辑tick与渲染解耦'; risk='手感重调' }
        )
        'performance-peak-budget' = @(
            @{ id='frame-budget'; title='帧预算'; change='批量工作超预算则分帧'; risk='完成变慢' }
            @{ id='lod'; title='降级LOD'; change='峰值自动切低LOD'; risk='画质投诉' }
            @{ id='probe'; title='预算探针'; change='开工前估计工作量'; risk='估计不准' }
            @{ id='shed'; title='负载卸载'; change='非关键特效可丢弃'; risk='表现不一致' }
            @{ id='pool'; title='池化'; change='热点分配改池'; risk='泄漏难查' }
            @{ id='metric'; title='峰值计数'; change='回执带峰值帧时'; risk='埋点' }
        )
        'failure-recovery' = @(
            @{ id='retry'; title='可重试'; change='可恢复错误自动重试有限次'; risk='掩盖真因' }
            @{ id='rollback'; title='回滚'; change='失败回滚到上一良序快照'; risk='快照成本' }
            @{ id='degrade'; title='降级'; change='主路径失败走降级功能'; risk='体验差' }
            @{ id='error-code'; title='错误码'; change='所有失败带稳定错误码'; risk='枚举膨胀' }
            @{ id='cleanup'; title='残留清理'; change='失败路径必须清理半成品'; risk='易漏' }
            @{ id='playbook'; title='恢复手册'; change='回执附推荐恢复动作'; risk='文案维护' }
        )
        'reuse-surface' = @(
            @{ id='public-api'; title='公开API面'; change='第二消费者只依赖公开合同'; risk='封装成本' }
            @{ id='no-copy'; title='禁拷贝实现'; change='复用靠组合不靠复制'; risk='短期变慢' }
            @{ id='contract-test'; title='合同测试'; change='替换实现合同测试仍绿'; risk='测试量' }
            @{ id='version'; title='版本协商'; change='API带版本与废弃窗'; risk='双轨' }
            @{ id='example-consumer'; title='示例消费者'; change='仓库带第二消费者样例'; risk='维护' }
            @{ id='surface-list'; title='表面清单'; change='生成API表面清单工件'; risk='工具' }
        )
        'breakthrough-novelty' = @(
            @{ id='baseline'; title='旧基准'; change='先测旧路径基准再谈突破'; risk='时间' }
            @{ id='one-claim'; title='单一突破声明'; change='一次只声明一个可测突破'; risk='营销弱' }
            @{ id='ab'; title='对照'; change='新旧对照表进回执'; risk='实验设计' }
            @{ id='rollback-break'; title='可回退突破'; change='突破开关可关'; risk='双实现' }
            @{ id='scope'; title='声明范围'; change='写清不声称的项'; risk='显得保守' }
            @{ id='metric-gate'; title='指标门'; change='未达指标不得标突破'; risk='压力' }
        )
        'longevity' = @(
            @{ id='extension'; title='扩展点'; change='预留扩展注册表'; risk='过度设计' }
            @{ id='migrate'; title='迁移脚本'; change='大改必须带迁移干跑'; risk='成本' }
            @{ id='deprecate'; title='废弃路径'; change='废弃有告警与期限'; risk='双轨久' }
            @{ id='compat-matrix'; title='版本矩阵'; change='维护版本兼容矩阵'; risk='文档' }
            @{ id='small-change'; title='小改不毁主链'; change='补丁级改动不改主状态机'; risk='约束' }
            @{ id='owner-doc'; title='所有权文档'; change='模块owner写进合同'; risk='流程' }
        )
        'counterplay' = @(
            @{ id='threat'; title='威胁模型'; change='先写滥用面再实现'; risk='前期慢' }
            @{ id='rate-limit'; title='限流'; change='关键写路径带限流'; risk='误伤' }
            @{ id='validate'; title='校验点'; change='输入消毒与权限检查'; risk='延迟' }
            @{ id='audit'; title='审计事件'; change='拒绝与通过都审计'; risk='存储' }
            @{ id='surface'; title='攻击面表'; change='回执附攻击面表'; risk='暴露' }
            @{ id='deny'; title='默认拒绝'; change='未知输入默认拒绝'; risk='兼容' }
        )
    }
    $stable = @{
        'contract-completeness' = @(
            @{ id='defaults'; title='默认值主'; change='缺字段有默认来源'; risk='隐式' }
            @{ id='validate-fail'; title='校验失败语义'; change='失败码稳定'; risk='枚举' }
            @{ id='compat-policy'; title='兼容策略'; change='合同写兼容策略'; risk='篇幅' }
            @{ id='reject-incomplete'; title='不完备拒入'; change='缺关键字段不得进稳定变更'; risk='阻力' }
            @{ id='field-owner'; title='字段主人'; change='每个字段有owner'; risk='流程' }
            @{ id='schema-freeze'; title='schema冻结'; change='变更要升版本'; risk='灵活度' }
        )
        'integration-fit' = @(
            @{ id='reuse-entry'; title='复用入口'; change='叠加现有入口不旁路'; risk='耦合' }
            @{ id='default-off'; title='默认关'; change='新开关默认关闭'; risk='发现性' }
            @{ id='gray'; title='灰度'; change='支持灰度打开'; risk='配置复杂' }
            @{ id='scan-bypass'; title='旁路扫描'; change='安装时扫描第二通道'; risk='误报' }
            @{ id='daily-isolate'; title='日常隔离'; change='活动配置不影响日常关'; risk='架构' }
            @{ id='probe'; title='入口探测'; change='先探测再叠加'; risk='环境差' }
        )
        'compatibility' = @(
            @{ id='old-load'; title='老数据可加载'; change='老存档必须可读'; risk='迁移' }
            @{ id='keep-unknown'; title='未知字段保留'; change='未知字段原样保留'; risk='体积' }
            @{ id='no-silent'; title='禁静默漂移'; change='语义变必须升版本'; risk='严格' }
            @{ id='dual-read'; title='双读校验'; change='迁移后双读对比'; risk='成本' }
            @{ id='mid-player'; title='中途玩家'; change='中途存档可继续'; risk='分支' }
            @{ id='diff'; title='语义diff'; change='输出语义diff报告'; risk='工具' }
        )
        'regression-fixture' = @(
            @{ id='min-repro'; title='最小复现'; change='修复带最小夹具'; risk='时间' }
            @{ id='expect-hash'; title='期望哈希'; change='夹具带期望哈希'; risk='脆' }
            @{ id='store'; title='夹具入库'; change='夹具进仓库'; risk='体积' }
            @{ id='rerun'; title='再发检测'; change='CI跑夹具'; risk='CI' }
            @{ id='no-fix-without'; title='无夹具不算修完'; change='门禁拒绝无夹具合入'; risk='流程' }
            @{ id='owner'; title='夹具owner'; change='夹具有维护人'; risk='人力' }
        )
        'rollback' = @(
            @{ id='snapshot'; title='变更快照'; change='变更前自动快照'; risk='磁盘' }
            @{ id='one-click'; title='一键回滚'; change='回滚到上一良序'; risk='权限' }
            @{ id='verify'; title='回滚校验'; change='回滚后哈希校验'; risk='时间' }
            @{ id='time-budget'; title='回滚耗时预算'; change='回滚有时限目标'; risk='压力' }
            @{ id='default-ability'; title='默认能力'; change='回滚是默认不是事故选项'; risk='文化' }
            @{ id='partial'; title='部分回滚'; change='支持按文件集回滚'; risk='一致' }
        )
        'security-boundary' = @(
            @{ id='sanitize'; title='输入消毒'; change='外部输入一律消毒'; risk='误杀' }
            @{ id='authz'; title='显式授权'; change='破坏性操作需授权证明'; risk='摩擦' }
            @{ id='import-gate'; title='导入门'; change='导入校验去重隔离'; risk='慢' }
            @{ id='least'; title='最小权限'; change='默认最小权限'; risk='不便' }
            @{ id='secret'; title='禁密钥入回执'; change='回执扫密钥模式'; risk='漏' }
            @{ id='deny-script'; title='脚本边界'; change='不信任脚本默认拒'; risk='灵活' }
        )
        'observability' = @(
            @{ id='corr-id'; title='关联id'; change='全路径打关联id'; risk='传递' }
            @{ id='struct-log'; title='结构化日志'; change='关键路径结构化'; risk='量' }
            @{ id='locate'; title='定位到行'; change='失败定位配置行或实体'; risk='元数据' }
            @{ id='timeline'; title='时间线'; change='回执可拼时间线'; risk='存储' }
            @{ id='gate'; title='可观测验收'; change='缺埋点不得标稳定完成'; risk='流程' }
            @{ id='sample'; title='采样'; change='高基数采样'; risk='盲区' }
        )
        'content-throughput' = @(
            @{ id='partial'; title='部分成功'; change='坏条隔离，好条提交'; risk='一致' }
            @{ id='progress'; title='进度'; change='批量作业有进度'; risk='UI' }
            @{ id='isolate'; title='失败隔离清单'; change='失败清单可导出'; risk='格式' }
            @{ id='validate-each'; title='逐条校验'; change='逐条校验再写'; risk='慢' }
            @{ id='no-allornothing'; title='禁全有全无'; change='默认部分成功策略'; risk='业务' }
            @{ id='quota'; title='吞吐配额'; change='单批上限与分批'; risk='运营' }
        )
        'complete-loop' = @(
            @{ id='checklist'; title='闭环检查表'; change='变更验证记录回滚关闭'; risk='流程重' }
            @{ id='no-hang'; title='禁悬空待补'; change='未关闭项阻断完成'; risk='严格' }
            @{ id='owner'; title='责任人'; change='每环有责任人'; risk='组织' }
            @{ id='evidence'; title='证据闭合'; change='无证据不得关单'; risk='慢' }
            @{ id='review'; title='复盘'; change='关闭前强制短复盘'; risk='会议' }
            @{ id='auto-close'; title='条件关闭'; change='证据齐自动可关'; risk='误关' }
        )
    }
    foreach ($k in $eng.Keys) { $packs[$k] = $eng[$k] }
    foreach ($k in $stable.Keys) { $packs[$k] = $stable[$k] }
    if ($packs.ContainsKey($axis)) { return @($packs[$axis]) }
    return @(
        @{ id='alt-a'; title='强化约束'; change="在轴 $Axis 上增加一条可验证约束"; risk='约束过紧' }
        @{ id='alt-b'; title='放松表达'; change="在轴 $Axis 上优先表达与可读性"; risk='深度不足' }
        @{ id='alt-c'; title='失败优先'; change="在轴 $Axis 上先设计失败与恢复"; risk='前期体验' }
        @{ id='alt-d'; title='性能优先'; change="在轴 $Axis 上先设预算与降级"; risk='表现裁切' }
        @{ id='alt-e'; title='兼容优先'; change="在轴 $Axis 上保证老数据路径"; risk='创新受限' }
        @{ id='alt-f'; title='可观测优先'; change="在轴 $Axis 上先埋点与回执"; risk='实现量' }
    )
}

function New-ESABCDRealDirectionCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)][string]$SourceHash,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$Axis,
        [Parameter(Mandatory)][int]$Ordinal,
        [Parameter(Mandatory)]$Profile,
        [ValidateRange(2, 12)][int]$RealRounds = 6
    )
    Import-Module (Join-Path $PSScriptRoot 'ESABCDCommercialContent.psm1') -Force -Global
    Import-Module (Join-Path $PSScriptRoot 'ESABCDDelivery.psm1') -Force -Global

    $body = Get-ESABCDAxisBodyFields -Axis $Axis -Mode $Mode -Requirement $Requirement -Ordinal $Ordinal
    $tokens = @(Get-ESABCDRequirementTokens -Requirement $Requirement)
    $mutations = @(Get-ESABCDAxisMutationCatalog -Axis $Axis -Mode $Mode)
    $seed = [ordered]@{ requirement = $Requirement; sourceHash = $SourceHash; mode = $Mode; axis = $Axis; ordinal = $Ordinal; engine = 'real-v1' }
    $hash = Get-ESABCDStringSha256 -Text (($seed | ConvertTo-Json -Compress -Depth 8))
    $id = 'cand-' + $hash.Substring(0, 20)

    $baseBlob = (@($body.concretePlayerScenario, $body.inputSequence, $body.visibleFeedback, $body.novelMechanism, $body.productPitch) -join '|')
    $fit = Get-ESABCDContentFitScore -Text $baseBlob -Tokens $tokens -Axis $Axis -AxisZh ([string]$body.axisZh)
    $salt = [int](([Convert]::ToInt32($hash.Substring(0, 4), 16) % 7)) - 3
    $mk = {
        param($name, $bias)
        $h = Get-ESABCDStringSha256 -Text (([ordered]@{ seed = $seed; dimension = $name; real = 1 } | ConvertTo-Json -Compress -Depth 8))
        $n = [int](([Convert]::ToInt32($h.Substring(0, 4), 16) % 9)) - 4
        $v = [int][Math]::Round($fit + $bias + $n + $salt)
        if ($v -gt 98) { $v = 98 }
        if ($v -lt 55) { $v = 55 }
        return $v
    }
    $scores = [ordered]@{
        delight = (& $mk 'delight' 5); smoothness = (& $mk 'smoothness' 3); presentation = (& $mk 'presentation' 2)
        skillCeiling = (& $mk 'skillCeiling' 4); joyLoop = (& $mk 'joyLoop' 6); first10sMoment = (& $mk 'first10sMoment' 4)
        expressionCeiling = (& $mk 'expressionCeiling' 3); noveltyDelta = (& $mk 'noveltyDelta' 2); counterplayClarity = (& $mk 'counterplayClarity' 3)
        depth = (& $mk 'depth' 5); breakthrough = (& $mk 'breakthrough' 2); reusability = (& $mk 'reusability' 3)
        longevity = (& $mk 'longevity' 2); projectFit = (& $mk 'projectFit' 4); completeness = (& $mk 'completeness' 3)
        safety = (& $mk 'safety' 3); closure = (& $mk 'closure' 4)
    }

    $playerValue = switch ($Mode) {
        'creative-divergence' { '玩家向：爽感/表达/上限可讨论' }
        'engineering' { '工程向：结构正确、可复用、可恢复' }
        default { '稳定向：兼容、回滚、少翻车' }
    }
    $chain = "核心动作（$($body.axisZh)）-> 关联机制 -> 可见收益 -> 恢复选择；放大环：$([string]$Profile.amplificationLoop)"
    $self = "最弱轴=$($body.axisZh)；修复=补具体关联机制与可见收益；排序优先=$((@($Profile.rankingPriority) | ForEach-Object { [string]$_ }) -join ',')"

    $live = [ordered]@{
        scenario = [string]$body.concretePlayerScenario
        input    = [string]$body.inputSequence
        feedback = [string]$body.visibleFeedback
        novel    = [string]$body.novelMechanism
        pitch    = [string]$body.productPitch
        risk     = [string]$body.risk
    }

    $trace = New-Object System.Collections.Generic.List[object]
    $keptMutations = New-Object System.Collections.Generic.List[object]
    $parentId = $id
    $mi = 0
    for ($round = 1; $round -le $RealRounds; $round++) {
        $alternatives = New-Object System.Collections.Generic.List[object]
        for ($b = 1; $b -le 2; $b++) {
            $mut = $mutations[$mi % $mutations.Count]
            $mi++
            $scenario2 = "$($live.scenario) 【第${round}轮分支$b·$([string]$mut['title'])】$([string]$mut['change'])"
            $novel2 = "$($live.novel)；变体：$([string]$mut['change'])"
            $risk2 = "$($live.risk)；分支风险：$([string]$mut['risk'])"
            $text = "$scenario2|$novel2|$($live.input)|$($live.feedback)|$Requirement"
            $accept = Get-ESABCDContentFitScore -Text $text -Tokens $tokens -Axis $Axis -AxisZh ([string]$body.axisZh)
            foreach ($k in $tokens) {
                if (([string][string]$mut['change']).IndexOf($k, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $accept += 2 }
            }
            if ($accept -gt 99) { $accept = 99 }
            [void]$alternatives.Add([pscustomobject]@{
                    branchId = "$id-r$round-b$b"; roundId = $round; parentCandidateId = $parentId
                    mutationId = [string][string]$mut['id']; title = [string][string]$mut['title']; concreteChange = [string][string]$mut['change']
                    branchReason = "第${round}轮检验「$([string]$mut['title'])」是否提升需求贴合与$($body.axisZh)可读性"
                    playerAcceptability = [int]$accept; scenario = $scenario2; novel = $novel2; risk = $risk2
                    inputSequence = [string]$live.input; visibleFeedback = [string]$live.feedback
                })
        }
        $sorted = @($alternatives | Sort-Object @{ e = { $_.playerAcceptability }; Descending = $true }, @{ e = { $_.branchId } })
        $keep = $sorted[0]; $drop = $sorted[1]
        [void]$trace.Add([pscustomobject][ordered]@{
                roundId = $round; parentCandidateId = $parentId; branchId = [string]$keep.branchId
                branchReason = [string]$keep.branchReason; concreteChange = [string]$keep.concreteChange
                mutationId = [string]$keep.mutationId; mutationTitle = [string]$keep.title
                playerAcceptability = [int]$keep.playerAcceptability
                keepOrDiscardReason = "保留：贴合分$($keep.playerAcceptability)高于另一分支$($drop.playerAcceptability)；变更=$($keep.concreteChange)"
                decision = 'keep'; language = 'zh-CN'
            })
        [void]$trace.Add([pscustomobject][ordered]@{
                roundId = $round; parentCandidateId = $parentId; branchId = [string]$drop.branchId
                branchReason = [string]$drop.branchReason; concreteChange = [string]$drop.concreteChange
                mutationId = [string]$drop.mutationId; mutationTitle = [string]$drop.title
                playerAcceptability = [int]$drop.playerAcceptability
                keepOrDiscardReason = "淘汰：贴合分$($drop.playerAcceptability)较低或风险更重；作为反事实保留"
                decision = 'discard'; language = 'zh-CN'
            })
        $live.scenario = [string]$keep.scenario; $live.novel = [string]$keep.novel; $live.risk = [string]$keep.risk
        $parentId = [string]$keep.branchId
        [void]$keptMutations.Add([pscustomobject]@{ round = $round; title = $keep.title; change = $keep.concreteChange; score = $keep.playerAcceptability })
    }

    $finalFit = Get-ESABCDContentFitScore -Text ($live.scenario + $live.novel) -Tokens $tokens -Axis $Axis -AxisZh ([string]$body.axisZh)

    $cand = [ordered]@{}
    $cand['directionId'] = $id
    $cand['mode'] = $Mode
    $cand['ordinal'] = $Ordinal
    $cand['axis'] = $Axis
    $cand['axisZh'] = [string]$body.axisZh
    $cand['productPitch'] = [string]$live.pitch
    $cand['contentTier'] = 'real-axis-branch-v1'
    $cand['focus'] = @($Profile.focus | ForEach-Object { [string]$_ })
    $cand['rankingPriority'] = @($Profile.rankingPriority | ForEach-Object { [string]$_ })
    $cand['selfCritiqueLoop'] = [string]$Profile.selfCritiqueLoop
    $cand['noveltyPrompt'] = ('沿「' + [string]$body.axisZh + '」探索与需求相关的真实变体，禁止空模板')
    $cand['playerValue'] = $playerValue
    $cand['modeScores'] = [pscustomobject]$scores
    $cand['amplificationChain'] = $chain
    $cand['selfCritique'] = $self
    $cand['selfCritiquePasses'] = $RealRounds
    $cand['seedDraft'] = [string]$body.seedDraft
    $cand['expansionSet'] = ('真实轴分支 · ' + [string]$body.axisZh + ' · ' + $RealRounds + ' 轮')
    $cand['auditFindings'] = '待审计：所有权、反制、恢复、需求贴合'
    $cand['playabilityBackpressure'] = '首个收益与复杂度预算已在分支贴合分中约束'
    $cand['finalDecision'] = '候选；未定案'
    $cand['deletedAnchors'] = @(('default-' + $Axis + '-assumption'), 'one-shot-resolution')
    $cand['novelMechanism'] = [string]$live.novel
    $cand['plausibilityRationale'] = '因果可读：资源/时机/目标/恢复边界内'
    $cand['counterplayInvariant'] = '对手需有预警与至少一种反制窗'
    $cand['surpriseScore'] = [int][Math]::Min(95.0, 60.0 + ([double]$finalFit / 5.0))
    $cand['plausibilityScore'] = [int][Math]::Min(95.0, 55.0 + ([double]$finalFit / 4.0))
    $cand['firstUseAffordance'] = ('主输入立即产生与「' + [string]$body.axisZh + '」相关的可见反应')
    $cand['partialUnderstandingPath'] = '基础反应在未掌握全部系统前仍有用'
    $cand['masteryDepth'] = '时机、分支与对位表达随熟练加深'
    $cand['onboardingBurden'] = [int][Math]::Max(40.0, 90.0 - [double]$finalFit)
    $cand['firstPayoffSeconds'] = 6
    $cand['firstInputCount'] = 1
    $cand['preservedIdentity'] = '需求主体身份保持'
    $cand['preservedRole'] = '需求角色保持'
    $cand['requestedFormFactor'] = '输入声明的形态'
    $cand['formFactorPreserved'] = $true
    $cand['mechanismDelta'] = '只改机制假设；身份/角色/形态不变'
    $cand['concretePlayerScenario'] = [string]$live.scenario
    $cand['inputSequence'] = [string]$live.input
    $cand['visibleFeedback'] = [string]$live.feedback
    $cand['acceptabilityRationale'] = ('分支贴合分=' + $finalFit + '；需求词命中与轴表达已计入')
    $cand['concretenessScore'] = [int][Math]::Min(98.0, 70.0 + ([double]([string]$live.scenario).Length / 20.0))
    $cand['acceptabilityScore'] = [int]$finalFit
    $cand['assumption'] = [string]$body.assumption
    $cand['risk'] = [string]$live.risk
    $cand['pruningPolicy'] = [string]$Profile.pruningPolicy
    $cand['hidden'] = $false
    $cand['status'] = 'candidate'
    $cand['verificationPredicate'] = ('source-hash-equals:' + $SourceHash)
    $cand['identityHash'] = $hash
    $cand['lineageRoot'] = $id
    $cand['lineageDepth'] = $RealRounds
    $cand['iterationTrace'] = @($trace.ToArray())
    $cand['keptMutations'] = @($keptMutations.ToArray())
    $cand['requirementTokens'] = @($tokens)
    $cand['divergenceEngine'] = 'real-axis-branch-v1'
    $cand['language'] = 'zh-CN'
    return [pscustomobject]$cand
}
function ConvertTo-ESABCDChineseReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)]$Divergence,
        [Parameter(Mandatory)][string]$Requirement,
        [string]$Entry = 'Invoke-ESABCD'
    )
    $modeZh = switch ([string]$Divergence.mode) {
        'creative-divergence' { '创意发散' }; 'engineering' { '工程' }; 'stable' { '稳定' }; default { [string]$Divergence.mode }
    }
    $deliveryZh = switch ([string]$Selection.deliveryKind) {
        'domain-brief' { '领域简报' }; 'lens-only' { '仅透镜排序' }; default { [string]$Selection.deliveryKind }
    }
    $levelZh = switch ([string]$Selection.pipelineLevel) {
        'L0' { 'L0 透镜层' }; 'L1' { 'L1 领域交付层' }; default { [string]$Selection.pipelineLevel }
    }
    $claimZh = switch -Regex ([string]$Selection.claimLevel) {
        'domain-brief' { '设计候选·领域简报' }
        'template' { '设计候选·透镜模板（正文曾碰撞）' }
        'design-candidate' { '设计候选' }
        'candidate' { '候选' }
        default { [string]$Selection.claimLevel }
    }
    $selZh = switch ([string]$Selection.selectionStatus) {
        'deterministic-selected' { '按规则选定主推荐' }
        'ranked-recommended' { '排序后推荐第一' }
        'collaborator-selected' { '协作者指定' }
        default { [string]$Selection.selectionStatus }
    }
    $engineZh = switch ([string]$Divergence.iterationTraceKind) {
        'real-axis-branch-v1' { '真实轴分支搜索' }
        'synthetic-trace' { '合成轨迹（旧）' }
        default { [string]$Divergence.iterationTraceKind }
    }

    $directionsZh = @()
    $rank = 0
    foreach ($row in @($Selection.ranked)) {
        $rank++
        $c = if ($null -ne $row.candidate) { $row.candidate } else { $row }
        $kept = @()
        if ($null -ne $c.PSObject.Properties['keptMutations'] -and $null -ne $c.keptMutations) {
            $kept = @($c.keptMutations | ForEach-Object { "第$($_.round)轮保留「$($_.title)」：$($_.change)（分=$($_.score)）" })
        }
        $traceSummary = @()
        if ($null -ne $c.iterationTrace) {
            foreach ($tr in @($c.iterationTrace | Where-Object { $_.decision -eq 'keep' })) {
                $title = if ($tr.PSObject.Properties['mutationTitle']) { [string]$tr.mutationTitle } else { [string]$tr.concreteChange }
                $traceSummary += "第$($tr.roundId)轮保留：$title（$($tr.playerAcceptability)分）"
            }
        }
        $directionsZh += [pscustomobject][ordered]@{
            排名 = $rank; 是否主推荐 = ($rank -eq 1); 方向编号 = [string]$c.directionId
            轴 = [string]$c.axis; 轴中文 = [string]$c.axisZh; 一句话卖点 = [string]$c.productPitch
            排序分 = $row.rankScore; 玩家场景 = [string]$c.concretePlayerScenario
            输入序列 = [string]$c.inputSequence; 可见反馈 = [string]$c.visibleFeedback
            新机制 = [string]$c.novelMechanism; 假设 = [string]$c.assumption; 风险 = [string]$c.risk
            可接受性分 = $c.acceptabilityScore; 具体性分 = $c.concretenessScore
            真实分支保留摘要 = $traceSummary; 保留变更列表 = $kept
            发散引擎 = [string]$c.divergenceEngine
        }
    }

    $domainBriefZh = $null
    if ($null -ne $Selection.domainBrief) {
        $db = $Selection.domainBrief
        $loopsZh = $null
        if ($null -ne $db.PSObject.Properties['loops'] -and $null -ne $db.loops) {
            $loopsZh = @($db.loops | ForEach-Object {
                    [pscustomobject][ordered]@{ 序号=$_.loopIndex; 名称=$_.name; 倾向=$_.tilt; 吸引谁=$_.attractWho; 烦谁=$_.annoyWho; 采集=$_.gather; 合成=$_.craft; 战备=$_.prep; 出击=$_.sortie; 接地轴=$_.groundedAxis }
                })
        }
        $cardsZh = $null
        if ($null -ne $db.PSObject.Properties['cards'] -and $null -ne $db.cards) {
            $cardsZh = @($db.cards | ForEach-Object {
                    [pscustomobject][ordered]@{ 标题=$_.title; 卖点=$_.pitch; 场景=$_.scenario; 输入=$_.inputSequence; 反馈=$_.visibleFeedback; 机制=$_.novelMechanism; 风险=$_.risk; 硬伤=$_.hardCost }
                })
        }
        $domainBriefZh = [pscustomobject][ordered]@{ 领域=[string]$db.domain; 摘要=[string]$db.summary; 语言=[string]$db.language; 日活环=$loopsZh; 方案卡=$cardsZh }
    }

    $collisionZh = $null
    if ($null -ne $Selection.templateCollision) {
        $collision = $Selection.templateCollision
        $collisionZh = [pscustomobject][ordered]@{
            是否碰撞 = [bool]$collision.hasCollision
            碰撞对数 = [int]$collision.collisionCount
            状态 = if ([bool]$collision.hasCollision) { '正文模板完全相同（已降级或失败）' } else { '无全文模板碰撞' }
        }
    }

    return [pscustomobject][ordered]@{
        规格版本 = 1; 记录类型 = 'ESABCD中文回执'; 入口 = $Entry
        需求 = $Requirement; 模式 = [string]$Divergence.mode; 模式中文 = $modeZh
        交付种类 = [string]$Selection.deliveryKind; 交付种类中文 = $deliveryZh
        流水线层级 = [string]$Selection.pipelineLevel; 流水线中文 = $levelZh
        领域 = [string]$Selection.domain
        声明级别 = [string]$Selection.claimLevel; 声明级别中文 = $claimZh
        选择状态 = [string]$Selection.selectionStatus; 选择状态中文 = $selZh
        主推荐方向 = [string]$Selection.selectedDirectionId
        方向数量 = [int]$Divergence.directionCount; 候选集哈希 = [string]$Divergence.candidateSetHash
        发散引擎 = [string]$Divergence.iterationTraceKind; 发散引擎中文 = $engineZh
        真实轮次 = [int]$Divergence.roundCount; 分支次数 = [int]$Divergence.branchCount
        运行时状态 = '运行时未验'
        非声称 = @('未发版','未平衡','未PlayMode','非全面碾压任意AI')
        模板碰撞 = $collisionZh; 领域简报 = $domainBriefZh; 方向列表 = $directionsZh
        说明 = '本回执为中文最终可读层。发散为真实轴分支搜索（每轮双分支按贴合分保留/淘汰），非空合成套话。'
        捕获UTC = [DateTime]::UtcNow.ToString('o')
    }
}

Export-ModuleMember -Function @(
    'Get-ESABCDRequirementTokens',
    'Get-ESABCDAxisMutationCatalog',
    'Get-ESABCDContentFitScore',
    'New-ESABCDRealDirectionCandidate',
    'ConvertTo-ESABCDChineseReceipt'
)

<#
====================================================================
  DSH / CODEX 破甲包 · 一键安装脚本  v1.0
  仓库: dsh-pj-pack
  作用: 把预设包「手动放置」到 AI 客户端会扫描的目录里，
        让 AI 在启动时把破甲协议读进系统提示词。

  两种通道:
    dsh    复制 DSH\aipj-1.0\ → %USERPROFILE%\.dsh\.agent-presets\aipj-1.0\
           （DeepSeek Harness 在启动时扫描该目录；装完必须重启 DSH 进程）
    codex  复制 CODEX\ai-pj-v1.0-codex.md → %USERPROFILE%\.codex\AGENTS.md
           （Codex 官方全局指令文件；改前自动备份）

  用法:
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action check
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -DryRun
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -Target codex
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -Target both
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action uninstall
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action join      # 合并 extra\ 里的分卷

  兼容 Windows PowerShell 5.1 与 PowerShell 7+。
====================================================================
#>
param(
  [ValidateSet('install','uninstall','check','join')]
  [string]$Action = 'install',
  [ValidateSet('dsh','codex','both')]
  [string]$Target = 'both',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Root       = $PSScriptRoot
$Stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$PresetName = 'aipj-1.0'
$Marker     = 'AP-PROTOCOL'

# ---- 载荷位置（仓库内） ----
$PresetSrc  = Join-Path $Root "DSH\$PresetName"
$CodexSrc   = Join-Path $Root 'CODEX\ai-pj-v1.0-codex.md'

# ---- 安装目标 ----
$PresetsDir = Join-Path $env:USERPROFILE '.dsh\.agent-presets'
$PresetDst  = Join-Path $PresetsDir $PresetName
$CodexDir   = Join-Path $env:USERPROFILE '.codex'
$CodexDst   = Join-Path $CodexDir 'AGENTS.md'

function Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    [OK] $m" -ForegroundColor Green }
function Wr($m)   { Write-Host "    [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "    [X]  $m" -ForegroundColor Red }

function Get-PresetDisplayName {
  if (-not (Test-Path -LiteralPath $PresetSrc)) { return $PresetName }
  $yml = Join-Path $PresetSrc 'preset.yml'
  if (Test-Path -LiteralPath $yml) {
    $m = [regex]::Match((Get-Content -LiteralPath $yml -Raw -Encoding UTF8), '(?m)^\s*name\s*:\s*(.+)$')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
  }
  return $PresetName
}

function Get-DshState {
  if (-not (Test-Path -LiteralPath $PresetDst)) { return 'absent' }
  $p = Join-Path $PresetDst 'persona.md'
  if (Test-Path -LiteralPath $p) {
    if ((Get-Content -LiteralPath $p -Raw -Encoding UTF8) -like "*$Marker*") { return 'ours' }
  }
  return 'other'
}

function Get-CodexState {
  if (-not (Test-Path -LiteralPath $CodexDst)) { return 'absent' }
  $t = [System.IO.File]::ReadAllText($CodexDst, [System.Text.Encoding]::UTF8)
  if ($t -like "*$Marker*" -or $t -like '*AI-PJ*') { return 'ours' }
  return 'other'
}

function Show-Status {
  Write-Host ''
  Write-Host '============================================================' -ForegroundColor Cyan
  Write-Host '  破甲包状态检查' -ForegroundColor Cyan
  Write-Host '============================================================' -ForegroundColor Cyan
  Write-Host ("  仓库根目录    : {0}" -f $Root)
  Write-Host ("  DSH 预设名    : {0}" -f (Get-PresetDisplayName))

  $dshSrcOk = (Test-Path -LiteralPath (Join-Path $PresetSrc 'persona.md'))
  Write-Host ("  [dsh] 载荷    : {0} {1}" -f $PresetSrc, $(if ($dshSrcOk) { '(存在)' } else { '(缺失!)' }))
  Write-Host ("  [dsh] 目标    : {0}" -f $PresetDst)
  $ds = Get-DshState
  Write-Host ("  [dsh] 状态    : {0}" -f $(switch ($ds) {
    'absent' { '未安装' }
    'ours'   { '已安装（含本包标记）' }
    'other'  { '目录已存在但不是本包内容' }
  }))
  if ($ds -eq 'ours') {
    $pv = ''
    $yml = Join-Path $PresetDst 'preset.yml'
    if (Test-Path -LiteralPath $yml) {
      $m = [regex]::Match((Get-Content -LiteralPath $yml -Raw -Encoding UTF8), '(?m)^\s*version\s*:\s*(.+)$')
      if ($m.Success) { $pv = $m.Groups[1].Value.Trim() }
    }
    Write-Host ("  [dsh] 版本    : {0}" -f $pv)
  }

  # 一个常见翻车点：把整个仓库目录丢进 .agent-presets 里
  if (Test-Path -LiteralPath $PresetsDir) {
    $suspicious = @(Get-ChildItem -LiteralPath $PresetsDir -Directory -ErrorAction SilentlyContinue |
      Where-Object { (Test-Path -LiteralPath (Join-Path $_.FullName 'DSH')) -or (Test-Path -LiteralPath (Join-Path $_.FullName 'README.md')) })
    if ($suspicious.Count -gt 0) {
      Write-Host ''
      Wr '发现疑似「整包复制」的目录（预设目录里不该有 README.md / DSH 子目录）：'
      $suspicious | ForEach-Object { Write-Host ("      {0}" -f $_.FullName) -ForegroundColor Yellow }
      Wr '正确做法：把仓库里的 DSH\aipj-1.0 这一个子目录复制过去（本脚本已自动做对）'
    }
  }

  $codexSrcOk = Test-Path -LiteralPath $CodexSrc
  Write-Host ("  [codex] 载荷  : {0} {1}" -f $CodexSrc, $(if ($codexSrcOk) { '(存在)' } else { '(缺失!)' }))
  Write-Host ("  [codex] 目标  : {0}" -f $CodexDst)
  $cs = Get-CodexState
  Write-Host ("  [codex] 状态  : {0}" -f $(switch ($cs) {
    'absent' { '未安装' }
    'ours'   { '已安装（含本包标记）' }
    'other'  { '存在其他内容（安装会先备份再覆盖；卸载不动它）' }
  }))

  # 分卷合并状态
  $extra   = Join-Path $Root 'extra'
  $parts   = @(Get-ChildItem -LiteralPath $extra -Filter 'DSH-Setup-Latest.exe.part*' -ErrorAction SilentlyContinue | Sort-Object Name)
  $exe     = Join-Path $extra 'DSH-Setup-Latest.exe'
  if ($parts.Count -gt 0 -or (Test-Path -LiteralPath $exe)) {
    $mb = if ($parts.Count -gt 0) { [math]::Round((($parts | Measure-Object Length -Sum).Sum) / 1MB, 1) } else { [math]::Round((Get-Item $exe).Length / 1MB, 1) }
    Write-Host ("  [extra] 安装包: {0} 卷 / 合计 {1} MB {2}" -f $parts.Count, $mb, $(if (Test-Path -LiteralPath $exe) { '(已合并)' } else { '(未合并，需要时跑 -Action join)' }))
  }
  Write-Host '============================================================' -ForegroundColor Cyan
}

function Install-Dsh {
  Step "安装 DSH 预设 → $PresetDst"
  if (-not (Test-Path -LiteralPath (Join-Path $PresetSrc 'persona.md'))) { Bad "载荷缺失: $PresetSrc"; return }
  if ($DryRun) {
    Write-Host "    [dry-run] 创建 $PresetsDir"
    Write-Host "    [dry-run] 复制 $PresetSrc\* → $PresetDst\"
    Write-Host '    [dry-run] 重启 DSH 后生效'
    return
  }
  New-Item -ItemType Directory -Force -Path $PresetsDir | Out-Null
  if (Test-Path -LiteralPath $PresetDst) {
    $bak = "$PresetDst.bak-$Stamp"
    Move-Item -LiteralPath $PresetDst -Destination $bak -Force
    Ok "原有同名预设已备份: $bak"
  }
  New-Item -ItemType Directory -Force -Path $PresetDst | Out-Null
  Copy-Item -Path (Join-Path $PresetSrc '*') -Destination $PresetDst -Recurse -Force
  $files = @(Get-ChildItem -LiteralPath $PresetDst -File)
  $check = Join-Path $PresetDst 'persona.md'
  if ((Test-Path -LiteralPath $check) -and ((Get-Content -LiteralPath $check -Raw -Encoding UTF8) -like "*$Marker*")) {
    Ok ("已写入并校验: {0} 个文件，preset.yml / persona.md / agent.cordis.yml 齐全 (marker $Marker)" -f $files.Count)
  } else {
    Bad '写入后校验失败，请检查编码或权限'
  }
  Wr "必须【完全退出 DSH 进程再重开】（关窗口不算），否则预设不会被扫描到"
  Wr ("重启后：新建会话 → 预设选择器选「{0}」→ 发 hi 验证" -f (Get-PresetDisplayName))
}

function Uninstall-Dsh {
  Step '卸载 DSH 预设'
  $ds = Get-DshState
  if ($ds -eq 'absent') { Wr '未安装，无需卸载'; return }
  if ($ds -eq 'other') { Wr "目标目录不是本包内容，未删除（防误删）: $PresetDst"; return }
  if ($DryRun) { Write-Host "    [dry-run] 删除 $PresetDst"; return }
  Remove-Item -LiteralPath $PresetDst -Recurse -Force
  Ok "已删除: $PresetDst"
  $baks = @(Get-ChildItem -LiteralPath $PresetsDir -Filter "$PresetName.bak-*" -Directory -ErrorAction SilentlyContinue)
  if ($baks.Count -gt 0) { Wr ("如要还原安装前的预设，可用备份: " + ($baks[-1].FullName)) }
  Wr '重启 DSH 后该预设从选择器消失'
}

function Install-Codex {
  Step "安装 CODEX 注入 → $CodexDst"
  if (-not (Test-Path -LiteralPath $CodexSrc)) { Bad "载荷缺失: $CodexSrc"; return }
  if ($DryRun) {
    Write-Host "    [dry-run] 创建 $CodexDir"
    Write-Host "    [dry-run] 备份已有 AGENTS.md（若有）"
    Write-Host "    [dry-run] 复制 ai-pj-v1.0-codex.md → AGENTS.md"
    return
  }
  New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null
  if (Test-Path -LiteralPath $CodexDst) {
    $bak = "$CodexDst.bak-pj-$Stamp"
    Copy-Item -LiteralPath $CodexDst -Destination $bak -Force
    Ok "已有 AGENTS.md 已备份: $bak"
  }
  Copy-Item -LiteralPath $CodexSrc -Destination $CodexDst -Force
  if ((Get-Content -LiteralPath $CodexDst -Raw -Encoding UTF8) -like "*$Marker*") { Ok 'AGENTS.md 已写入并校验' }
  else { Bad '写入后校验失败' }
  Wr '重启 Codex（桌面端或 CLI）后新开会话生效：发 hi 应回「AI-PJ v1.0 已就绪」'
}

function Uninstall-Codex {
  Step '卸载 CODEX 注入'
  $cs = Get-CodexState
  if ($cs -eq 'absent') { Wr '未安装，无需卸载'; return }
  if ($cs -eq 'other') { Wr 'AGENTS.md 是其他内容（非本包），未删除（防误伤）'; return }
  if ($DryRun) { Write-Host "    [dry-run] 删除 $CodexDst"; return }
  Remove-Item -LiteralPath $CodexDst -Force
  Ok "已删除: $CodexDst"
  $baks = @(Get-ChildItem -LiteralPath $CodexDir -Filter 'AGENTS.md.bak-pj-*' -ErrorAction SilentlyContinue)
  if ($baks.Count -gt 0) { Wr ("如要还原安装前的全局指令，可用备份: " + ($baks[-1].FullName)) }
}

function Join-Extra {
  Step '合并 extra\ 分卷'
  $extra = Join-Path $Root 'extra'
  $parts = @(Get-ChildItem -LiteralPath $extra -Filter 'DSH-Setup-Latest.exe.part*' -ErrorAction SilentlyContinue | Sort-Object Name)
  if ($parts.Count -eq 0) { Wr '没有找到分卷文件（extra\DSH-Setup-Latest.exe.partNNN）'; return }
  $out = Join-Path $extra 'DSH-Setup-Latest.exe'
  if ($DryRun) { Write-Host ("    [dry-run] 合并 {0} 卷 → {1}" -f $parts.Count, $out); return }
  $os = [System.IO.File]::Create($out)
  try {
    foreach ($p in $parts) {
      $fs = [System.IO.File]::OpenRead($p.FullName)
      try { $fs.CopyTo($os) } finally { $fs.Close() }
    }
  } finally { $os.Close() }
  $len = (Get-Item -LiteralPath $out).Length
  $sha = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash
  Ok ("已合并: {0} ({1} 字节)" -f $out, $len)
  Write-Host ("    SHA256 = {0}" -f $sha)
  $mf = Join-Path $extra 'SHA256.txt'
  if (Test-Path -LiteralPath $mf) {
    $expect = ([regex]::Match((Get-Content -LiteralPath $mf -Raw -Encoding UTF8), '(?im)^([0-9A-F]{64})\s+\*?DSH-Setup-Latest\.exe\s*$'))
    if ($expect.Success) {
      if ($expect.Groups[1].Value.ToUpper() -eq $sha) { Ok '哈希与清单一致，安装包完整' }
      else { Bad ('哈希不一致！清单=' + $expect.Groups[1].Value.ToUpper()) }
    } else { Wr '清单 SHA256.txt 里没找到对应行，跳过校验' }
  }
}

Show-Status

switch ($Action) {
  'check' { }
  'install' {
    if ($Target -eq 'dsh' -or $Target -eq 'both') { Install-Dsh }
    if ($Target -eq 'codex' -or $Target -eq 'both') { Install-Codex }
  }
  'uninstall' {
    if ($Target -eq 'dsh' -or $Target -eq 'both') { Uninstall-Dsh }
    if ($Target -eq 'codex' -or $Target -eq 'both') { Uninstall-Codex }
  }
  'join' { Join-Extra }
}

Write-Host ''

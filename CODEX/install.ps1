<#
====================================================================
  AI-PJ v1.1 · Codex 注入安装/卸载/检查脚本（双通道跨机版）
  载荷: ai-pj-v1.0-codex.md（源自 AI-PJ v1.0 分享合规版 persona）

  通道说明:
    agents  写 ~/.codex/AGENTS.md（官方全局指令，复制即装，不碰 config；默认推荐）
    config  写 config.toml 的 model_instructions_file（官方自定义系统指令，需已有 config）
    both    两通道同时注（同内容，system 双份，token 开销 ×2，仅特殊需求）
    auto    默认 = agents（最非侵入、跨机最稳）

  用法:
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action check
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -Channel agents -DryRun
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action uninstall -Channel agents
====================================================================
#>
param(
  [string]$Action = "install",     # install / uninstall / check
  [string]$Channel = "auto",       # auto / agents / config / both
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
if ($Channel -eq "auto") { $Channel = "agents" }

# ---- 路径（全部 %USERPROFILE% 动态，跨机通用）----
$codexDir   = Join-Path $env:USERPROFILE ".codex"
$codexCfg   = Join-Path $codexDir "config.toml"
$payloadSrc = Join-Path $PSScriptRoot "ai-pj-v1.0-codex.md"
$cfgPayload = Join-Path $codexDir "ai-pj-v1.0-codex.md"
$agentsFile = Join-Path $codexDir "AGENTS.md"
$marker     = "AP-PROTOCOL"        # 载荷身份标记（卸载防误删用）
$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"

function Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    [OK] $m" -ForegroundColor Green }
function Wr($m)   { Write-Host "    [!] $m" -ForegroundColor Yellow }

# ---- Codex 安装探测（信息性，不阻断）----
function Test-CodexPresent {
  $cli = Get-Command codex -ErrorAction SilentlyContinue
  if ($cli) { return "codex(命令) @ $($cli.Source)" }
  $appDir = Join-Path $env:LOCALAPPDATA "OpenAI\Codex"
  if (Test-Path -LiteralPath (Join-Path $appDir "bin")) { return "Codex 桌面端 @ $appDir" }
  if (Test-Path -LiteralPath $codexDir) { return "发现 ~/.codex（Codex 曾运行过）" }
  return $null
}

# ---- config 通道：当前注入行 ----
function Get-ConfigInjectLine {
  if (-not (Test-Path -LiteralPath $codexCfg)) { return $null }
  $t = [System.IO.File]::ReadAllText($codexCfg, [System.Text.Encoding]::UTF8)
  $m = [regex]::Match($t, '(?m)^\s*model_instructions_file\s*=.*$')
  return $(if ($m.Success) { $m.Value.Trim() } else { $null })
}

# ---- agents 通道：状态 + 是否为本包内容 ----
function Get-AgentsState {
  if (-not (Test-Path -LiteralPath $agentsFile)) { return "absent" }
  $t = [System.IO.File]::ReadAllText($agentsFile, [System.Text.Encoding]::UTF8)
  if ($t -like "*$marker*" -or $t -like "*AI-PJ*") { return "ai-pj" }
  return "other"
}

# ---- 汇总状态 ----
function Show-Status {
  Write-Host ""
  Write-Host "======================================================" -ForegroundColor Cyan
  Write-Host "  AI-PJ v1.1 · Codex 注入状态" -ForegroundColor Cyan
  Write-Host "======================================================" -ForegroundColor Cyan
  $codex = Test-CodexPresent
  Write-Host "  Codex 检测    : $(if($codex){$codex}else{'未检测到（安装后首次启动 Codex 即生效）'})"
  Write-Host "  载荷源        : $payloadSrc ($((Get-Item $payloadSrc -ErrorAction SilentlyContinue).Length)B)"
  if (Test-Path -LiteralPath $codexCfg) {
    $cur = Get-ConfigInjectLine
    Write-Host "  [config] 配置 : $codexCfg"
    Write-Host "  [config] 注入 : $(if($cur){$cur}else{'（无 model_instructions_file 行）'})"
    $own = if ($cur -and $cur -like "*ai-pj-v1.0-codex.md*") { " ← 本包" } else { "" }
    if ($own) { Write-Host "  [config] 判定 : 已指向本包载荷$own" }
  } else { Write-Host "  [config] 配置 : 不存在（此机器 Codex 可能未初始化）" }
  $ag = Get-AgentsState
  Write-Host "  [agents] 文件 : $agentsFile"
  Write-Host "  [agents] 状态 : $(switch($ag){'absent'{'不存在'};'ai-pj'{'含本包标记(AI-PJ)'};'other'{'存在其他内容(非本包)'}})"
  Write-Host "======================================================" -ForegroundColor Cyan
}

# ---- 冲突提示（安装前）----
function Warn-Conflicts {
  $cur = Get-ConfigInjectLine
  if ($cur -and $cur -notlike "*ai-pj-v1.0-codex.md*") {
    Wr "config.toml 当前指向其他注入: $cur"
    Wr "   → -Channel agents 不碰它（并存）；-Channel config/both 会替换它（备份可还原）"
  }
  $ag = Get-AgentsState
  if ($ag -eq "other") {
    Wr "~/.codex/AGENTS.md 已存在其他内容"
    Wr "   → 安装会先备份为 AGENTS.md.bak-aipj-$stamp 再覆盖；卸载只删本包内容并提示还原"
  }
}

# ---- agents 通道：安装（复制一个文件，零 TOML 风险）----
function Install-Agents {
  Step "安装 agents 通道（~/.codex/AGENTS.md）"
  if (-not (Test-Path -LiteralPath $payloadSrc)) { Wr "载荷缺失: $payloadSrc"; return }
  if ($DryRun) { Write-Host "    [dry-run] 创建 $codexDir / 备份已有 AGENTS.md / 复制载荷到 AGENTS.md"; return }
  New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
  if (Test-Path -LiteralPath $agentsFile) {
    $bakAg = "$agentsFile.bak-aipj-$stamp"
    Copy-Item -LiteralPath $agentsFile -Destination $bakAg -Force
    Ok "已有 AGENTS.md 已备份: $bakAg"
  }
  Copy-Item -LiteralPath $payloadSrc -Destination $agentsFile -Force
  # 校验写入成功
  $back = [System.IO.File]::ReadAllText($agentsFile, [System.Text.Encoding]::UTF8)
  if ($back -like "*$marker*") { Ok "AGENTS.md 已写入并校验（含 $marker 标记）" }
  else { Wr "写入后校验未找到标记（可能编码问题），请人工确认" }
  Wr "重启 Codex / 新开会话后生效（握手: hi → AI-PJ v1.0 已就绪）"
}

# ---- agents 通道：卸载（只删本包内容，防误删用户自己的 AGENTS.md）----
function Uninstall-Agents {
  Step "卸载 agents 通道"
  if ($DryRun) { Write-Host "    [dry-run] 若 AGENTS.md 含本包标记则删除"; return }
  $ag = Get-AgentsState
  if ($ag -eq "absent") { Wr "AGENTS.md 不存在，无需卸载"; return }
  if ($ag -eq "other") {
    Wr "AGENTS.md 是其他内容（非本包），不删除（避免误伤）。如需覆盖请先手动处理"
    return
  }
  Remove-Item -LiteralPath $agentsFile -Force
  Ok "AGENTS.md 已删除（内容为本包标记）"
  if (Test-Path -LiteralPath "$agentsFile.bak-aipj-*") { Wr "如要还原安装前的 AGENTS.md：找 *.bak-aipj-* 备份改回即可" }
}

# ---- config 通道：安装（备份 → 复制载荷 → 安全插入注入行，无数组索引坑）----
function Install-Config {
  Step "安装 config 通道（model_instructions_file）"
  if (-not (Test-Path -LiteralPath $payloadSrc)) { Wr "载荷缺失: $payloadSrc"; return }
  if (-not (Test-Path -LiteralPath $codexCfg)) {
    Wr "未找到 Codex 配置: $codexCfg（Codex 从未启动？）"
    Wr "   → 建议改用 -Channel agents（无需 config，复制即装）"
    return
  }
  if ($DryRun) { Write-Host "    [dry-run] 备份 config.toml / 复制载荷 / 安全插入 model_instructions_file 行"; return }

  $bak = "$codexCfg.bak-aipj-$stamp"
  Copy-Item -LiteralPath $codexCfg -Destination $bak -Force
  Ok "config.toml 已备份: $bak"

  Copy-Item -LiteralPath $payloadSrc -Destination $cfgPayload -Force
  Ok "载荷已复制: $cfgPayload"

  $line = "model_instructions_file = '" + ($cfgPayload -replace '\\', '/') + "'"
  $text = [System.IO.File]::ReadAllText($codexCfg, [System.Text.Encoding]::UTF8)
  # 1) 去掉旧注入行（任意引号写法）
  $text = [regex]::Replace($text, '(?m)^\s*model_instructions_file\s*=.*\r?\n', '')
  # 2) 在首个 [table] 行之前插入；若无顶层键则插文件头。用逐行重组避开 PS 的 0..-1 陷阱
  $lines = $text -split "`n"
  $at = $lines.Count
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].TrimStart().StartsWith('[')) { $at = $i; break }
  }
  $new = @()
  if ($at -gt 0) { $new += $lines[0..($at - 1)] }
  $new += $line
  if ($at -lt $lines.Count) { $new += $lines[$at..($lines.Count - 1)] }
  [System.IO.File]::WriteAllText($codexCfg, ($new -join "`n"), (New-Object System.Text.UTF8Encoding $false))
  Ok "model_instructions_file 行已插入（原 $($lines.Count) 行 → 现 $($new.Count) 行）"
  Wr "重启 Codex 桌面端/新开会话后生效"
}

# ---- config 通道：卸载 ----
function Uninstall-Config {
  Step "卸载 config 通道"
  if ($DryRun) { Write-Host "    [dry-run] 移除注入行 / 删除载荷"; return }
  if (Test-Path -LiteralPath $codexCfg) {
    $text = [System.IO.File]::ReadAllText($codexCfg, [System.Text.Encoding]::UTF8)
    $new = [regex]::Replace($text, '(?m)^\s*model_instructions_file\s*=.*\r?\n', '')
    if ($new -ne $text) {
      [System.IO.File]::WriteAllText($codexCfg, $new, (New-Object System.Text.UTF8Encoding $false))
      Ok "config.toml 注入行已移除"
    } else { Wr "config.toml 中无注入行" }
  } else { Wr "config.toml 不存在" }
  if (Test-Path -LiteralPath $cfgPayload) { Remove-Item -LiteralPath $cfgPayload -Force; Ok "载荷已删除: $cfgPayload" }
}

# ---- 主流程 ----
$validChannels = @("agents", "config", "both")
if ($validChannels -notcontains $Channel) { Wr "未知 Channel: $Channel（agents / config / both / auto）"; exit 1 }

Show-Status

switch ($Action.ToLower()) {
  "check"   { }
  "install" {
    Warn-Conflicts
    if ($Channel -eq "agents" -or $Channel -eq "both") { Install-Agents }
    if ($Channel -eq "config" -or $Channel -eq "both") { Install-Config }
  }
  "uninstall" {
    if ($Channel -eq "agents" -or $Channel -eq "both") { Uninstall-Agents }
    if ($Channel -eq "config" -or $Channel -eq "both") { Uninstall-Config }
  }
  default { Wr "未知 Action: $Action（install / uninstall / check）" }
}
Write-Host ""

<#
====================================================================
  push-to-github.ps1 · 把本包一键推送到自己的 GitHub 仓库
  用法:
    powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1
    powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 -RepoUrl https://github.com/me/dsh-pj-pack.git -Token ghp_xxx
    powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 -RepoUrl ... -Token ... -Create   # 仓库不存在时自动创建（需 token 有 repo 权限）

  行为:
    - 自动 git init / add / commit（若尚未初始化）
    - 把 remote origin 设为你的仓库
    - token 只用于本次推送，不落盘（推完把 origin 改回不带 token 的地址）
    - 推送前做安全自检：文件是否超 100MB、是否残留个人绝对路径
====================================================================
#>
param(
  [string]$RepoUrl,
  [string]$Token,
  [string]$Branch = 'main',
  [switch]$Create
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

function Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    [OK] $m" -ForegroundColor Green }
function Wr($m)   { Write-Host "    [!]  $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "    [X]  $m" -ForegroundColor Red }

function Wait-Enter { param([string]$msg = '按回车关闭'); Write-Host ''; Write-Host ("  " + $msg + '...') -ForegroundColor DarkGray; [void](Read-Host) }

# ---------- 0. 检查 git ----------
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { Bad '未找到 git，请先安装 Git for Windows'; Wait-Enter; exit 1 }
Ok ("git: " + $git.Source)

# ---------- 1. 采集参数 ----------
if (-not $RepoUrl) {
  Write-Host ''
  Write-Host '请输入你的 GitHub 仓库地址，例如：' -ForegroundColor Gray
  Write-Host '    https://github.com/wangyingjie-wyj/dsh-pj-pack.git' -ForegroundColor DarkGray
  $RepoUrl = Read-Host '仓库地址'
}
if (-not $RepoUrl) { Bad '仓库地址为空，退出'; Wait-Enter; exit 1 }
$RepoUrl = $RepoUrl.Trim().TrimEnd('/')
if ($RepoUrl -notlike '*.git') { $RepoUrl = "$RepoUrl.git" }

if (-not $Token) {
  Write-Host ''
  Write-Host '请输入 GitHub Personal Access Token（勾选 repo 权限；输入时不显示）：' -ForegroundColor Gray
  Write-Host '  生成地址: https://github.com/settings/tokens  → Generate new token (classic)' -ForegroundColor DarkGray
  $sec = Read-Host 'Token' -AsSecureString
  $Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
             [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
if (-not $Token) { Bad 'Token 为空，退出'; Wait-Enter; exit 1 }

# 从地址里解析 owner/repo
$m = [regex]::Match($RepoUrl, 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+?)(\.git)?$')
if (-not $m.Success) { Bad "无法从地址解析 owner/repo: $RepoUrl"; Wait-Enter; exit 1 }
$Owner = $m.Groups['owner'].Value
$Repo  = $m.Groups['repo'].Value
Ok ("目标仓库: {0}/{1}  (分支 {2})" -f $Owner, $Repo, $Branch)

Push-Location $Root
try {
  # ---------- 2. 预检：大文件 & 隐私 ----------
  Step '推送前自检'
  $maxMB = 100
  $big = @(Get-ChildItem $Root -Recurse -File -Force |
           Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Length -ge ($maxMB * 1MB) })
  if ($big.Count -gt 0) {
    Bad ("发现 >= {0}MB 的文件，GitHub 会拒绝推送：" -f $maxMB)
    $big | ForEach-Object { Write-Host ("      {0}  {1} MB" -f $_.FullName.Replace("$Root\",''), [math]::Round($_.Length/1MB,1)) -ForegroundColor Red }
    Wr '处理：把大文件切分（本包 install.ps1 -Action join 是合并；切分见 docs/上传到GitHub.md），或删除该文件'
    Wait-Enter; exit 1
  } else { Ok ("无超限文件（最大 {0} MB）" -f [math]::Round((Get-ChildItem $Root -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\\.git\\' } | Measure-Object Length -Maximum).Maximum / 1MB, 1)) }

  # 只报"真人路径"：排除 <你> / %USERPROFILE% / <用户名> 这类占位写法
  $files = @(Get-ChildItem $Root -Recurse -File -Include *.md, *.ps1, *.yml, *.txt -Force |
             Where-Object { $_.FullName -notmatch '\\\.git\\' } | Select-Object -ExpandProperty FullName)
  $leak = @()
  if ($files.Count -gt 0) {
    $leak = @($files | Select-String -Pattern 'C:\\Users\\[^\\<>%]+|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}' -ErrorAction SilentlyContinue |
             Where-Object { $_.Matches[0].Value -notmatch '%USERPROFILE%' })
  }
  if ($leak.Count -gt 0) {
    Wr '文本文件里发现疑似个人路径或 token，请确认后再推：'
    $leak | Select-Object -First 10 | ForEach-Object { Write-Host ("      {0}:{1}" -f $_.Path.Replace("$Root\",''), $_.LineNumber) -ForegroundColor Yellow }
  } else { Ok '未发现个人绝对路径 / token 残留' }

  # ---------- 3. 初始化并提交 ----------
  Step '准备本地提交'
  if (-not (Test-Path (Join-Path $Root '.git'))) {
    & git init -b $Branch | Out-Null
    Ok '已 git init'
  } else { Ok '已有 .git' }

  & git add -A 2>$null
  $dirty = (& git status --porcelain)
  if ($dirty) {
    & git -c user.name="$Owner" -c user.email="$Owner@users.noreply.github.com" commit -m "更新：DSH/CODEX 破甲包（手动放置版）" 2>$null | Out-Null
    Ok '已提交改动'
  } else { Ok '无未提交改动' }

  # ---------- 4. 可选：创建远端仓库 ----------
  if ($Create) {
    Step '检查远端仓库是否存在'
    $api = "https://api.github.com/repos/$Owner/$Repo"
    $hdr = @{ Authorization = "token $Token"; 'User-Agent' = 'dsh-pj-pack-push' }
    $exists = $false
    try { $r = Invoke-WebRequest -Uri $api -Headers $hdr -Method Get -UseBasicParsing -ErrorAction Stop; $exists = ($r.StatusCode -eq 200) }
    catch { $exists = $false }
    if ($exists) { Ok '远端仓库已存在' }
    else {
      Write-Host "    远端不存在，尝试创建 $Owner/$Repo ..." -ForegroundColor Gray
      $body = @{ name = $Repo; private = $false; auto_init = $false } | ConvertTo-Json
      try {
        Invoke-WebRequest -Uri 'https://api.github.com/user/repos' -Headers $hdr -Method Post -Body $body -ContentType 'application/json' -UseBasicParsing -ErrorAction Stop | Out-Null
        Ok '远端仓库已创建'
      } catch { Wr ("自动创建失败（可能 token 无 repo 权限或组织限制）：" + $_.Exception.Message) }
    }
  }

  # ---------- 5. 推送（token 只在本次 URL 里，不写进 .git/config） ----------
  Step '推送'
  $auth = "https://$Owner`:$Token@github.com/$Owner/$Repo.git"
  & git remote remove origin 2>$null | Out-Null
  & git remote add origin $RepoUrl 2>$null | Out-Null
  & git push $auth "${Branch}:${Branch}" --force-with-lease 2>&1 | ForEach-Object { Write-Host "    $_" }
  if ($LASTEXITCODE -eq 0) {
    Ok '推送成功'
    Write-Host ''
    Write-Host ("    仓库地址: https://github.com/{0}/{1}" -f $Owner, $Repo) -ForegroundColor Green
  } else {
    Bad '推送失败，常见原因见 docs/上传到GitHub.md 的报错表'
  }
}
finally { Pop-Location }

Write-Host ''
Wr '提示：如果你打算长期用这个仓库，建议安装 GitHub CLI（gh）或用 Git Credential Manager 记住凭据，之后直接 git push 即可'
Wait-Enter '按回车关闭窗口'

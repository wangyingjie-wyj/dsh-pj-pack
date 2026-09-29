# 把这个包整包上传到自己的 GitHub

三种走法，按你的实际情况选一种即可。**推荐走法 1**（命令行一次到位，可重复更新）。

前置：本机已装 Git（`git --version` 有输出）。GitHub 账号已有。

---

## 走法 0 · 一键脚本（最省事）

仓库里已带 `push-to-github.ps1`：

1. 先去 <https://github.com/new> 建一个空仓库（不要勾 Add README / .gitignore / license），比如叫 `dsh-pj-pack`；
2. 去 <https://github.com/settings/tokens> → **Generate new token (classic)** → 勾 `repo` → 复制 token；
3. 双击 **`双击推送到GitHub.bat`**（或跑 `push-to-github.ps1`），按提示粘贴仓库地址和 token。

脚本会自己完成：自检（>100MB 文件、个人路径/token 残留）→ `git init/add/commit` → 推送。
加 `-Create` 参数还能顺便用 API 帮你把远端仓库建出来。

```powershell
powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1 `
  -RepoUrl https://github.com/<用户名>/dsh-pj-pack.git -Token <你的token> -Create
```

**Token 只在本次推送的 URL 里使用，不写进 `.git/config`。**

---

## 走法 1 · 全手动 HTTPS + Personal Access Token

### 1) 建空仓库

浏览器打开 <https://github.com/new>：

- Repository name：`dsh-pj-pack`（可自定，建议纯英文/数字）
- 选 **Public** 或 **Private**（都行）
- **不要**勾选 "Add a README file" / .gitignore / license（本地已有）

创建后记下地址，例如 `https://github.com/wangyingjie-wyj/dsh-pj-pack.git`。

### 2) 生成 Token（GitHub 已不允许用账号密码推送）

<https://github.com/settings/tokens> → **Generate new token (classic)** →
勾选 `repo`（私有仓库必勾；公开仓库勾 `public_repo` 即可）→ 生成 → **复制整串 token（只显示一次）**。

### 3) 本地初始化并推送

```powershell
cd "C:\Users\wyj\Desktop\dsh-pj-pack"

git init -b main
git config user.name  "你的GitHub用户名"
git config user.email "你的GitHub邮箱"

git add -A
git commit -m "DSH/CODEX 破甲包：手动放置版（预设 + 双通道安装脚本 + 客户端分卷）"

git remote add origin https://github.com/<你的用户名>/dsh-pj-pack.git

# 推送时用户名填 GitHub 用户名，密码处粘贴上面那串 token（不是账号密码）
git push -u origin main
```

推送过程中会弹凭据窗口或提示输入；token 粘贴进去即可。Windows 上会由 Git Credential Manager 记住，下次不用再输。

> 若之前已配过 gitee 的 generic 凭据导致混淆，可强制指定：
> `git remote set-url origin https://<用户名>@github.com/<用户名>/dsh-pj-pack.git`

### 4) 之后更新

```powershell
git add -A
git commit -m "更新说明"
git push
```

---

## 走法 2 · 网页上传（零命令，但注意两点）

浏览器进仓库 → **Add file → Upload files** → 把 `dsh-pj-pack` 里的内容拖进去 → Commit。

**两个坑必须知道：**

1. **网页上传单文件上限较严**（免费账号通常几十 MB），`extra/` 里的 96 MB 分卷**多半传不上去**；
2. 拖文件夹时浏览器通常会保留目录结构，但空文件夹会丢（本仓库没有空目录，问题不大）。

对策：

- 大文件走 `git push`（走法 1），或
- 干脆把 `extra/` 排除（`extra/` 只是 DSH 客户端安装包，你已装 DSH 就不需要），
  在 `.gitignore` 里加一行 `extra/` 即可，仓库仍有完整破甲包本体。

---

## 走法 3 · Git LFS（想让安装包保持单个 228 MB 文件）

```powershell
git lfs install
git lfs track "*.exe"
git add .gitattributes
# 把 extra/ 的三个 part 合并回完整 exe（install.ps1 -Action join），放到 extra/ 下再 add
git add -A
git commit -m "带 LFS 大文件"
git push -u origin main
```

注意：LFS 有免费配额（存储/流量），别人 clone 需要装 git-lfs。
**分卷方案（本仓库默认）不依赖 LFS、clone 即完整**，一般更省事。

---

## 关于 `extra/` 的分卷

DeepSeek Harness 客户端安装包 238,761,824 字节（227.7 MB），超过 GitHub 单文件 **100 MB 硬限制**，
故切成 3 卷：

| 文件 | 大小 |
|---|---|
| `DSH-Setup-Latest.exe.part001` | 100,663,296 B (96 MiB) |
| `DSH-Setup-Latest.exe.part002` | 100,663,296 B (96 MiB) |
| `DSH-Setup-Latest.exe.part003` | 37,435,232 B |

合并（自动校验 SHA256）：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action join
```

原始完整文件的哈希（供核对）：

```
SHA256  21CAFEBAFCCF0FCF20F72BDD800267DDB71E2B106754BFE7A507B2FB439F0B73
SIZE    238761824
```

分卷 → 合并的往返一致性已实测通过（合并结果哈希与原始文件逐字节一致）。

---

## 推送前自检清单

```powershell
# 1) 确认没有把个人隐私/凭据带进去
git status --short
Select-String -Path .\**\*.md,.\**\*.ps1 -Pattern 'token|password|密码|C:\\Users\\' -SimpleMatch

# 2) 确认大文件都在 100MB 以下（分卷每个 96MB，安全）
Get-ChildItem -Recurse -File | Sort-Object Length -Descending |
  Select-Object -First 5 FullName, @{n='MB';e={[math]::Round($_.Length/1MB,1)}}

# 3) 确认文件哈希与清单一致
Get-FileHash .\DSH\aipj-1.0\persona.md -Algorithm SHA256
```

- 本仓库内的路径全部使用 `%USERPROFILE%` 动态解析，不含任何个人绝对路径；
- 不含任何 token、账号、cookie；
- `extra/` 里是 DeepSeek Harness **官方客户端安装包**（原样分卷），如不希望分发可删除该目录并在 `.gitignore` 里加 `extra/`。

---

## 常见推送报错

| 报错 | 原因 | 处理 |
|---|---|---|
| `remote: Support for password authentication was removed` | 用了账号密码 | 改用 Personal Access Token 当密码 |
| `remote: error: File ... is 227.76 MB; this exceeds GitHub's file size limit of 100.00 MB` | 单文件超限 | 用本仓库的分卷方案（勿把合并后的 exe 提交） |
| `failed to push some refs` / `non-fast-forward` | 远端已有提交 | `git pull --rebase origin main` 后再 push |
| `git: 'lfs' is not a git command` | 没装 git-lfs | 用分卷方案，或先 `git lfs install` 前装 git-lfs |
| 中文文件名显示成 `\344\275\277...` | git 转义显示 | 仅显示问题，可 `git config core.quotepath false` |
| `LF will be replaced by CRLF` 警告 | Windows 换行 | 无害，可忽略；或加 `.gitattributes` 固定 |

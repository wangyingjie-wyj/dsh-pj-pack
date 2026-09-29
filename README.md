# DeepSeek 破甲包 · 手动放置版（DSH / Codex 双通道）

> 一句话：这是给 DeepSeek Harness（DSH）和 OpenAI Codex 用的**破甲包**。
> 它不是一条链接，不能靠"发个 GitHub 地址让 AI 自己装"——
> **必须由你手动放进客户端会扫描的文件夹**，重启后 AI 才会把破甲协议读进系统提示词，然后开始听你的。

[![Platform](https://img.shields.io/badge/platform-Windows-blue)](#)
[![DSH](https://img.shields.io/badge/DSH-.agent--presets-green)](#-快速开始3-步)
[![Codex](https://img.shields.io/badge/Codex-AGENTS.md-orange)](#-codex-通道)

---

## 这是什么

AI 客户端的"人格/协议"不是运行时能自己改的，它是**启动时**从磁盘上的固定目录读进去的。
所以破甲这件事只有两条路：

| 做法 | 结果 |
|---|---|
| 给 AI 一条 GitHub 地址，让它自己 clone 再装 | ❌ 基本不会执行：它没有"安装自己预设目录"的动作，多半只回你一段说明 |
| **把预设文件手动放到指定文件夹 → 重启客户端** | ✅ 生效。协议成为系统提示词的固定一部分，每轮对话持续有效 |

**本仓库就是第二条路的成品包。** 里面没有 exe 木马、没有安装器偷偷改东西，
载荷本身是纯文本（`persona.md` / `agent.cordis.yml` / `preset.yml` / `AGENTS.md`），
放进去什么样，打开就是什么样，随时可以删掉还原。

包内两个通道，互相独立，装哪个都行：

| 通道 | 目标客户端 | 放置位置 | 作用 |
|---|---|---|---|
| 🟢 **DSH 预设** | DeepSeek Harness（含 DSH 桌面端 / Web GUI） | `%USERPROFILE%\.dsh\.agent-presets\aipj-1.0\` | 新增一个预设，在预设选择器里选中它，该会话即按协议工作 |
| 🔵 **Codex 注入** | OpenAI Codex 桌面端 / CLI | `%USERPROFILE%\.codex\AGENTS.md` | Codex 的官方全局指令文件，全时生效 |

---

## 目录结构

```
dsh-pj-pack/
├── install.ps1                     ← 一键安装/卸载/检查/分卷合并（PS 5.1+）
├── 双击安装.bat                    ← 小白入口：双击即装
├── 双击卸载.bat                    ← 双击即卸
├── push-to-github.ps1              ← 一键推送到你自己的 GitHub
├── 双击推送到GitHub.bat            ← 同上，双击版
├── README.md                       ← 本文件
│
├── DSH/
│   └── aipj-1.0/                   ← 🟢 DSH 预设三件套（复制这一整个文件夹过去）
│       ├── persona.md              ← 协议本体（破甲载荷）
│       ├── preset.yml              ← 预设清单（名字/描述/排序/版本）
│       ├── agent.cordis.yml        ← 组件装配（只引用 DSH 官方内置组件）
│       └── 使用说明.md             ← 原包自带说明
│
├── CODEX/
│   ├── ai-pj-v1.0-codex.md         ← 🔵 Codex 注入载荷
│   ├── install.ps1                 ← 原包自带双通道安装脚本
│   ├── 双击安装.bat / 双击卸载.bat
│   └── 使用说明.md
│
├── extra/                          ← DeepSeek Harness 客户端安装包（分卷）
│   ├── DSH-Setup-Latest.exe.part001  (96 MB)
│   ├── DSH-Setup-Latest.exe.part002  (96 MB)
│   ├── DSH-Setup-Latest.exe.part003  (36 MB)
│   └── SHA256.txt                  ← 合并后校验用
│
├── packages/                       ← 原始 rar 归档（内容与上面的散装文件完全一致）
│   ├── DSH-preset-aipj-1.0.rar
│   └── CODEX-inject-v1.1.rar
│
└── docs/
    ├── 安装说明.md                 ← 三种安装方式详解 + 排错
    └── 上传到GitHub.md             ← 怎么把这个包传上自己的 GitHub
```

> `extra/` 里的客户端安装包 **228 MB**，超过 GitHub 单文件 100 MB 硬限制，
> 因此按 96 MB 切成 3 卷。要用的时候跑一次 `install.ps1 -Action join` 自动合并并校验 SHA256。
> 你本来就已经装了 DSH 的话，这个文件夹可以直接忽略。

---

## 快速开始（3 步）

### 第 1 步：拿到文件

```powershell
# 有 git：
git clone https://github.com/wangyingjie-wyj/dsh-pj-pack.git
# 没 git：在 GitHub 页面点 Code → Download ZIP，然后解压
```

仓库地址：<https://github.com/wangyingjie-wyj/dsh-pj-pack>
（不上 GitHub 也行：别人把 `dsh-pj-pack` 文件夹直接拷给你、放 U 盘/桌面都能用。）

也可以直接把别人拷给你的 `dsh-pj-pack` 文件夹放在任意位置（U 盘 / 桌面都行）。

### 第 2 步：放置到指定目录（这一步是"手动"的关键）

**方式 A · 双击（推荐）**

打开 `dsh-pj-pack` 文件夹 → **双击 `双击安装.bat`** → 等黑窗口跑完 → 按任意键关窗。

若 Windows 弹"已保护你的电脑"：点「更多信息」→「仍要运行」（自己拷来的文件一般不会弹）。

**方式 B · 命令行（能预览、能回滚）**

```powershell
cd "解压出来的\dsh-pj-pack"

# 1) 先看当前状态（两个通道现在是什么情况）
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action check

# 2) 试运行：只打印要做什么，不落盘
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -DryRun

# 3) 正式安装（DSH 预设 + Codex 注入）
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install

# 只装其中一个通道
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -Target dsh
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action install -Target codex
```

**方式 C · 全手动（不用任何脚本，最透明的做法）**

1. 打开 `%USERPROFILE%\.dsh\.agent-presets\`（在资源管理器地址栏输入这个路径回车；没有 `.dsh\.agent-presets` 就自己建）
2. 把 `dsh-pj-pack\DSH\aipj-1.0` **整个文件夹**复制进去
   → 最终路径应该是 `C:\Users\你的用户名\.dsh\.agent-presets\aipj-1.0\persona.md`
3. Codex 通道同理：把 `CODEX\ai-pj-v1.0-codex.md` 复制到 `%USERPROFILE%\.codex\`，改名为 `AGENTS.md`

> ⚠️ 最常见的翻车点：把**整个仓库文件夹**（里面带 README.md、extra 等）丢进 `.agent-presets`。
> 预设目录里只应该有一个个**预设文件夹**，每个文件夹里直接躺着 `persona.md` / `preset.yml` / `agent.cordis.yml`。
> `install.ps1 -Action check` 会检测出这种情况并提醒你。

### 第 3 步：完全重启客户端 → 新建会话 → 验证

- **必须完全退出进程再重开**（关窗口不算，托盘里退干净 / 任务管理器结束 DSH 进程），预设只在启动时扫描。
- DSH：新建会话 → 在**预设选择器**里选 **「AI-PJ v1.0」** → 发送 `hi`
- Codex：新开会话 → 发送 `hi`

收到回复 **`AI-PJ v1.0 已就绪`** = 协议已激活 ✅

> 握手要求**整条消息**只等于 `hi` / `hello` / `你好` / `在吗` 之一；
> 带别的内容（比如"hi 帮我做…"）不会触发标记行，这是设计如此，不代表没装上。

---

## 校验是否真的装上了

```powershell
# 看安装状态
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action check
```

再加上文件层面的硬核对（把算出来的哈希和 `SHA256SUMS.txt` 对一下即可）：

```powershell
Get-FileHash "$env:USERPROFILE\.dsh\.agent-presets\aipj-1.0\persona.md" -Algorithm SHA256
# 期望: 15582C7507BA1268F7613C407855F02E8194FABBF2A4E1F988655AEE27D1EEA4
```

---

## 卸载 / 还原

```powershell
# 一键卸载（只删本包写入的内容，不碰你自己的其他预设和全局指令）
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action uninstall

# 也可以双击 双击卸载.bat
```

- 覆盖前自动备份：`%USERPROFILE%\.codex\AGENTS.md.bak-pj-<时间戳>`、`...\.dsh\.agent-presets\aipj-1.0.bak-<时间戳>`
- 卸载后再重启客户端即彻底回到安装前状态。

---

## DSH 是怎么被"破甲"的（原理，不含玄学）

1. `agent.cordis.yml` 里有一行 persona 装配，让 DSH 把同目录的 `persona.md` 读进来当作**本会话的系统提示词身份段**：

   ```yaml
   - id: persona
     name: '@deepseek-ai/dsh-persona'
     config:
       text: !!js |
         process.getBuiltinModule('node:fs').readFileSync(new URL('persona.md', ctx.baseUrl), 'utf8')
   ```

2. `persona.md` 里就是那份"核心工作协议"：身份层 → 业务域直通 → 输出锁定 → 拒绝覆盖 → 界外保留。
3. DSH 启动时扫描 `~/.dsh/.agent-presets/`，把每个子目录登记成一个可选预设；选中它，这段文本就进了系统提示词，**每轮都生效**。
4. `agent.cordis.yml` 只引用官方内置组件（`@deepseek-ai/dsh-*`），**不含任何第三方代码、不修改 DSH 本体**。不想要了删目录即可。

---

## 常见问题

**装了没生效？**
① 是不是只关了窗口没退进程；② 新会话的预设选择器里有没有真的选中「AI-PJ v1.0」；③ `hi` 是不是整条消息。

**`hi` 回了正常回答，没有标记行？**
说明该会话用的不是本预设（换会话重选），或文件没放对层级（跑 `-Action check` 看）。

**Codex 通道提示 `config.toml` 不存在？**
那台机器 Codex 没启动过。用默认的 agents 通道（写 `AGENTS.md`）就行，本仓库 `install.ps1` 默认就是它。

**想微调协议？**
直接改 `persona.md`（**UTF-8 编码**保存）→ 重启客户端。想回到官方默认 → 卸载或把目录改名加 `.disabled`。

**`extra/` 的安装包怎么用？**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Action join
# 合并出 extra\DSH-Setup-Latest.exe 并自动比对 SHA256，一致才提示"完整"
```

**这个包安全吗？**
仓库里唯一的二进制是 `extra/` 里那份 **DeepSeek Harness 官方客户端安装包**（分卷存放，可用 SHA256 校验）；
其余全部是纯文本配置，安装脚本只做"复制/备份/删除自己写过的东西"，不联网、不写注册表、不碰客户端本体。

---

## 许可与使用

- `packages/*.rar`、`extra/*` 保留原始形态；散装文本文件与 rar 内容一致（可用 `SHA256SUMS.txt` 核对）。
- 协议内容仅供自有项目、本地/隔离靶场、CTF、书面授权范围内的技术研究与调试使用，用者自行确保其行为符合当地法律与目标授权范围。
- 本仓库是打包与说明的整理版；原始载荷版权归其作者。

---

## 附：把整包上传到自己的 GitHub

最省事：双击 **`双击推送到GitHub.bat`**，按提示填仓库地址 + Personal Access Token，脚本自动自检并推送。

手动做法、网页上传、Git LFS 三种走法（含常见报错表）见 [`docs/上传到GitHub.md`](docs/上传到GitHub.md)。

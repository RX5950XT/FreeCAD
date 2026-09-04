# CONTEXT — 開發交接紀錄

> 給下一位 AI Agent 的接手文件，持續精簡維護。專案規範見 `CLAUDE.md` / `AGENTS.md`。

## 專案定位

**FreeCAD 繁體中文現代化分支**：介面全面在地化（臺灣用語）+ 現代化 QSS 樣式改造。

## Git remote 配置

| remote | 用途 | 備註 |
|--------|------|------|
| `origin` | 我們的 fork（RX5950XT/FreeCAD） | 正常推送目標 |
| `upstream` | 官方 FreeCAD/FreeCAD | **push 已停用**（位址設為 `DISABLE_PUSH_TO_UPSTREAM`），只抓不推，避免影響原作者 |

## 我們的自訂變更（務必保留）

1. `feat: 從 zh-CN 補齊 zh-TW 繁體中文翻譯（OpenCC s2twp）` — 20+ 個 `*_zh-TW.ts`
2. `chore: 新增批次翻譯腳本與專案文件` — `tools/translate_tw_from_cn.py`、`CLAUDE.md`、`AGENTS.md`
3. `feat: 現代化 UI 樣式` — `FreeCAD.qss`、`parameters/*.yaml`（圓角選單/捲軸/提示框/輸入框）
4. `chore: 新增 Windows NSIS 安裝檔打包流程` — `package/WindowsInstaller/`、`tools/build_windows_bundle.ps1`
5. ~~`feat: AgentCAD`~~ — 已於 2026-09-03 拆成獨立 repo `../AgentCAD`，
   相關檔案與 6 行 `BUILD_AGENT` CMake 皆已從本分支移除。

## AgentCAD 已獨立（2026-09-03）

原 `src/Mod/Agent/`（純 Python FreeCAD 模組）與 `tools/agentcad-mcp/`（MCP server）
已拆成獨立 repo：`D:/Workspace/Personal_Project/AgentCAD`，並以 junction 掛在
`%APPDATA%/FreeCAD/Mod/Agent`。它對本分支零依賴，原版 FreeCAD 1.2 就能跑。

舊的 `FreeCADMCP` addon 兩份都已刪除（`v1-2/Mod_disabled/` 與 `Mod/`），
它的用戶端 `freecad` MCP server 也從 `~/.claude.json` 移除
（與 `agentcad` 功能重複，每次重連都多起一批進程）。
要裝回去：`claude mcp add freecad -s user -- uvx freecad-mcp`。

本分支從此只負責繁體中文化與 QSS 樣式改造。

### 完整編譯（2026-09-03 首次成功）

在這之前這個分支**從未編譯成功過**，卡在兩個互相獨立的問題，兩個都已修好並寫進
`CLAUDE.md` 的疑難排解：

1. `cl.exe` 不在 PATH —— pixi 把 `CC` 設成 `cl.exe`，但要先跑 `vcvars64.bat`。
2. `.pixi` 環境是專案還在 `D:\Workspace_cloud\` 時建的，conda 套件把絕對路徑寫死在
   設定檔裡，搬家後全指向不存在的位置。已修復 396 個文字設定檔。

**編譯方式**（`pixi run configure-release` 直接跑會失敗）：

```powershell
# 兩步都要在 MSVC 環境下，並限制並行數避免機器卡死
cmd /c "call \"...\vcvars64.bat\" && pixi run configure-release"
$env:CMAKE_BUILD_PARALLEL_LEVEL = 10
cmd /c "call \"...\vcvars64.bat\" && pixi run build-release && pixi run install-release"
```

首次成功的結果：7047 個目標、0 錯誤，約 60 分鐘（10 核）。
產物版本 `1.2.0 build 47080 (Git)`，來源標記為 `RX5950XT/FreeCAD main`。

注意 `pixi run freecad-release` 仍會失敗（depends-on `install-release` 會重跑安裝），
要啟動直接跑 `.pixi/envs/default/Library/bin/FreeCAD.exe` 並補
`QT_QPA_PLATFORM_PLUGIN_PATH`。

### 翻譯與樣式怎麼驗證有生效

核心 GUI 翻譯（`src/Gui/Language/FreeCAD_zh-TW.ts`）是透過 Qt resource（`.qrc`）
**嵌入二進位**的，安裝目錄裡看不到 `FreeCAD_zh-TW.qm` —— 那是正常的，不是漏裝。
模組翻譯（`src/Mod/*/Gui/Resources/translations/`）才是外部 `.qm`。
要驗證只能實際啟動 GUI 看介面語言。

### 出廠預設值（2026-09-04 修正）

在**沒有舊 `user.cfg` 的乾淨機器**上安裝，介面會跟原版一模一樣 —— 翻譯與 QSS
都有正確打包，只是沒被啟用：

- 語言：`QLocale::languageToString()` 給的是 `"Chinese"`，翻譯表的鍵是
  `"Chinese (Traditional)"`，對不上就退回英文。
- 樣式：`StyleSheet` 參數預設空字串，`FreeCAD.qss` 根本不載入。

已在 `src/Gui/Application.cpp`（語言預設繁中）與 `src/Gui/StartupProcess.cpp`
（`StyleSheet` 為空時 `prefPackManager->apply("FreeCAD Dark")`）修好。

驗證方式（不動到自己的設定）：

```powershell
FreeCAD.exe --user-cfg <空目錄>\user.cfg --system-cfg <空目錄>\system.cfg
# 產生的 user.cfg 應含 StyleSheet=FreeCAD.qss 與 Theme=FreeCAD Dark
```

注意語言不會寫進 `user.cfg`（`GetASCII` 帶預設值不落地），只能看介面。
`branding.xml` 幫不上忙 —— 白名單只有 `StyleSheet`，管不到語言與 Theme pack。

### 安裝檔必須自己帶 AgentCAD addon

極簡 AI 介面（簡化工具列、右側量測面板、狀態列「AI 已就緒 · port 9875」）
**不在這個 repo 裡** —— 它是 `../AgentCAD_MCP` 這個獨立 repo 的 addon，
開發機用 junction 掛在 `%APPDATA%/FreeCAD/v1-2/Mod/Agent`。
所以本機怎麼跑都正常，安裝到別台電腦卻只剩原版 FreeCAD 介面。

`tools/build_windows_bundle.ps1` 現在會把它複製進 `Mod/Agent`，
找不到就讓打包失敗。發安裝檔前先確認 AgentCAD_MCP 已 push 且是最新的。

MCP server 仍要在每台電腦各自註冊（介面本身不需要）：

```powershell
claude mcp add agentcad -s user -- uv run --script "<安裝目錄>\Mod\Agent\mcp\server.py"
```

### 端到端驗證安裝檔（別再只測 bundle 目錄）

```powershell
installer.exe /S /CurrentUser              # 裝到 %LOCALAPPDATA%\Programs\FreeCAD-TW 1.2
$env:FREECAD_USER_HOME = "<空目錄>"        # 隔離掉本機的 addon 與設定
& "<安裝目錄>/bin/FreeCAD.exe"
```

`FREECAD_USER_HOME` 是關鍵：只用 `--user-cfg` 仍會載入 `%APPDATA%` 底下的 addon，
測不出「乾淨機器」的真實情況。

### 發布 release 一定要標 latest

fork 從上游帶來一個 `1.2.0dev` release（2026-05-13），裡面是**原版 FreeCAD 安裝檔**。
我們的版本若標成 pre-release，GitHub 的 Latest 就會停在那個原版上 ——
從 repo 首頁或 `/releases/latest` 下載到的會是原版，症狀是「裝了跟沒改一樣」。

```powershell
gh release edit <tag> -R RX5950XT/FreeCAD --prerelease=false --latest
gh api repos/RX5950XT/FreeCAD/releases/latest -q '.tag_name'   # 驗證
```

## 上游同步工作流程（已驗證可用）

```bash
git fetch upstream --no-tags
git merge upstream/main --no-edit
# 衝突一律是 *_zh-TW.ts（上游 Crowdin vs 我方 OpenCC）→ 全部保留我方版本：
git diff --name-only --diff-filter=U | while read -r f; do git checkout --ours -- "$f" && git add -- "$f"; done
git commit --no-edit
```

**衝突解決原則**：`*_zh-TW.ts` 衝突一律 `--ours`（保留我方 OpenCC s2twp 翻譯，捨棄上游 Crowdin zh-TW）。程式碼/樣式/NSIS 等通常無衝突，可自動併入。

## 最近一次上游同步（2026-05-31）

- 基底 `feddd13733` → 上游 `7266f08f79`，併入 **348 個上游提交**
- 合併提交 `2d4c0fdeb5`（雙親：`bb3737205d` 我方 + `7266f08f79` 上游）
- 20 個翻譯檔衝突全部保留我方版本，子模組指標未變動（無需重跑 init-submodules）
- 備份分支：`backup/pre-upstream-merge-20260531`
- **尚未 push 到 origin**（等使用者確認）

## 注意事項

- Bash 工具用 bash 語法；本機預設 shell 是 PowerShell，兩者引號/here-string 不同（commit 訊息勿用 `@'...'@`）。
- **Bash heredoc 會吃掉一層反斜線**：在 heredoc 裡寫 Python 字串時，`\\v` 會變成垂直定位字元。
  含反斜線的內容改用 Write／Edit 工具。
- 上游也維護自己的 zh-TW（Crowdin），與我方競爭同檔 → 合併時務必取我方。
- 新功能帶來的新字串目前仍是英文；要補譯需重跑 lupdate + `translate_tw_from_cn.py` 從更新後的 zh-CN 轉換。

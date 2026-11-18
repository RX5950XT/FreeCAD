# FreeCAD 繁體中文現代化分支 todo
最後更新：2026-11-19

建置、翻譯流程、樣式系統與疑難排解見 `CLAUDE.md`／`AGENTS.md`；本檔只放交接重點。

## 現況（交接）
- 定位：FreeCAD fork，只負責介面繁體中文化（臺灣用語）與 QSS 樣式現代化。
- Remote：`origin` = RX5950XT/FreeCAD（推送目標）；`upstream` = FreeCAD/FreeCAD，push 已停用（位址設為 `DISABLE_PUSH_TO_UPSTREAM`），只抓不推。
- 我方自訂變更（務必保留）：
  1. zh-CN 經 OpenCC `s2twp` 補齊 20+ 個 `*_zh-TW.ts`（`tools/translate_tw_from_cn.py`）。
  2. 現代化 UI 樣式：`FreeCAD.qss`、`parameters/*.yaml`。
  3. Windows NSIS 安裝檔：`package/WindowsInstaller/`、`tools/build_windows_bundle.ps1`。
  4. 出廠預設：`src/Gui/Application.cpp` 預設繁中；`src/Gui/StartupProcess.cpp` 在 `StyleSheet` 為空時套用 `FreeCAD Dark`。
- AgentCAD 已於 2026-09-03 拆成獨立 repo（`../AgentCAD`），本分支零依賴、相關檔案與 `BUILD_AGENT` CMake 已移除。舊 `FreeCADMCP` addon 已刪（與 AgentCAD 搶 port 9875）。
- 2026-09-03 首次完整編譯成功（7047 目標、0 錯誤、約 60 分鐘 / 10 核）。最新 release `tw-20260904-0408`（已標 latest）。
- 最近一次上游同步：2026-05-31 併入 348 個上游提交（合併提交 `2d4c0fdeb5`），已在 `origin/main`。

## 關鍵決策與踩雷
- **上游同步**：`git fetch upstream --no-tags` → `git merge upstream/main --no-edit`；衝突幾乎都是 `*_zh-TW.ts`（上游 Crowdin vs 我方 OpenCC），一律 `git checkout --ours` 後再 commit。程式／樣式／NSIS 通常可自動併入。
- **編譯**：`pixi run configure-release` 直接跑必失敗，configure 與 build 都要先 `vcvars64.bat`，並設 `CMAKE_BUILD_PARALLEL_LEVEL=10`。`.pixi` 搬家後絕對路徑會失效（曾修 396 個設定檔）。
- **啟動**：`pixi run freecad-release` 會重跑 install 而失敗；直接跑 `.pixi/envs/default/Library/bin/FreeCAD.exe` 並補 `QT_QPA_PLATFORM_PLUGIN_PATH`。
- **翻譯驗證**：核心 GUI 翻譯經 `.qrc` 嵌入二進位，安裝目錄看不到 `FreeCAD_zh-TW.qm` 是正常的；模組翻譯才是外部 `.qm`。只能實際啟動 GUI 看。
- **出廠預設**：舊問題是 `QLocale::languageToString()` 回 `"Chinese"` 對不上 `"Chinese (Traditional)"`、`StyleSheet` 預設空字串；已修。語言不會寫進 `user.cfg`；`branding.xml` 白名單只有 `StyleSheet`，管不到語言與 Theme pack。
- **乾淨環境驗證**：`FreeCAD.exe --user-cfg <空目錄>\user.cfg --system-cfg <空目錄>\system.cfg`，產生的 `user.cfg` 應含 `StyleSheet=FreeCAD.qss`、`Theme=FreeCAD Dark`。
- **安裝檔要自帶 AgentCAD addon**：極簡 AI 介面在 `../AgentCAD_MCP`，開發機用 junction 掛在 `%APPDATA%/FreeCAD/v1-2/Mod/Agent`。`build_windows_bundle.ps1` 會複製進 `Mod/Agent`，找不到就失敗；發安裝檔前先確認 AgentCAD_MCP 已 push 且最新。MCP server 每台電腦各自註冊：`claude mcp add agentcad -s user -- uv run --script "<安裝目錄>\Mod\Agent\mcp\server.py"`。
- **端到端驗證安裝檔**：`installer.exe /S /CurrentUser` 後設 `FREECAD_USER_HOME=<空目錄>` 再啟動；只用 `--user-cfg` 仍會載入 `%APPDATA%` 的 addon，測不出乾淨機器。
- **Release 一定要標 latest**：上游帶來的 `1.2.0dev` release 是原版安裝檔；我方若標 pre-release，`/releases/latest` 會停在原版。用 `gh release edit <tag> -R RX5950XT/FreeCAD --prerelease=false --latest`，再 `gh api repos/RX5950XT/FreeCAD/releases/latest -q '.tag_name'` 驗證。
- 停用 addon 只改資料夾名稱沒用，必須整個移出 `Mod/`。
- Bash heredoc 會吃掉一層反斜線，含反斜線的內容改用 Write／Edit 工具；commit 訊息勿用 PowerShell `@'...'@`。

## 待辦
- [ ] 上游新功能帶來的新字串仍是英文：需重跑 lupdate＋`translate_tw_from_cn.py` 從更新後的 zh-CN 轉換。

## 已知問題／刻意不處理
- `AGENTS.md`／`CLAUDE.md` 仍把 `pixi run freecad-release` 列為推薦啟動方式，與上述踩雷不一致（未改）。

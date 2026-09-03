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

### 尚未完整編譯

本機**從未成功完整編譯過**這個分支。`.pixi/envs/default/Library/` 裡的 FreeCAD
是 conda 裝的上游版本，不是自編的 —— 也就是說繁體中文翻譯與 QSS 改造目前都還沒實際生效過。

`build/release/` 已在 2026-09-03 清空（原本只是一個 configure 失敗的空殼）。
要出安裝檔（或讓翻譯／樣式生效）前，必須在 MSVC 環境下完整跑一次
`configure → build → install`。在那之前 `pixi run freecad-release` 會失敗
（它 depends-on `install-release`），要啟動請直接跑
`.pixi/envs/default/Library/bin/FreeCAD.exe` 並補 `QT_QPA_PLATFORM_PLUGIN_PATH`。

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

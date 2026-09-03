# FreeCAD 繁體中文現代化專案

本專案是 FreeCAD 原始碼的分支，目標是將介面全面翻譯為繁體中文（臺灣用語）並進行現代化 UI 改造。

## 專案概述

- **原始專案**: [FreeCAD](https://github.com/FreeCAD/FreeCAD)
- **目標**: 繁體中文在地化 + 現代化介面樣式
- **語言**: C++、Python、Qt/QML、CMake
- **建置系統**: pixi (conda 環境管理) + CMake + Ninja

## 快速開始

### 環境需求

- Windows 10/11
- [pixi](https://pixi.sh/)
- Git

### 初始化

```powershell
cd <project-root>
pixi install
pixi run init-submodules
```

### 建置

```powershell
pixi run configure-release
pixi run build-release
pixi run install-release
```

### 啟動

```powershell
# 推薦方式（自動設定環境變數）
pixi run freecad-release

# 或直接執行安裝版
.\.pixi\envs\default\Library\bin\FreeCAD.exe
```

### 重新編譯（增量）

```powershell
pixi run build-release && pixi run install-release
```

### Windows 安裝檔

- 正式交付格式使用 NSIS installer，不使用壓縮檔
- 打包腳本：`tools/build_windows_bundle.ps1`
- 產物：`FreeCAD_<version>-Windows-x86_64-installer.exe`
- `FreeCAD_Windows/` 與 installer checksum 檔皆不提交版控

## 專案結構

```
.
├── src/                          # 原始碼
│   ├── Gui/                      # GUI 核心
│   │   ├── Stylesheets/          # QSS 樣式表
│   │   │   ├── FreeCAD.qss       # 主樣式表
│   │   │   └── parameters/       # 主題參數 YAML
│   │   │       ├── FreeCAD Dark.yaml
│   │   │       └── FreeCAD Light.yaml
│   │   └── Language/             # 翻譯檔案
│   │       └── FreeCAD_zh-TW.ts  # 核心 GUI 繁體中文翻譯
│   └── Mod/                      # 各工作模組
│       ├── Assembly/
│       ├── Part/
│       ├── PartDesign/
│       └── ...
├── tools/                        # 自製工具腳本
│   └── translate_tw_from_cn.py   # 批次翻譯腳本（OpenCC s2twp）
├── build/                        # CMake 編譯產出（被 .gitignore 排除）
├── .pixi/                        # pixi 虛擬環境（被 .gitignore 排除）
│   └── envs/default/Library/     # cmake --install 輸出目錄
├── pixi.toml                     # pixi 專案設定
├── CMakePresets.json             # CMake presets
└── .gitignore
```

## 翻譯工作流程

### 批次填補 unfinished 翻譯

使用 `tools/translate_tw_from_cn.py` 從 `zh-CN` 自動轉換為 `zh-TW`（OpenCC s2twp 臺灣慣用語模式）：

```powershell
python tools/translate_tw_from_cn.py src/Mod/<Module>/Gui/Resources/translations/<Module>_zh-CN.ts src/Mod/<Module>/Gui/Resources/translations/<Module>_zh-TW.ts
```

此腳本會：
1. 解析兩個 `.ts` 檔案
2. 對於 `zh-TW` 中標記為 `unfinished` 的條目，查找對應的 `zh-CN` 翻譯
3. 使用 OpenCC `s2twp` 模式轉換為臺灣慣用語
4. 保留既有正確的繁體中文翻譯，不覆蓋

### 手動補齊

少量條目（如 Assembly 模組的 2 個條目）建議手動翻譯，以確保專業術語正確。

### 編譯翻譯檔案

翻譯檔案必須透過從原始碼建置才能嵌入 `.qm` 到二進位中。修改 `.ts` 後：

```powershell
pixi run build-release && pixi run install-release
```

或手動使用 lrelease（若本機已有 Qt 工具）：

```powershell
lrelease src/Gui/Language/FreeCAD_zh-TW.ts
```

## 樣式/主題系統

### 檔案位置

- **主樣式表**: `src/Gui/Stylesheets/FreeCAD.qss`
- **深色主題參數**: `src/Gui/Stylesheets/parameters/FreeCAD Dark.yaml`
- **淺色主題參數**: `src/Gui/Stylesheets/parameters/FreeCAD Light.yaml`
- **使用者樣式目錄**: `%APPDATA%\FreeCAD\Gui\Stylesheets\`

### 已新增的樣式 Token

| Token | 說明 | 範例值 |
|-------|------|--------|
| `MenuBorderRadius` | 選單圓角 | `6px` |
| `ScrollbarWidth` | 捲軸寬度 | `12px` |
| `ScrollbarBorderRadius` | 捲軸圓角 | `6px` |
| `TooltipBorderRadius` | 提示框圓角 | `6px` |
| `InputFieldBorderRadius` | 輸入框圓角 | `5px`（原為 `3px`）|

### 修改後的 QSS 特性

- 選單圓角（`border-radius: @MenuBorderRadius@`）
- 捲軸圓角（`border-radius: @ScrollbarBorderRadius@`）
- 提示框內距增加
- 分隔線顏色調整

### 測試樣式變更

**正式變更**（需重新編譯）：

1. 修改 `src/Gui/Stylesheets/FreeCAD.qss` 或 YAML 參數檔案
2. 重新編譯：`pixi run build-release && pixi run install-release`
3. 啟動 FreeCAD 驗證樣式

**快速測試**（不編譯，複製到使用者目錄）：

```powershell
Copy-Item src/Gui/Stylesheets/FreeCAD.qss "$env:APPDATA\FreeCAD\Gui\Stylesheets\"
Copy-Item src/Gui/Stylesheets/parameters/FreeCAD Dark.yaml "$env:APPDATA\FreeCAD\Gui\Stylesheets\parameters\"
Copy-Item src/Gui/Stylesheets/parameters/FreeCAD Light.yaml "$env:APPDATA\FreeCAD\Gui\Stylesheets\parameters\"
```

## 常見指令

| 指令 | 說明 |
|------|------|
| `pixi run configure-release` | CMake configure（首次建置或 CMakeLists.txt 變更後）|
| `pixi run build-release` | 編譯（增量）|
| `pixi run install-release` | 安裝到 `.pixi/envs/default/Library/` |
| `pixi run freecad-release` | 啟動 FreeCAD（推薦）|
| `pixi run build-release && pixi run install-release` | 完整重新編譯並安裝 |

## AgentCAD 已獨立成 addon

把 FreeCAD 變成 AI agent 建模引擎的那部分（原 `src/Mod/Agent/` 與
`tools/agentcad-mcp/`）已在 2026-09-03 拆成獨立 repo：`../AgentCAD`。

它對這個分支沒有任何依賴 —— import 全部是標準 API（`FreeCAD`、`FreeCADGui`、
`PySide`、`Part`、`Mesh`），原版 FreeCAD 1.2 就能跑。原本掛進編譯的 6 行 CMake
（`BUILD_AGENT` 及 `src/Mod/CMakeLists.txt` 的 `add_subdirectory`）也已撤除。

開發規範、慣例與踩過的坑都跟著搬到那個 repo 的 `CLAUDE.md` / `tasks/lessons.md`，
這裡不再維護。本分支只負責繁體中文化與 QSS 樣式改造。

**舊的 `FreeCADMCP` addon 已全部刪除**（`%APPDATA%/FreeCAD/v1-2/Mod_disabled/` 與
`%APPDATA%/FreeCAD/Mod/`，兩份都刪了）—— 它和 AgentCAD 搶同一個 port 9875。
要裝回去請重抓上游版本。
（順帶一提：停用 addon 只改資料夾名字沒有用，FreeCAD 照載，必須整個移出 `Mod/`。）

## 注意事項

1. **不要直接修改 `build/` 或 `.pixi/` 內的檔案** — 這些目錄被 `.gitignore` 排除，且會在重新編譯時被覆蓋。
2. **翻譯修改後必須重新建置** — `.ts` 檔案需要編譯為 `.qm` 才能嵌入執行檔。
3. **樣式測試有兩種方式** — 快速測試可複製到 `%APPDATA%\FreeCAD\`，正式變更需修改 `src/Gui/Stylesheets/` 並重新編譯。
   **測完務必刪掉使用者目錄的複本**，同名檔案會蓋過原始碼版本。
4. **直接雙擊 `FreeCAD.exe` 可能缺 DLL** — 必須先將 `python311.dll` 等從 `.pixi/envs/default/` 複製到 `Library/bin/`，或始終使用 `pixi run freecad-release` 啟動。
5. **使用 OpenCC `s2twp` 而非 `s2tw`** — 以正確處理臺灣用語（如「文件→檔案」、「屏幕→螢幕」、「窗口→視窗」、「鼠標→滑鼠」、「文件夾→資料夾」）。

## 疑難排解

### 找不到 python311.dll

**原因**: 直接雙擊執行，未透過 pixi 環境啟動。

**解決**: 
- 使用 `pixi run freecad-release` 啟動
- 或將 `.pixi/envs/default/python311.dll` 複製到 `.pixi/envs/default/Library/bin/`

### configure 失敗：Could not find compiler set in environment variable CC: cl.exe

pixi 環境把 `CC` 設成 `cl.exe`，但 `cl.exe` 只有跑過 `vcvars64.bat` 才會進 PATH。
`pixi run configure-release` 直接跑一定失敗，必須先進 MSVC 環境：

```powershell
cmd /c "call \"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat\" && pixi run configure-release"
```

寫成 `.bat` 執行更方便，但**批次檔內不要出現中文** —— cmd 用 cp950 讀檔，
UTF-8 的中文註解會變成亂碼並被當成指令執行（症狀是一堆
「不是內部或外部命令」加上 `pixi: unrecognized subcommand`）。

### configure / build 失敗：路徑指向 D:/Workspace_cloud/...

本專案曾從 `D:\Workspace_cloud\` 搬到 `D:\Workspace\`，而 `.pixi` 環境是搬家前建的 ——
conda 套件把**絕對路徑寫死**在設定檔裡，搬家後全部指向不存在的位置。
這是這個分支長期無法完整編譯的真正原因。

2026-09-03 已修復 396 個文字設定檔（`.pc` 375、`.cmake` 5+17、`.py`、`.sh`、`.pri` 等）：

```bash
find .pixi/envs/default -type f \( -name '*.cmake' -o -name '*.pc' -o -name '*.py' \
  -o -name '*.sh' -o -name '*.csh' -o -name '*.fish' -o -name '*.settings' \
  -o -name '*.pri' -o -name '*.prl' -o -name '*.cfg' -o -name '*.json' \) \
  -exec grep -l "Workspace_cloud" {} + \
  | xargs sed -i 's|D:/Workspace_cloud/Personal_Project/FreeCAD|D:/Workspace/Personal_Project/FreeCAD|g'
```

**cmake config 散在三個地方**，只修一處會在 build 階段才爆（`ninja: error: 'z.lib' missing`）：
`Library/lib/cmake/`、`Library/cmake/`、`Library/WebP/cmake/`。

還剩 35 個 `.pyd` 與 6 個 `.lib` 二進位內含舊路徑，那些是編譯期記錄的 debug 資訊，
連結時走的是 cmake config 給的路徑，不影響建置。真要徹底乾淨就重建環境
（`.pixi` 有 9.9 GB，且本機 rattler 快取只剩 137 MB，等於整包重新下載）。

**教訓**：搬動這個專案的資料夾之後，`.pixi` 必須重建，不能直接搬。

### 編譯太慢或把機器卡死

`cmake --build` 預設用光所有核心。限制並行數：

```powershell
$env:CMAKE_BUILD_PARALLEL_LEVEL = 10   # 16 核的機器留 6 核給自己用
pixi run build-release
```

### 翻譯未生效

確認已重新編譯並安裝：

```powershell
pixi run build-release && pixi run install-release
```

## 相關連結

- [FreeCAD 官方文件](https://wiki.freecad.org/)
- [FreeCAD GitHub](https://github.com/FreeCAD/FreeCAD)
- [OpenCC 文件](https://github.com/BYVoid/OpenCC)
- [pixi 文件](https://pixi.sh/)

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

## 注意事項

1. **不要直接修改 `build/` 或 `.pixi/` 內的檔案** — 這些目錄被 `.gitignore` 排除，且會在重新編譯時被覆蓋。
2. **翻譯修改後必須重新建置** — `.ts` 檔案需要編譯為 `.qm` 才能嵌入執行檔。
3. **樣式測試有兩種方式** — 快速測試可複製到 `%APPDATA%\FreeCAD\`，正式變更需修改 `src/Gui/Stylesheets/` 並重新編譯。
4. **直接雙擊 `FreeCAD.exe` 可能缺 DLL** — 必須先將 `python311.dll` 等從 `.pixi/envs/default/` 複製到 `Library/bin/`，或始終使用 `pixi run freecad-release` 啟動。
5. **使用 OpenCC `s2twp` 而非 `s2tw`** — 以正確處理臺灣用語（如「文件→檔案」、「屏幕→螢幕」、「窗口→視窗」、「鼠標→滑鼠」、「文件夾→資料夾」）。

## 疑難排解

### 找不到 python311.dll

**原因**: 直接雙擊執行，未透過 pixi 環境啟動。

**解決**: 
- 使用 `pixi run freecad-release` 啟動
- 或將 `.pixi/envs/default/python311.dll` 複製到 `.pixi/envs/default/Library/bin/`

### 編譯失敗

```powershell
pixi run configure-release  # 重新 configure
pixi run build-release      # 再試一次
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

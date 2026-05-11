# AGENTS.md — FreeCAD 繁體中文現代化專案

本檔案定義本專案中 AI Agent 的行為準則、工作流程與品質標準。

## 語言與溝通

- 所有回覆使用**繁體中文（臺灣用語）**，禁止使用韓文、日文
- 用語精簡能省則省，只需告知結果
- 技術術語可保留英文原文

## Agent 使用原則

**主動使用 Agent（不需使用者提示）：**

1. 複雜功能 → 先啟動 **planner**
2. 寫完/修改程式碼 → 自動執行 **code-reviewer**
3. 新功能或 bug 修復 → 使用 **tdd-guide**
4. 架構決策 → 使用 **architect**
5. 資料庫相關 → 使用 **database-reviewer**
6. 效能問題 → 使用 **performance-engineer**
7. 新增 UI 元件 → 使用 **ui-reviewer**
8. 新增/更新依賴 → 使用 **dependency-manager**
9. CI/CD 或部署故障 → 使用 **devops-troubleshooter**
10. API 設計變更 → 使用 **api-reviewer**

**平行執行：** 獨立任務一律同時啟動多個 Agent。

**Agent 決策樹：**

```
新功能或複雜重構？
├── 是 → planner（建立實作計畫）
│   └── 計畫核准後 → tdd-guide
│       └── 編碼完成後 → code-reviewer
│           └── 涉及安全？ → security-reviewer
└── 否：架構決策？
    ├── 是 → architect
    └── 否：剛寫完／修改程式碼？
        ├── 是 → code-reviewer（自動）
        └── 否：建置失敗？
            ├── 是 → auto-build-fix
            └── 否：需要 E2E 測試？
                ├── 是 → e2e-runner
                └── 否：需要更新文件？
                    ├── 是 → doc-updater
                    └── 否：安全稽核？
                        └── 是 → security-reviewer
```

**多視角分析：** 複雜問題使用分角色子代理：
- 事實審查者
- 資深工程師
- 安全專家
- 一致性審查者
- 冗餘檢查者

## 程式碼品質標準

- 不可變資料優先：永遠建立新物件，不直接修改現有物件
- 函數 < 50 行，檔案 < 800 行
- 不超過 4 層巢狀
- 每一層都要處理錯誤，禁止靜默吞掉例外
- 在系統邊界驗證所有輸入（使用者輸入、API 回應、檔案內容）

## Git 工作流程

提交格式：`<type>: <description>`
Types: feat, fix, refactor, docs, test, chore, perf, ci

### Rebase vs Merge

使用 **rebase**：
- 讓功能分支保持與 main 同步（更乾淨的歷史）
- 準備功能分支的 PR（線性歷史）

使用 **merge**：
- 將已核准的 PR 整合進 main
- 保留分支協作脈絡

### Squash Commits

在以下情況 squash：
- 功能分支有太多「進行中」的提交
- 提交在邏輯上屬於單一變更
- 想要乾淨、原子的提交歷史

不要 squash：
- 每個提交代表一個可審查的獨立步驟
- 需要保留 bisect 能力
- 協作者可能已基於你的分支工作

## 設計模式

### Repository Pattern

封裝資料存取層，提供一致介面：
- 定義標準操作：findAll、findById、create、update、delete
- 具體實作處理儲存細節（資料庫、API、檔案等）
- 業務邏輯依賴抽象介面，而非儲存機制
- 便於測試時使用 mock

### Strategy Pattern

封裝可互換的演算法：
- 定義共同介面
- 具體策略實作介面
- 上下文類別委派給策略實例
- 允許執行期演算法選擇

### Error Boundary Pattern

隔離失敗以防止連鎖錯誤：
- 在模組邊界使用 try/catch 包裝高風險操作
- 回傳結構化錯誤（不拋出未處理的例外穿越邊界）
- 在邊界記錄詳細上下文
- 在最外層呈現使用者友善訊息

### API Response Format

所有 API 回應使用一致的封包格式：
- 包含 success/status 指示器
- 包含 data payload（錯誤時可為 null）
- 包含 error message 欄位（成功時可為 null）
- 分頁回應包含 metadata（total、page、limit）

## 安全規範

### 提交前強制檢查清單

- [ ] 無硬編碼機密（API keys、密碼、tokens）
- [ ] 所有使用者輸入已驗證
- [ ] SQL 注入防護（參數化查詢）
- [ ] XSS 防護（消毒 HTML）
- [ ] CSRF 防護已啟用
- [ ] 認證／授權已驗證
- [ ] 所有端點已設定速率限制
- [ ] 錯誤訊息不洩漏敏感資料

### 機密管理

- 絕不在原始碼中硬編碼機密
- 一律使用環境變數或機密管理器
- 啟動時驗證必要機密是否存在
- 輪換任何可能已暴露的機密

### 供應鏈安全

新增依賴前：
- [ ] 檢查已知漏洞（`npm audit`、`pip-audit`、`govulncheck`）
- [ ] 優先選擇維護良好的套件
- [ ] 在 lock 檔案中鎖定精確版本
- [ ] 審查套件權限（npm：檢查 install scripts）

## CLI 工具優先原則

**優先使用 CLI，而非 MCP 或瀏覽器自動化。** CLI 更穩定、可腳本化、輸出可預測。

### 工具不存在時的處理方式

若執行指令時找不到工具，**必須自行安裝後繼續**，不可中止任務：

```
# 優先安裝順序
1. uv tool install <tool>        # Python CLI 工具首選
2. npm install -g <tool>         # Node.js CLI 工具
3. winget install <tool>         # 系統層級工具
4. 直接下載 binary 至 ~/.local/bin/
```

安裝後驗證：執行 `<tool> --version` 確認可用。

## 本專案特定規範

### 建置與開發

- 使用 `pixi` 管理依賴與建置（`pixi.toml` + `CMakePresets.json`）
- 編譯 preset：`conda-windows-release`
- 啟動指令：`pixi run freecad-release`
- 重新編譯：`pixi run build-release && pixi run install-release`
- 直接雙擊 `FreeCAD.exe` 前需確保 `python311.dll` 等已複製到 `Library/bin/`

### 翻譯規範

- 使用 OpenCC `s2twp`（臺灣慣用語）模式轉換簡體中文翻譯
- 從 `zh-CN` 翻譯補齊 `zh-TW` 的 `unfinished` 條目
- 保留既有正確的繁體中文翻譯，不覆蓋
- 批次翻譯腳本：`tools/translate_tw_from_cn.py`
- 翻譯修改後必須重新編譯（`.ts` → `.qm` 嵌入二進位）

### 樣式規範

- 樣式檔案位置：`src/Gui/Stylesheets/`
- 主題參數檔案：`src/Gui/Stylesheets/parameters/`
- 新增 token 需在 `FreeCAD Dark.yaml` 與 `FreeCAD Light.yaml` 同步更新
- QSS 檔案使用 `@TokenName@` 語法引用 YAML 參數
- 快速測試可複製到 `%APPDATA%\FreeCAD\Gui\Stylesheets\`
- 正式變更需修改 `src/` 並重新編譯

### 臺灣用語對照表（OpenCC s2twp）

| 簡體/大陸用語 | 臺灣用語 |
|-------------|---------|
| 文件 | 檔案 |
| 屏幕 | 螢幕 |
| 窗口 | 視窗 |
| 鼠標 | 滑鼠 |
| 文件夾 | 資料夾 |
| 軟件 | 軟體 |
| 硬件 | 硬體 |
| 程序 | 程式 |
| 菜單 | 選單 |
| 滾動 | 捲動 |
| 組件 | 元件 |
| 信息 | 資訊 |
| 網絡 | 網路 |
| 服務器 | 伺服器 |
| 驅動 | 驅動程式 |
| 安裝 | 安裝 |
| 卸載 | 移除 |
| 幫助 | 說明 |

### 結果驗證要求

**每個任務完成後必須自行驗證結果符合需求**，不可僅回報「已完成」：

- 執行 CLI 指令確認預期輸出
- 讀取修改後的檔案確認內容正確
- 啟動 FreeCAD 確認翻譯/樣式生效
- 若驗證失敗，自動修正後再次驗證，直到通過為止

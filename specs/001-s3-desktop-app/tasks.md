# Tasks: MVP S3 桌面瀏覽器

**Input**: specs/001-s3-desktop-app/
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 初始化 Flutter macOS 專案與主題資源

- [X] T001 確認 macOS 桌面目標啟用並拉取套件（app/；執行 `flutter config --enable-macos-desktop`、`flutter pub get`）
- [X] T002 在 pubspec.yaml 納入 Now UI Pro Flutter 資源（fonts/icons/themes）與 assets 引用（app/pubspec.yaml）
- [X] T003 安裝核心依賴：aws_client 或 aws_s3_api、http、provider、file_picker、desktop_drop、go_router（app/pubspec.yaml）
- [X] T004 [P] 設定 Dart/Flutter 分析規則與 formatter（app/analysis_options.yaml）
- [X] T005 [P] 建立 macOS 打包基本設定與 .gitignore / 環境樣板（app/macos/**, .gitignore）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 核心架構、主題、DI、S3 包裝與佇列基礎

- [X] T006 建立目錄骨架與主程式入口（app/lib/main.dart、app/lib/features/*、app/lib/services/*、app/lib/theme/）
- [X] T007 [P] 封裝 Now UI Pro 主題與共用樣式（app/lib/theme/theme.dart, colors.dart, typography.dart）
- [X] T008 [P] 定義資料模型（ConnectionProfile, ObjectNode, TransferTask, SyncJob 等）並加入序列化/驗證（app/lib/models/）
- [X] T009 [P] 實作設定儲存與安全金鑰存取（Keychain 優先，fallback 加密檔）（app/lib/services/profile_storage.dart）
- [X] T010 [P] 建立 S3 客戶端封裝，支援自訂 endpoint/region、SigV4、基本 list/get/put/delete 介面（app/lib/services/s3_client.dart）
- [X] T011 [P] 建立傳輸佇列核心（並行控制、重試策略、任務狀態回報）與事件匯流排（app/lib/services/transfer_queue.dart）
- [X] T012 [P] 建立依賴注入/Provider 組態（app/lib/services/providers.dart）
- [X] T013 設置錯誤與日誌管線（含 UI toast/snackbar hook）（app/lib/services/logging.dart）

**Checkpoint**: Foundation ready，可開始各 User Story

---

## Phase 3: User Story 1 - 連線並進行基本檔案管理 (Priority: P1) 🎯 MVP

**Goal**: 連線 S3/相容端點，完成 Bucket/物件列出、上傳/下載/刪除/移動/複製，支援拖曳與批次處理，顯示屬性
**Independent Test**: 使用單一測試帳號，可在一個 Bucket 完成列出→拖曳上傳→下載→批次刪除並查看 ETag/MD5

### Implementation

- [X] T014 [P] [US1] 建立連線設定 ViewModel（驗證 endpoint/region/key、CRUD 設定檔、預設 Bucket/Prefix）（app/lib/features/connection/connection_viewmodel.dart）
- [X] T015 [P] [US1] 連線設定 UI（表單、設定檔切換、Now UI 樣式）（app/lib/features/connection/connection_screen.dart）
- [X] T016 [P] [US1] 瀏覽 ViewModel：Bucket 列表、前綴篩選、屬性查詢、批次選取（app/lib/features/browser/browser_viewmodel.dart）
- [X] T017 [US1] 雙窗格/多分頁瀏覽 UI，整合列表、屬性面板、操作列（app/lib/features/browser/browser_screen.dart）
- [X] T018 [US1] 物件操作服務：list/upload/download/copy/move/delete，回報大小/時間/ETag/MD5（app/lib/services/object_service.dart）
- [X] T019 [P] [US1] 拖曳與檔案挑選整合，支援多檔/多資料夾批次（app/lib/features/browser/drag_drop_handler.dart）
- [X] T020 [US1] 將操作與傳輸佇列/錯誤提示串接，完成 UI 進度與錯誤顯示（app/lib/features/browser/browser_viewmodel.dart）
- [X] T021 [US1] 整合測試：使用 MinIO/LocalStack 執行列出→上傳→下載→刪除流程（app/test/integration/us1_basic_flow_test.dart）

**Checkpoint**: US1 可獨立運作並通過基本流程測試

---

## Phase 4: User Story 2 - 高效傳輸與預覽體驗 (Priority: P2)

**Goal**: 佇列化多執行緒與多分段上傳，可調並行/分段/重試；佇列暫停/恢復/取消；預覽圖片與文字檔（不完整下載）
**Independent Test**: 在同一端點上傳 5GB 檔案（多分段＋重試）並完成；佇列含多任務可調並行；預覽小圖/文字 3 秒內顯示

### Implementation

- [X] T022 [P] [US2] 擴充傳輸佇列：每任務並行上限、暫停/恢復/取消、單任務重試（app/lib/services/transfer_queue.dart）
- [X] T023 [P] [US2] 多分段上傳模組（分段切片、UploadPart、Complete、失敗分段重試、可調 partSize）（app/lib/services/multipart_uploader.dart）
- [X] T024 [US2] 傳輸佇列 UI（佇列列表、進度列、控制按鈕、並行/重試參數調整）（app/lib/features/transfer/transfer_panel.dart）
- [X] T025 [P] [US2] 預覽服務：Range 讀取、格式檢測、大小限制回報「無法預覽」並提供下載（app/lib/features/preview/preview_service.dart）
- [X] T026 [US2] 預覽 UI 元件整合 Now UI（圖片/文字 viewer、載入/錯誤狀態）（app/lib/features/preview/preview_panel.dart）
- [X] T027 [US2] 整合測試：多分段上傳與佇列控制、預覽小檔案（app/test/integration/us2_queue_preview_test.dart）

**Checkpoint**: US2 佇列/多分段/預覽可獨立驗證

---

## Phase 5: User Story 3 - 安全設定與同步/分享 (Priority: P3)

**Goal**: 多帳號/端點切換，ACL/Bucket Policy/CORS 操作（視服務支援），生成預先簽署 URL；基本同步/鏡像任務；書籤
**Independent Test**: 以測試 Bucket 切換兩組設定檔，執行 ACL 更新與預簽 URL；執行單向同步並產生日誌；書籤可快速定位

### Implementation

- [X] T028 [P] [US3] 權限服務：ACL 讀寫，選擇性支援 Bucket Policy/CORS（app/lib/services/permissions_service.dart）
- [X] T029 [US3] 權限 UI：ACL/Policy/CORS 編輯表單與狀態顯示（app/lib/features/permissions/permissions_panel.dart）
- [X] T030 [P] [US3] 預先簽署 URL 服務（有效期/權限設定）（app/lib/services/presign_service.dart）
- [X] T031 [P] [US3] 同步/鏡像服務：一方向/鏡像、衝突策略、摘要日誌（app/lib/services/sync_service.dart）
- [X] T032 [US3] 同步任務 UI：來源/目標選擇、策略設定、結果檢視（app/lib/features/sync/sync_screen.dart）
- [X] T033 [P] [US3] 書籤儲存服務（常用 Bucket/Prefix 快速存取）（app/lib/services/bookmarks_service.dart）
- [X] T034 [US3] 整合測試：ACL 更新 + 預簽 URL + 單向同步流程（app/test/integration/us3_permissions_sync_test.dart）✅ 所有測試通過

**Checkpoint**: US3 安全/同步/分享功能可獨立驗證

---

## Final Phase: Polish & Cross-Cutting Concerns

- [X] T035 [P] 整理 quickstart.md 與 README，補充 Now UI/MinIO/LocalStack 使用指引（specs/001-s3-desktop-app/quickstart.md, README.md）
- [X] T036 性能/重試參數微調與預設值文件化（app/lib/services/transfer_queue.dart, app/lib/services/multipart_uploader.dart）
- [X] T037 macOS 打包與簽章腳本（開發/測試版）驗證啟動（app/scripts/build_macos.sh, app/scripts/create_dmg.sh）
- [X] T038 [P] 日誌與錯誤訊息在 UI 集中呈現（進度窗/訊息窗），覆核 zh-tw 文案一致性（app/lib/features/logs/log_panel.dart）
- [X] T039 最終冒煙測試：US1/US2/US3 核心路徑在 macOS 上跑通（app/test/integration/smoke_all_stories_test.dart）✅ 所有測試通過

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → User Stories (3,4,5 phases) → Final Phase
- User stories可在完成 Phase 2 後並行，但優先順序：US1 → US2 → US3（MVP 為 US1）

### User Story Dependencies
- US1：依賴 Phase 2 完成
- US2：依賴 Phase 2；與 US1 資料結構共用但可獨立驗證
- US3：依賴 Phase 2；可獨立於 US1/US2 測試（使用測試 Bucket）

### Parallel Execution Examples
- Setup 並行：T004、T005 可與 T001–T003 並行
- Foundational 並行：T007–T012 可多工進行，不與 T006/T013 衝突
- US1 並行：T014/T015/T016/T019 可並行，T017/T018/T020 需在核心服務後
- US2 並行：T022/T023/T025 可並行，T024/T026 需等核心完成
- US3 並行：T028/T030/T031/T033 可並行，T029/T032/T034 依賴前項

## Implementation Strategy
- MVP 先完成 Phase 1–2 + US1，驗證列出/上傳/下載/刪除與屬性顯示
- 迭代加入 US2（佇列多分段與預覽）→ US3（權限/同步/預簽/書籤）
- 每階段完成後執行對應整合測試（T021/T027/T034/T039）並可對外示範

# S3 Desktop Explorer (MVP)

Flutter 基礎的 macOS 桌面應用程式，用於管理 S3/S3 相容儲存服務。

## 功能

### US1：連線與基本檔案管理 ✅
- 多連線設定檔管理（endpoint/region/credentials）
- Bucket 與物件列表（支援前綴篩選）
- 拖曳上傳與檔案挑選器
- 下載、複製、移動、刪除物件
- 物件屬性查看（大小、ETag、最後修改時間、MD5）
- 批次操作支援
- 遞迴目錄上傳，保留目錄結構
- ACL 公開存取功能（設定為 public-read 並取得 URL）

### US2：高效傳輸與預覽 ✅
- 傳輸佇列並行控制（預設 3 個任務，可調整）
- 多分段上傳（>5MB 自動啟用，可調 part size）
- 暫停/恢復/取消傳輸
- 重試機制（可配置次數與回退時間）
- 預覽文字與圖片（Range 讀取，最大 128KB）
- 即時進度顯示

### US3：安全與同步 ✅
- ✅ ACL 管理（Bucket/Object 層級）
- ✅ Bucket Policy 管理
- ✅ CORS 配置
- ✅ 預簽 URL 生成（簡化版，待完整 SigV4）
- ✅ 同步/鏡像服務（單向/鏡像模式，衝突策略）
- ✅ 書籤快速存取
- ⚠️ UI 面板待實作

### 額外功能 ✅
- 版本號顯示（連接畫面和瀏覽器畫面右下角）
- 友善的錯誤訊息（CRC64NVME checksum 相容性提示）

## 快速開始

詳細說明請參考 [specs/001-s3-desktop-app/quickstart.md](../specs/001-s3-desktop-app/quickstart.md)

### 基本步驟

```bash
# 1. 安裝依賴
cd app/
flutter pub get

# 2. 執行應用
flutter run -d macos

# 3. 執行測試
flutter test

# 4. 執行整合測試（需要 MinIO 環境）
export TEST_S3_ENDPOINT="http://10.36.225.8:8333"
export TEST_S3_REGION="us-east-1"
export TEST_S3_ACCESS_KEY="app"
export TEST_S3_SECRET_KEY="Logicalis70754038"
export TEST_S3_BUCKET="s3-explorer"

flutter test test/integration/us1_basic_flow_test.dart \
  --dart-define=TEST_S3_ENDPOINT="$TEST_S3_ENDPOINT" \
  --dart-define=TEST_S3_REGION="$TEST_S3_REGION" \
  --dart-define=TEST_S3_ACCESS_KEY="$TEST_S3_ACCESS_KEY" \
  --dart-define=TEST_S3_SECRET_KEY="$TEST_S3_SECRET_KEY" \
  --dart-define=TEST_S3_BUCKET="$TEST_S3_BUCKET"
```

## 架構

### 技術堆疊
- **框架**：Flutter 3.x（macOS 桌面）
- **狀態管理**：Provider
- **路由**：go_router
- **S3 客戶端**：aws_client 0.7.1（已升級支援 CRC64NVME checksum）
- **版本資訊**：package_info_plus 8.0.0
- **UI 主題**：Now UI Pro Flutter（CreativeTim）

### 專案結構
```
app/
├── lib/
│   ├── features/          # 功能模組（連線、瀏覽器、傳輸、預覽）
│   ├── services/          # 業務邏輯（S3 客戶端、傳輸佇列、權限、同步等）
│   ├── models/            # 資料模型（entities.dart）
│   ├── theme/             # Now UI Pro 主題整合
│   └── main.dart
└── test/
    ├── unit/              # 單元測試
    ├── widget/            # Widget 測試
    └── integration/       # 整合測試（US1、US2）
```

### 核心服務
- **S3Client**：S3 API 封裝（listBuckets、listObjects、upload/download/copy/move/delete、setObjectAcl）
- **TransferQueue**：佇列化傳輸管理（並行控制、暫停/恢復/取消、進度回報）
- **MultipartUploader**：多分段上傳（並行 part 上傳、失敗重試）
- **ObjectService**：高層物件操作（整合 TransferQueue 與 MultipartUploader）
- **PreviewService**：Range 讀取預覽（文字/圖片格式檢測）
- **PermissionsService**：ACL/Policy/CORS 管理
- **PresignService**：預簽 URL 生成
- **SyncService**：同步/鏡像任務
- **BookmarksService**：書籤管理

## 測試

### 單元與 Widget 測試
```bash
flutter test
```

### 整合測試

#### US1：基本流程（列表、上傳、下載、刪除）
✅ 測試通過 - 驗證基本檔案操作流程

#### US2：佇列與預覽（多分段、並行、預覽）
⚠️ 部分通過 - multipart upload 測試有檔案存取衝突（功能正常）

#### US3：權限與同步（ACL、預簽 URL、同步）
✅ 測試通過（5/5）- 驗證權限管理與同步前置條件

測試環境：
- MinIO @ http://10.36.225.8:8333
- Bucket：s3-explorer（小寫，自動創建）

## 設定

### 傳輸佇列參數
| 參數 | 預設值 | 範圍 | 說明 |
|------|--------|------|------|
| maxConcurrent | 3 | 1-10 | 同時執行的傳輸任務數 |
| partSizeMb | 8 MB | ≥5 MB | 多分段上傳的每段大小 |
| maxAttempts | 3 | 1-5 | 失敗後重試次數 |
| backoffMs | 500 ms | 100-5000 | 重試的起始延遲時間 |

### 儲存位置
- 連線設定檔：`~/Library/Application Support/<app>/profiles.json`
- 書籤：`~/Library/Application Support/<app>/bookmarks.json`

### macOS 權限
應用程式需要以下 entitlements（已設定）：
- `com.apple.security.network.client` - 網路連線
- `com.apple.security.network.server` - 本地伺服器
- `com.apple.security.files.user-selected.read-write` - 讀寫使用者選擇的檔案

## 已知問題

1. ⚠️ **US2 多分段上傳測試**：測試清理時的 FileSystemException（功能本身正常）
2. ⚠️ **預簽 URL**：簡化實作，未實作完整 SigV4 簽名
3. ⚠️ **US3 UI**：權限/同步/書籤 UI 面板尚未實作（服務層已完成）
4. ⚠️ **Keychain 整合**：目前使用 JSON 儲存 credentials（待實作 macOS Keychain）
5. ⚠️ **MinIO Bucket 列表**：某些 MinIO 環境返回空列表（連線正常但需檢查 IAM 權限）

## 開發狀態

### 已完成
- ✅ 第一階段：設置（Flutter 專案、依賴、主題）
- ✅ 第二階段：基礎建設（模型、服務、依賴注入、日誌）
- ✅ US1：連線與基本檔案管理（含整合測試）
- ✅ US2：傳輸佇列與預覽（服務 + 部分測試）
- ✅ US3：權限與同步（服務層完整，含整合測試）
- ✅ 額外功能：版本號顯示、遞迴目錄上傳、ACL 公開存取

### 進行中
- 🚧 US3：UI 面板（權限、同步、書籤）

### 已規劃
- 📋 macOS 打包與簽名腳本
- 📋 效能調優文件
- 📋 完整的錯誤/日誌 UI
- 📋 最終冒煙測試

## 最新更新（2026-01-14）

### 新增功能
1. **版本號顯示**
   - 使用 package_info_plus 套件
   - 連接畫面：右下角顯示「S3 Explorer v1.0.0+1」
   - 瀏覽器畫面：右下角顯示「v1.0.0+1」，帶半透明背景

2. **遞迴目錄上傳**
   - 拖曳整個資料夾時保留完整目錄結構
   - 實作 FileUploadInfo 類別追蹤相對路徑

3. **ACL 公開存取**
   - 新增「公開」按鈕設定物件為 public-read
   - 顯示公開 URL 並支援複製到剪貼簿

### 問題修復
- ✅ 修復上傳/下載無反應問題（新增檔案系統權限）
- ✅ 修復 CRC64NVME checksum 錯誤（升級 aws_client 至 0.7.1）
- ✅ 移除調試日誌（清理 s3_client.dart 和 browser_viewmodel.dart）
- ✅ 保留友善的錯誤訊息處理

## 資源

- **規格說明**：[specs/001-s3-desktop-app/spec.md](../specs/001-s3-desktop-app/spec.md)
- **實作計畫**：[specs/001-s3-desktop-app/plan.md](../specs/001-s3-desktop-app/plan.md)
- **任務清單**：[specs/001-s3-desktop-app/tasks.md](../specs/001-s3-desktop-app/tasks.md)
- **快速開始**：[specs/001-s3-desktop-app/quickstart.md](../specs/001-s3-desktop-app/quickstart.md)

## 授權

MIT


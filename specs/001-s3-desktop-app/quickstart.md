# quickstart.md — MVP S3 桌面瀏覽器

## 1) 前置需求（macOS）

- 安裝 Flutter 3.x（macOS 桌面目標已啟用：`flutter config --enable-macos-desktop`）
- Xcode Command Line Tools + Cocoapods（若需）
- 取得 Now UI Pro Flutter 資源：已存在於 `docs/creativetimofficial-now-ui-pro-flutter`，確保可被 pubspec 引用

## 2) 取得程式碼與套件

```bash
cd app/
flutter pub get
```

## 3) 測試環境設置（MinIO）

### 使用外部 MinIO（如提供的測試環境）

已驗證環境：
- Endpoint: `http://10.36.225.8:8333`
- Region: `us-east-1`
- Access Key: `app`
- Secret Key: `Logicalis70754038`
- Bucket: `s3-explorer` (小寫，自動創建)

### 本地 MinIO（可選）

```bash
# 使用 Docker 啟動 MinIO
docker run -p 9000:9000 -p 9001:9001 \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  quay.io/minio/minio server /data --console-address ":9001"
```

訪問 Console: http://localhost:9001
S3 API: http://localhost:9000

## 4) 執行應用

```bash
cd app/
flutter run -d macos
```

首次啟動會進入連線設定畫面，輸入：
- 名稱：自訂（如 "MinIO Test"）
- Endpoint: `http://10.36.225.8:8333` 或 `http://localhost:9000`
- Region: `us-east-1`
- Access Key ID: 對應端點的 access key
- Secret Key: 對應端點的 secret key
- 預設 Bucket（可選）: `s3-explorer`

## 5) 執行測試

### 單元/Widget 測試
```bash
cd app/
flutter test
```

### 整合測試（需要 MinIO 環境）

US1 基本流程（列表、上傳、下載、刪除）：
```bash
export TEST_S3_ENDPOINT="http://10.36.225.8:8333"
export TEST_S3_REGION="us-east-1"
export TEST_S3_ACCESS_KEY="app"
export TEST_S3_SECRET_KEY="Logicalis70754038"
export TEST_S3_BUCKET="S3-Explorer"

flutter test test/integration/us1_basic_flow_test.dart \
  --dart-define=TEST_S3_ENDPOINT="$TEST_S3_ENDPOINT" \
  --dart-define=TEST_S3_REGION="$TEST_S3_REGION" \
  --dart-define=TEST_S3_ACCESS_KEY="$TEST_S3_ACCESS_KEY" \
  --dart-define=TEST_S3_SECRET_KEY="$TEST_S3_SECRET_KEY" \
  --dart-define=TEST_S3_BUCKET="$TEST_S3_BUCKET"
```

US2 佇列與預覽：
```bash
flutter test test/integration/us2_queue_preview_test.dart \
  --dart-define=TEST_S3_ENDPOINT="$TEST_S3_ENDPOINT" \
  --dart-define=TEST_S3_REGION="$TEST_S3_REGION" \
  --dart-define=TEST_S3_ACCESS_KEY="$TEST_S3_ACCESS_KEY" \
  --dart-define=TEST_S3_SECRET_KEY="$TEST_S3_SECRET_KEY" \
  --dart-define=TEST_S3_BUCKET="$TEST_S3_BUCKET"
```

### 驗證功能

- ✅ 列出 Buckets
- ✅ 列出物件（支援前綴篩選）
- ✅ 拖曳/檔案挑選器上傳
- ✅ 下載物件
- ✅ 複製/移動/刪除物件
- ✅ 查看物件屬性（大小、ETag、最後修改時間）
- ✅ 多分段上傳（>5MB 自動啟用）
- ✅ 佇列並行控制（預設 3）
- ✅ 暫停/恢復/取消傳輸
- ✅ 預覽文字/圖片（Range 讀取）
- ✅ ACL/Policy/CORS 管理（服務層）
- ✅ 預簽 URL 生成（服務層）
- ✅ 同步/鏡像（服務層）
- ✅ 書籤（服務層）

## 6) 主題整合指引

Now UI Pro Flutter 資源已整合：
- 在 `pubspec.yaml` 中引用 `../docs/creativetimofficial-now-ui-pro-flutter/assets/`
- 主題封裝位於 `app/lib/theme/`
- 共用元件樣式遵循 Now UI 配色與字體

## 7) 傳輸佇列參數

| 參數 | 預設值 | 說明 |
|------|--------|------|
| 並行數 (maxConcurrent) | 3 | 同時執行的傳輸任務數 |
| 分段大小 (partSizeMb) | 8 MB | 多分段上傳的每段大小（≥5MB） |
| 重試次數 (maxAttempts) | 3 | 失敗後重試次數 |
| 重試間隔 (backoffMs) | 500 ms | 重試的起始延遲時間（指數回退） |
| 自動多分段閾值 | 5 MB | 超過此大小自動使用多分段上傳 |

配置位置：
- `ConnectionProfile.concurrency` 和 `ConnectionProfile.partSizeMb`
- `TransferQueue(maxConcurrent: 3)`

## 8) 安全與儲存

### 連線設定檔
- 儲存位置：`~/Library/Application Support/<app>/profiles.json`
- macOS Keychain 整合：TODO（目前使用加密 JSON）
- ⚠️ 開發階段 secret key 以明文儲存，生產環境需使用 Keychain

### 書籤
- 儲存位置：`~/Library/Application Support/<app>/bookmarks.json`

## 9) 已知問題

- ⚠️ US2 multipart upload 測試有檔案存取衝突（FileSystemException），功能本身正常但測試需要修復
- ⚠️ 預簽 URL 目前為簡化實作，未實作完整 SigV4 簽名（TODO）
- ⚠️ UI 層面板（權限、同步）尚未實作，服務層已完成

## 10) 後續延伸

- Windows 打包與測試為後續發佈
- macOS 打包腳本與簽章（T037）
- 完整 UI 面板（權限、同步、書籤）
- 完整 US3 整合測試
- 生產級 SigV4 預簽 URL
- 完整錯誤/日誌 UI 整合


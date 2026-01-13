# research.md — MVP S3 桌面瀏覽器

## 決策與澄清

### 主題與 UI 套件
- Decision: 採用 repo 內 `docs/creativetimofficial-now-ui-pro-flutter` 的資源作為 UI 主題，僅整合必要色票、元件樣式與圖示，避免改動其設計規範。
- Rationale: 符合「專業樣式套件」要求，減少自行設計工時；Flutter Desktop 可直接引用本地資源與 Dart 包。
- Alternatives: (1) 自行客製主題（超出 MVP 範圍，時間成本高）；(2) 使用其他免費 UI 套件（不符指定套件要求）。

### S3 相容 API 客戶端
- Decision: 使用 Dart `aws_client` / `aws_s3_api` 提供的 SigV4 簽名與 S3 API（ListBuckets、ListObjectsV2、PutObject、Multipart Upload 等），自訂 endpoint/region 以支援相容服務。
- Rationale: 純 Dart、跨桌面可行；支援自訂端點；API 覆蓋常見 S3 操作；減少平台原生橋接。
- Alternatives: (1) 直接 HTTP 手寫簽名（易錯且耗時）；(2) 原生 AWS SDK via FFI（增加封裝與維護成本）。

### 傳輸佇列與並行
- Decision: 以 Dart Futures + 受控並行度實作佇列；多分段上傳採 S3 Multipart Upload（CreateMultipartUpload → UploadPart → Complete）；預設並行 3、可調；失敗重試具最大次數與回退間隔。
- Rationale: 滿足 P1/P2 需求且避免過度設計；Dart Isolates 可按需用於大檔分段計算，但 MVP 先用主 isolate 控制並行 I/O。
- Alternatives: (1) 全面 isolate/worker 池（增加複雜度）；(2) 單任務序列化（不符效能需求）。

### 預覽策略
- Decision: 圖片/文字檔以 Range 讀取小片段或限制檔案大小（例如 ≤10MB）後載入；不支援格式回報「無法預覽」並提供下載。
- Rationale: 避免完整下載；符合 MVP 需求；介面可快速回應。
- Alternatives: (1) 全檔下載後預覽（耗時）；(2) 內嵌複雜多媒體播放器（非 MVP）。

### 設定與憑證儲存
- Decision: 將連線設定（endpoint/region/key/secret/缺省 Bucket/並行與分段參數）存於本機安全存放區不可得時，使用加密 JSON 檔（如 macOS Keychain 優先，不可用時 fallback 檔案）。
- Rationale: 桌面端需保護金鑰；保持離線可讀寫；不引入伺服端。
- Alternatives: (1) 純明文設定檔（安全性不足）；(2) 引入雲端設定同步（超出 MVP）。

### 測試與相容性
- Decision: 開發/CI 使用 LocalStack 或 MinIO 作為 S3 相容測試端點；核心流程以 flutter test + integration_test（若桌面 runner 支援）驗證列表/上傳/下載/預覽。
- Rationale: 避免依賴實體 AWS 帳號；可重現；支援多端點。
- Alternatives: (1) 僅用真實 AWS（成本與權限風險）；(2) 自建 mock（覆蓋不足）。

### 平台與部署
- Decision: 先鎖定 macOS 桌面打包（Universal 或 x64 視需求）；Windows 後續獨立發佈，介面與邏輯共用 Flutter 程式碼。
- Rationale: 符合使用者要求，降低當前平台變異；保持後續延伸可能。
- Alternatives: 同步支援 Windows（增加測試矩陣，不符 MVP）。

## 待辦澄清
- 無。當前需求已可支撐計畫撰寫。

# Implementation Plan: MVP S3 桌面瀏覽器

**Branch**: `001-s3-desktop-app` | **Date**: 2026-01-13 | **Spec**: specs/001-s3-desktop-app/spec.md
**Input**: Feature specification from specs/001-s3-desktop-app/spec.md

**Note**: This plan follows /speckit.plan workflow.

## Summary

以 Flutter 建立 macOS 優先的 S3/S3-Compatible 桌面檔案總管，套用 CreativeTim Now UI Pro Flutter 主題。提供基本檔案管理、佇列化多分段傳輸、預覽、ACL/Policy/CORS（視服務）與簽署 URL。MVP 聚焦單一桌面應用（無後端），以 aws_client/aws_s3_api 等 Dart 套件直連端點。

## Technical Context

**Language/Version**: Dart 3.x、Flutter 3.x（macOS 桌面目標）  
**Primary Dependencies**: Flutter 桌面支援、aws_client 或 aws_s3_api（S3 相容 API）、http、path、provider/state 管理（簡化用），file_picker/desktop_drop（拖曳）、creativetim Now UI Pro Flutter 主題資源  
**Storage**: 本機設定檔（JSON/共享偏好）與暫存目錄；無伺服端資料庫  
**Testing**: flutter test（單元/Widget），integration_test（桌面流程，如可行），最小必要的契約測試以 mock S3 端點  
**Target Platform**: macOS 桌面（先行）；Windows 後續獨立版本  
**Project Type**: 單一 Flutter 桌面應用  
**Performance Goals**: 列出 Bucket/物件 ≤10 秒；預覽圖片/文字 ≤3 秒 90%；佇列三任務並行不中斷；5GB 多分段上傳成功率 ≥95%（有重試）  
**Constraints**: 不需離線完整緩存；UI 必須使用 Now UI Pro 主題；避免過度設計（MVP 優先）；兼容自訂端點/區域；安全錯誤需明確  
**Scale/Scope**: 主要服務於中小型團隊，多帳號/多 Bucket；單視窗多分頁/多窗格（後續可擴充）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Constitution 文件尚未定義具體原則（.specify/memory/constitution.md 為樣板），視為無強制門檻；若後續加入需再對照。

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/                      # Flutter 桌面專案根（假設）
├── lib/
│   ├── theme/            # Now UI Pro Flutter 主題封裝（色票、字體、元件樣式）
│   ├── features/
│   │   ├── connection/   # 設定檔管理、端點/區域/金鑰 UI
│   │   ├── browser/      # Bucket/物件列表、搜尋/篩選、拖曳
│   │   ├── transfer/     # 佇列、多分段上傳、進度視窗
│   │   ├── preview/      # 圖片/文字預覽
│   │   ├── permissions/  # ACL/Policy/CORS（視服務）
│   │   ├── sync/         # 基本同步/鏡像
│   │   └── bookmarks/    # 書籤/快速存取
│   ├── services/         # S3 客戶端封裝、傳輸佇列、設定儲存
│   ├── models/           # 對應 data-model.md 的實體
│   ├── widgets/          # 共用 UI 元件（雙窗格、分頁、表格、狀態列）
│   └── main.dart
├── assets/               # Now UI Pro 資源（fonts/icons）
└── test/
    ├── unit/
    ├── widget/
    └── integration/      # 若桌面 runner 支援
```

**Structure Decision**: 單一 Flutter 桌面專案（app/），以 features 分層 + services 封裝 S3/佇列邏輯，theme 內聚指定主題資源；無後端專案。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | - | - |

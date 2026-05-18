# 品質與安全檢查報告（2026-05-18）

## 結論

- 品質檢查：已修復 analyzer 編譯錯誤、lint issue、測試入口不一致與缺少依賴問題。
- 安全掃描：發現 3 個可修風險並已修復；目前沒有未解的高信心可回報安全漏洞。
- 版本：更新至 `1.0.1+2`。

## 已修復品質問題

- `PermissionsPanel` 不再使用 `key` 作為物件 key 欄位，避免覆寫 `Widget.key`。
- `SyncScreen` 對齊現有 `SyncService` API，移除不存在的型別與方法引用。
- 補齊 `path_provider`、`intl`、`crypto` 直接依賴。
- 修正 `widget_test.dart` 的 app root 測試。
- 清理 `avoid_print`、deprecated API、package import、未使用變數與 analyzer warnings。

## 已修復安全問題

- 預簽 URL：新增 `SigV4Presigner`，GET/PUT URL 改為 AWS SigV4 query signing。
- S3 key 處理：`S3Client._cleanKey` 不再使用本機檔案路徑正規化，避免 `..` segment 被改寫。
- ACL UI：移除 `public-read-write` 快速範本，降低誤設公開寫入風險。

## 尚待後續處理

- Profile credentials 仍存於本機 JSON，後續應改為 macOS Keychain 並提供既有 profile 遷移。
- S3/MinIO 整合測試需要 `TEST_S3_*` 環境變數；本次未提供，因此依測試設計 skipped。

## 驗證

```bash
flutter analyze
flutter test
```

結果：兩者皆通過；`flutter test` 中整合測試因未設定 `TEST_S3_*` 變數而 skipped。

完整安全掃描產物：

`/tmp/codex-security-scans/S3-Explorer/6f1af6d_20260518174255/report.md`

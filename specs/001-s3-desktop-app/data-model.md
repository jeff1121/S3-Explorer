# data-model.md — MVP S3 桌面瀏覽器

## Entities

### ConnectionProfile
- id, name
- endpoint, region
- accessKeyId, secretKey (安全儲存指標，不記明文位置)
- defaultBucket, defaultPrefix
- concurrency (int), partSizeMB (int), retryPolicy {maxAttempts, backoffMs}

### ObjectNode
- bucket
- key (path)
- isFolder (bool)
- sizeBytes
- lastModified
- etag
- acl (optional summary)
- contentType (optional，用於預覽)

### TransferTask
- id
- type (upload|download|copy|move|delete|sync)
- source {bucket,key,localPath?,endpointProfileId}
- target {bucket,key,localPath?,endpointProfileId}
- status (pending|running|paused|failed|completed|canceled)
- progress {bytesTransferred, totalBytes, partsCompleted?, partsTotal?}
- retryCount
- error (last error message)
- createdAt, updatedAt

### SyncJob (簡化的同步/鏡像)
- id
- source {bucket,keyPrefix,localPath?,profileId}
- target {bucket,keyPrefix,localPath?,profileId}
- mode (one-way|mirror)
- conflictPolicy (overwrite|skip|keep-both)
- status (pending|running|failed|completed)
- summary {added, updated, skipped, conflicts}

### PresignedUrlRecord
- id
- bucket, key
- action (get|put)
- expiresAt
- generatedAt
- url

### Bookmark
- id
- label
- bucket
- prefix
- profileId

### PolicyItem (for ACL/Policy/CORS UI)
- scope (bucket|object)
- type (acl|policy|cors)
- statementSummary / cannedAcl
- lastSyncedAt

## Relationships
- ConnectionProfile 1..* → Bookmark
- ConnectionProfile 1..* → PresignedUrlRecord
- ConnectionProfile referenced by TransferTask/SyncJob source/target
- ObjectNode belongs to a bucket; derived from listing
- PolicyItem associated with bucket or object

## Validation & Rules
- Access keys 必須成對；endpoint 需為合法 URL；region 可為自訂字串
- partSizeMB 需 ≥ 5MB (S3 Multipart 下限)；concurrency 建議 1–5，預設 3
- Presigned URL expiresAt > now 且在服務允許範圍內
- Bookmark/prefix 不得為空；標籤需唯一於同 profile
- SyncJob 衝突政策必填；mode=mirror 時需雙向或單向清楚標示

## State Transitions (TransferTask)
- pending → running → (completed | failed | paused)
- paused → running
- failed → running (on retry)
- running → canceled (user cancel)
- running (multipart) → partial failed parts tracked, auto-retry up to max

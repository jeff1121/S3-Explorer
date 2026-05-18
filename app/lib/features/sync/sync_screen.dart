import 'package:app/models/entities.dart' show EndpointRef, TransferStatus;
import 'package:app/services/object_service.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/sync_service.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sync/Mirror task management screen.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _formKey = GlobalKey<FormState>();

  String _sourceBucket = '';
  String _sourcePrefix = '';
  String _targetBucket = '';
  String _targetPrefix = '';
  SyncMode _mode = SyncMode.oneWay;
  ConflictPolicy _conflictPolicy = ConflictPolicy.overwrite;
  bool _dryRun = true;
  bool _isSyncing = false;
  SyncJob? _lastJob;
  String? _error;

  Future<void> _executeSyncTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSyncing = true;
      _error = null;
      _lastJob = null;
    });

    try {
      final client = context.read<S3Client>();
      final queue = context.read<TransferQueue>();
      final objectService = ObjectService(client: client, queue: queue);
      final syncService = SyncService(
        client: client,
        queue: queue,
        objectService: objectService,
      );

      if (_dryRun) {
        final sourceObjects = await objectService.listObjects(
          _sourceBucket,
          prefix: _normalizedPrefix(_sourcePrefix),
        );
        _lastJob = SyncJob(
          id: 'dry-run',
          name: '同步預覽',
          source: EndpointRef(
              bucket: _sourceBucket, key: _normalizedPrefix(_sourcePrefix)),
          target: EndpointRef(
              bucket: _targetBucket, key: _normalizedPrefix(_targetPrefix)),
          mode: _mode,
          conflictPolicy: _conflictPolicy,
          status: TransferStatus.completed,
          filesScanned: sourceObjects.length,
          totalBytes:
              sourceObjects.fold<int>(0, (sum, item) => sum + item.sizeBytes),
        );
      } else {
        _lastJob = await syncService.startSync(
          name: '$_sourceBucket -> $_targetBucket',
          source: EndpointRef(
              bucket: _sourceBucket, key: _normalizedPrefix(_sourcePrefix)),
          target: EndpointRef(
              bucket: _targetBucket, key: _normalizedPrefix(_targetPrefix)),
          mode: _mode,
          conflictPolicy: _conflictPolicy,
        );
      }

      if (!mounted) return;
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dryRun ? '同步預覽完成' : '同步工作已啟動')),
      );
    } catch (e) {
      setState(() {
        _error = '同步失敗: $e';
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步/鏡像任務'),
        actions: [
          if (_lastJob != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showResultDetails,
              tooltip: '查看同步工作',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEndpointCard(
                title: '來源設定',
                bucketLabel: 'Source Bucket *',
                prefixLabel: 'Source Prefix',
                onBucketChanged: (value) => _sourceBucket = value,
                onPrefixChanged: (value) => _sourcePrefix = value,
              ),
              const SizedBox(height: 16),
              _buildEndpointCard(
                title: '目標設定',
                bucketLabel: 'Target Bucket *',
                prefixLabel: 'Target Prefix',
                onBucketChanged: (value) => _targetBucket = value,
                onPrefixChanged: (value) => _targetPrefix = value,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('同步策略', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<SyncMode>(
                        segments: const [
                          ButtonSegment(
                            value: SyncMode.oneWay,
                            label: Text('單向同步'),
                            icon: Icon(Icons.arrow_forward),
                          ),
                          ButtonSegment(
                            value: SyncMode.mirror,
                            label: Text('鏡像'),
                            icon: Icon(Icons.sync_alt),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) =>
                            setState(() => _mode = selection.first),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ConflictPolicy>(
                        initialValue: _conflictPolicy,
                        decoration: const InputDecoration(
                          labelText: '衝突處理',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ConflictPolicy.overwrite,
                            child: Text('覆寫'),
                          ),
                          DropdownMenuItem(
                            value: ConflictPolicy.skip,
                            child: Text('跳過'),
                          ),
                          DropdownMenuItem(
                            value: ConflictPolicy.keepBoth,
                            child: Text('保留兩者'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _conflictPolicy = value!),
                      ),
                      SwitchListTile(
                        value: _dryRun,
                        onChanged: (value) => setState(() => _dryRun = value),
                        title: const Text('預覽模式'),
                        subtitle: const Text('只掃描來源並顯示預估，不執行寫入或刪除'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              if (_lastJob != null) ...[
                const SizedBox(height: 16),
                _buildResultCard(_lastJob!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _executeSyncTask,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_dryRun ? Icons.preview : Icons.sync),
                  label: Text(
                      _isSyncing ? '處理中...' : (_dryRun ? '預覽同步計畫' : '執行同步')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndpointCard({
    required String title,
    required String bucketLabel,
    required String prefixLabel,
    required ValueChanged<String> onBucketChanged,
    required ValueChanged<String> onPrefixChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                  labelText: bucketLabel, border: const OutlineInputBorder()),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '請輸入 Bucket 名稱'
                  : null,
              onChanged: onBucketChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                  labelText: prefixLabel, border: const OutlineInputBorder()),
              onChanged: onPrefixChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(SyncJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('上次同步工作', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('狀態: ${job.status.name}'),
            Text('掃描檔案: ${job.filesScanned}'),
            Text('已傳輸檔案: ${job.filesTransferred}'),
            Text('傳輸位元組: ${job.bytesTransferred} / ${job.totalBytes}'),
            if (job.errors.isNotEmpty) Text('錯誤: ${job.errors.length}'),
          ],
        ),
      ),
    );
  }

  void _showResultDetails() {
    final job = _lastJob;
    if (job == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步工作詳細資訊'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('工作名稱: ${job.name}'),
                Text('狀態: ${job.status.name}'),
                Text('來源: ${job.source.bucket}/${job.source.key ?? ''}'),
                Text('目標: ${job.target.bucket}/${job.target.key ?? ''}'),
                Text('模式: ${job.mode.name}'),
                Text('衝突處理: ${job.conflictPolicy.name}'),
                if (job.errors.isNotEmpty) ...[
                  const Divider(),
                  ...job.errors.map((error) => Text(error)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  String? _normalizedPrefix(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sync_service.dart';
import '../../services/s3_client.dart';
import '../../models/connection_profile.dart';

/// Sync/Mirror task management screen
/// 
/// Features:
/// - Configure source and target (bucket/prefix)
/// - Select sync strategy (one-way, mirror)
/// - Configure conflict policy (overwrite, skip, keepBoth)
/// - Preview sync plan before execution
/// - Execute sync with progress tracking
/// - View sync results and logs
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Source configuration
  String _sourceBucket = '';
  String _sourcePrefix = '';
  
  // Target configuration
  String _targetBucket = '';
  String _targetPrefix = '';
  
  // Sync configuration
  SyncStrategy _strategy = SyncStrategy.oneWay;
  ConflictPolicy _conflictPolicy = ConflictPolicy.overwrite;
  bool _deleteExtraFiles = false;
  bool _dryRun = true;
  
  // State
  bool _isSyncing = false;
  SyncResult? _lastResult;
  String? _error;

  late SyncService _syncService;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService(context.read<S3Client>());
  }

  Future<void> _executeSyncTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSyncing = true;
      _error = null;
      _lastResult = null;
    });

    try {
      final config = SyncConfiguration(
        sourceBucket: _sourceBucket,
        sourcePrefix: _sourcePrefix,
        targetBucket: _targetBucket,
        targetPrefix: _targetPrefix,
        strategy: _strategy,
        conflictPolicy: _conflictPolicy,
        deleteExtraFiles: _deleteExtraFiles,
        dryRun: _dryRun,
      );

      final result = await _syncService.sync(config);
      
      setState(() {
        _lastResult = result;
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_dryRun ? '同步預覽完成' : '同步完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
          if (_lastResult != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showResultDetails(),
              tooltip: '查看同步結果',
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
              // Source Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '來源設定',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Source Bucket *',
                          hintText: 'my-source-bucket',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? '請輸入 Bucket 名稱' : null,
                        onChanged: (value) => _sourceBucket = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Source Prefix (選填)',
                          hintText: 'folder/subfolder/',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _sourcePrefix = value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Target Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '目標設定',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Target Bucket *',
                          hintText: 'my-target-bucket',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? '請輸入 Bucket 名稱' : null,
                        onChanged: (value) => _targetBucket = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Target Prefix (選填)',
                          hintText: 'backup/folder/',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _targetPrefix = value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sync Strategy Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '同步策略',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: const Text('單向同步 (One-way)'),
                        subtitle: const Text('僅將來源的變更同步到目標'),
                        leading: Radio<SyncStrategy>(
                          value: SyncStrategy.oneWay,
                          groupValue: _strategy,
                          onChanged: (value) =>
                              setState(() => _strategy = value!),
                        ),
                      ),
                      ListTile(
                        title: const Text('鏡像 (Mirror)'),
                        subtitle: const Text('目標完全鏡像來源，刪除目標額外檔案'),
                        leading: Radio<SyncStrategy>(
                          value: SyncStrategy.mirror,
                          groupValue: _strategy,
                          onChanged: (value) =>
                              setState(() => _strategy = value!),
                        ),
                      ),
                      const Divider(),
                      Text(
                        '衝突處理',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ConflictPolicy>(
                        value: _conflictPolicy,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ConflictPolicy.overwrite,
                            child: Text('覆寫 (Overwrite)'),
                          ),
                          DropdownMenuItem(
                            value: ConflictPolicy.skip,
                            child: Text('跳過 (Skip)'),
                          ),
                          DropdownMenuItem(
                            value: ConflictPolicy.keepBoth,
                            child: Text('保留兩者 (Keep Both)'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _conflictPolicy = value!),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('刪除目標額外檔案'),
                        subtitle: const Text('刪除來源不存在但目標存在的檔案'),
                        value: _deleteExtraFiles,
                        onChanged: (value) =>
                            setState(() => _deleteExtraFiles = value),
                      ),
                      SwitchListTile(
                        title: const Text('預覽模式 (Dry Run)'),
                        subtitle: const Text('不實際執行，僅顯示將執行的操作'),
                        value: _dryRun,
                        onChanged: (value) => setState(() => _dryRun = value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Display
              if (_error != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Last Result Summary
              if (_lastResult != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '上次同步結果',
                              style: theme.textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: _showResultDetails,
                              child: const Text('詳細資訊'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildResultSummary(_lastResult!),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Execute Button
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
                  label: Text(_isSyncing
                      ? '同步中...'
                      : _dryRun
                          ? '預覽同步計畫'
                          : '執行同步'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dryRun
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(SyncResult result) {
    return Column(
      children: [
        _buildResultRow('已複製', result.copiedCount, Icons.file_copy),
        _buildResultRow('已更新', result.updatedCount, Icons.update),
        _buildResultRow('已刪除', result.deletedCount, Icons.delete),
        _buildResultRow('已跳過', result.skippedCount, Icons.skip_next),
        if (result.errorCount > 0)
          _buildResultRow(
            '錯誤',
            result.errorCount,
            Icons.error,
            color: Theme.of(context).colorScheme.error,
          ),
        const Divider(),
        _buildResultRow(
          '總計',
          result.copiedCount +
              result.updatedCount +
              result.deletedCount +
              result.skippedCount,
          Icons.check_circle,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    int count,
    IconData icon, {
    Color? color,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDetails() {
    if (_lastResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步詳細結果'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('執行時間: ${_formatDuration(_lastResult!.duration)}'),
                const Divider(),
                if (_lastResult!.copiedFiles.isNotEmpty) ...[
                  const Text(
                    '已複製檔案:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._lastResult!.copiedFiles
                      .map((f) => Text('  • $f', style: const TextStyle(fontSize: 12))),
                  const SizedBox(height: 8),
                ],
                if (_lastResult!.updatedFiles.isNotEmpty) ...[
                  const Text(
                    '已更新檔案:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._lastResult!.updatedFiles
                      .map((f) => Text('  • $f', style: const TextStyle(fontSize: 12))),
                  const SizedBox(height: 8),
                ],
                if (_lastResult!.deletedFiles.isNotEmpty) ...[
                  const Text(
                    '已刪除檔案:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._lastResult!.deletedFiles
                      .map((f) => Text('  • $f', style: const TextStyle(fontSize: 12))),
                  const SizedBox(height: 8),
                ],
                if (_lastResult!.skippedFiles.isNotEmpty) ...[
                  const Text(
                    '已跳過檔案:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._lastResult!.skippedFiles
                      .map((f) => Text('  • $f', style: const TextStyle(fontSize: 12))),
                  const SizedBox(height: 8),
                ],
                if (_lastResult!.errors.isNotEmpty) ...[
                  const Text(
                    '錯誤訊息:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  ..._lastResult!.errors.entries.map((e) => Text(
                        '  • ${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      )),
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

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} 秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} 分 ${duration.inSeconds % 60} 秒';
    } else {
      return '${duration.inHours} 小時 ${duration.inMinutes % 60} 分';
    }
  }
}

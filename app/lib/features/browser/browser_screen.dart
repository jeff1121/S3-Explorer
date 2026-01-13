import 'package:app/features/browser/browser_viewmodel.dart';
import 'package:app/features/browser/drag_drop_handler.dart';
import 'package:app/models/entities.dart';
import 'package:app/services/object_service.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:app/theme/theme.dart';
import 'package:app/features/transfer/transfer_panel.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key, required this.profile});

  final ConnectionProfile profile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final queue = context.read<TransferQueue>();
        final client = S3Client(profile: profile);
        final service = ObjectService(client: client, queue: queue);
        final vm = BrowserViewModel(profile: profile, objectService: service, queue: queue);
        vm.init();
        return vm;
      },
      child: const _BrowserView(),
    );
  }
}

class _BrowserView extends StatefulWidget {
  const _BrowserView();

  @override
  State<_BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<_BrowserView> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BrowserViewModel>();
    final queue = context.watch<TransferQueue>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(vm.currentBucket ?? 'Browser'),
        actions: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout),
            tooltip: '切換連線',
          )
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Text(vm.error!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade800)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: vm.currentBucket,
                          hint: const Text('選擇 Bucket'),
                          items: vm.buckets
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) vm.setBucket(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(vm.prefix),
                          initialValue: vm.prefix,
                          decoration: const InputDecoration(labelText: 'Prefix', hintText: 'e.g. logs/'),
                          onFieldSubmitted: (value) => vm.setPrefix(value.trim().isEmpty ? '' : (value.endsWith('/') ? value : '$value/')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(onPressed: vm.refresh, icon: const Icon(Icons.refresh)),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: vm.working ? null : () => _pickAndUpload(context, vm),
                        icon: const Icon(Icons.file_upload),
                        label: const Text('上傳'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: vm.selectedKeys.isEmpty || vm.working ? null : () => _downloadSelection(context, vm),
                        icon: const Icon(Icons.download),
                        label: const Text('下載'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: vm.selectedKeys.isEmpty || vm.working ? null : () => _makePublic(context, vm),
                        icon: const Icon(Icons.public),
                        label: const Text('公開'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: vm.selectedKeys.isEmpty || vm.working ? null : () => _confirmDelete(context, vm),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('刪除'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _objectPane(context, vm)),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _detailPane(context, vm)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TransferPanel(),
                ],
              ),
            ),
                if (_version.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v$_version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _objectPane(BuildContext context, BrowserViewModel vm) {
    final theme = Theme.of(context);
    return DropTarget(
      onDragDone: (details) => _handleDrop(context, vm, details),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('物件 (${vm.objects.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text('拖曳檔案至此區上傳', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: vm.objects.isEmpty
                  ? const Center(child: Text('尚無物件'))
                  : ListView.separated(
                      itemCount: vm.objects.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final obj = vm.objects[index];
                        final selected = vm.selectedKeys.contains(obj.key);
                        return ListTile(
                          selected: selected,
                          selectedTileColor: NowUITheme.surface,
                          leading: Icon(obj.isFolder ? Icons.folder : Icons.insert_drive_file, color: obj.isFolder ? NowUITheme.primary : Colors.grey[700]),
                          title: Text(obj.key, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                          subtitle: obj.isFolder
                              ? const Text('資料夾')
                              : Text('${obj.sizeBytes} bytes · ${obj.lastModified.toLocal()}'),
                          onTap: () {
                            if (obj.isFolder) {
                              vm.setPrefix(obj.key);
                            } else {
                              vm.toggleSelection(obj);
                            }
                          },
                          trailing: obj.isFolder
                              ? const Icon(Icons.chevron_right)
                              : Checkbox(value: selected, onChanged: (_) => vm.toggleSelection(obj)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailPane(BuildContext context, BrowserViewModel vm) {
    final theme = Theme.of(context);
    final selected = vm.selectedNodes;
    final primary = selected.isNotEmpty ? selected.first : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: primary == null
          ? Center(child: Text('選取檔案以查看詳細資訊', style: theme.textTheme.bodyMedium))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primary.key, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Bucket: ${primary.bucket}'),
                Text('大小: ${primary.sizeBytes} bytes'),
                Text('更新時間: ${primary.lastModified.toLocal()}'),
                if (primary.etag != null) Text('ETag: ${primary.etag}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: vm.working ? null : () => _downloadSelection(context, vm),
                      icon: const Icon(Icons.download),
                      label: const Text('下載選取'),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.working ? null : () => _copyOrMove(context, vm, move: false),
                      icon: const Icon(Icons.copy),
                      label: const Text('複製'),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.working ? null : () => _copyOrMove(context, vm, move: true),
                      icon: const Icon(Icons.drive_file_move),
                      label: const Text('移動'),
                    ),
                    TextButton.icon(
                      onPressed: vm.working ? null : () => _confirmDelete(context, vm),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('刪除'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, BrowserViewModel vm) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    await vm.uploadFiles(paths);
  }

  Future<void> _downloadSelection(BuildContext context, BrowserViewModel vm) async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) return;
    await vm.downloadSelection(directory);
  }

  Future<void> _makePublic(BuildContext context, BrowserViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('設為公開存取'),
          content: Text('確定將 ${vm.selectedKeys.length} 個檔案設為公開存取 (public-read)？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    final urls = await vm.makeSelectedPublic();
    
    if (urls.isEmpty) return;
    
    if (!context.mounted) return;
    
    // Show URLs in a dialog
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('公開存取 URL'),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('已設定為公開存取，以下為 URL：'),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: urls.length,
                    itemBuilder: (context, index) {
                      final url = urls[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                url,
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: '複製 URL',
                              onPressed: () {
                                // Copy to clipboard
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已複製到剪貼簿')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, BrowserViewModel vm) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除確認'),
          content: Text('確定刪除 ${vm.selectedKeys.length} 個項目？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('刪除')),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      await vm.deleteSelection();
    }
  }

  Future<void> _copyOrMove(BuildContext context, BrowserViewModel vm, {required bool move}) async {
    if (vm.currentBucket == null) return;
    final bucketNotifier = ValueNotifier<String>(vm.currentBucket!);
    final prefixController = TextEditingController(text: vm.prefix);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(move ? '移動到 Bucket/Prefix' : '複製到 Bucket/Prefix'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: bucketNotifier.value,
                items: vm.buckets.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (value) {
                  if (value != null) bucketNotifier.value = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prefixController,
                decoration: const InputDecoration(labelText: 'Prefix (可留空)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(move ? '移動' : '複製')),
          ],
        );
      },
    );
    if (confirmed == true) {
      await vm.copySelection(bucketNotifier.value, prefixController.text, move: move);
    }
  }

  Future<void> _handleDrop(BuildContext context, BrowserViewModel vm, DropDoneDetails details) async {
    final handler = DragDropHandler();
    final files = await handler.filesFromDrop(details);
    await vm.uploadFilesWithStructure(files);
  }
}

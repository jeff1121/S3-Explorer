import 'package:app/features/connection/connection_viewmodel.dart';
import 'package:app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConnectionViewModel(
        storage: context.read(),
        logger: context.read(),
      )..load(),
      child: const _ConnectionView(),
    );
  }
}

class _ConnectionView extends StatefulWidget {
  const _ConnectionView();

  @override
  State<_ConnectionView> createState() => _ConnectionViewState();
}

class _ConnectionViewState extends State<_ConnectionView> {
  final _formKey = GlobalKey<FormState>();
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
    final vm = context.watch<ConnectionViewModel>();
    final theme = Theme.of(context);
    if (vm.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('連線設定')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('設定檔', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: vm.profiles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final profile = vm.profiles[index];
                              final selected = profile.id == vm.selected?.id;
                              return ListTile(
                                tileColor: selected ? NowUITheme.surface : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                title: Text(profile.name),
                                subtitle: Text('${profile.endpoint.host} (${profile.region})'),
                                trailing: selected ? const Icon(Icons.check_circle, color: NowUITheme.primary) : null,
                                onTap: () => vm.select(profile.id),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final newProfile = await vm.addTemplate();
                                vm.select(newProfile.id);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('新增設定'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: vm.selected == null ? null : vm.deleteSelected,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('刪除'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('連線詳情', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            if (vm.errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                child: Text(vm.errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade800)),
                              ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('name-${vm.selected?.id}'),
                              initialValue: vm.name,
                              decoration: const InputDecoration(labelText: '名稱'),
                              onChanged: (v) => vm.updateDraft(name: v),
                              validator: (v) => (v == null || v.isEmpty) ? '名稱必填' : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('endpoint-${vm.selected?.id}'),
                              initialValue: vm.endpointText,
                              decoration: const InputDecoration(labelText: 'Endpoint', hintText: 'https://s3.local:9000'),
                              onChanged: (v) => vm.updateDraft(endpoint: v),
                              validator: (v) => (v == null || !v.startsWith('http')) ? '需為 http/https URL' : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('region-${vm.selected?.id}'),
                                    initialValue: vm.region,
                                    decoration: const InputDecoration(labelText: 'Region'),
                                    onChanged: (v) => vm.updateDraft(region: v),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Region 必填' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('bucket-${vm.selected?.id}'),
                                    initialValue: vm.defaultBucket,
                                    decoration: const InputDecoration(labelText: '預設 Bucket (選填)'),
                                    onChanged: (v) => vm.updateDraft(defaultBucket: v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('prefix-${vm.selected?.id}'),
                              initialValue: vm.defaultPrefix,
                              decoration: const InputDecoration(labelText: '預設 Prefix (選填)'),
                              onChanged: (v) => vm.updateDraft(defaultPrefix: v),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('access-${vm.selected?.id}'),
                                    initialValue: vm.accessKeyId,
                                    decoration: const InputDecoration(labelText: 'Access Key'),
                                    onChanged: (v) => vm.updateDraft(accessKeyId: v),
                                    validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('secret-${vm.selected?.id}'),
                                    initialValue: vm.secretKey,
                                    decoration: const InputDecoration(labelText: 'Secret Key'),
                                    obscureText: true,
                                    onChanged: (v) => vm.updateDraft(secretKey: v),
                                    validator: (v) => (v == null || v.isEmpty) ? '必填' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('concurrency-${vm.selected?.id}'),
                                    initialValue: vm.concurrency.toString(),
                                    decoration: const InputDecoration(labelText: '並行數'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => vm.updateDraft(concurrency: int.tryParse(v) ?? vm.concurrency),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('part-${vm.selected?.id}'),
                                    initialValue: vm.partSizeMb.toString(),
                                    decoration: const InputDecoration(labelText: '分段大小 (MB)'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => vm.updateDraft(partSizeMb: int.tryParse(v) ?? vm.partSizeMb),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('retry-${vm.selected?.id}'),
                                    initialValue: vm.retryMaxAttempts.toString(),
                                    decoration: const InputDecoration(labelText: '重試次數'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => vm.updateDraft(retryMaxAttempts: int.tryParse(v) ?? vm.retryMaxAttempts),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('backoff-${vm.selected?.id}'),
                                    initialValue: vm.retryBackoffMs.toString(),
                                    decoration: const InputDecoration(labelText: '回退 (ms)'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => vm.updateDraft(retryBackoffMs: int.tryParse(v) ?? vm.retryBackoffMs),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: vm.saving
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) return;
                                          final error = await vm.saveDraft();
                                          if (error == null && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存設定')));
                                          }
                                        },
                                  icon: const Icon(Icons.save),
                                  label: const Text('儲存'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: vm.testing
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) return;
                                          final error = await vm.testConnection();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(error == null ? '連線成功' : '連線失敗: $error')),
                                            );
                                          }
                                        },
                                  icon: vm.testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
                                  label: const Text('測試連線'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: vm.saving
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) return;
                                          final error = await vm.saveDraft();
                                          if (error == null && context.mounted) {
                                            context.go('/browser', extra: vm.selected);
                                          }
                                        },
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('開始瀏覽'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_version.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: Text(
                'S3 Explorer v$_version',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

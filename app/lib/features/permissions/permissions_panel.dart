import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/services/permissions_service.dart';
import 'package:app/services/s3_client.dart';

/// Permissions panel for managing ACL, Bucket Policy, and CORS
///
/// Features:
/// - View and edit Bucket/Object ACL
/// - View and edit Bucket Policy (if supported by service)
/// - View and edit CORS configuration (if supported by service)
/// - Grant/Revoke permissions with predefined ACL templates
class PermissionsPanel extends StatefulWidget {
  final String bucket;
  final String? objectKey; // null for bucket-level permissions

  const PermissionsPanel({
    super.key,
    required this.bucket,
    this.objectKey,
  });

  @override
  State<PermissionsPanel> createState() => _PermissionsPanelState();
}

class _PermissionsPanelState extends State<PermissionsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PermissionsService _permissionsService;

  AclResult? _currentAcl;
  String? _currentPolicy;
  CorsConfiguration? _currentCors;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _permissionsService = PermissionsService(
      client: context.read<S3Client>(),
    );
    _loadPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.objectKey == null) {
        // Bucket-level permissions
        final results = await Future.wait([
          _permissionsService.getBucketAcl(widget.bucket),
          _permissionsService
              .getBucketPolicy(widget.bucket)
              .catchError((_) => null),
          _permissionsService
              .getBucketCors(widget.bucket)
              .catchError((_) => null),
        ]);
        setState(() {
          _currentAcl = results[0] as AclResult;
          _currentPolicy = results[1] as String?;
          _currentCors = results[2] as CorsConfiguration?;
          _isLoading = false;
        });
      } else {
        // Object-level permissions (ACL only)
        final acl = await _permissionsService.getObjectAcl(
            widget.bucket, widget.objectKey!);
        setState(() {
          _currentAcl = acl;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '載入權限失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyAclTemplate(String template) async {
    setState(() => _isLoading = true);
    try {
      if (widget.objectKey == null) {
        await _permissionsService.setBucketAcl(widget.bucket, template);
      } else {
        await _permissionsService.setObjectAcl(
            widget.bucket, widget.objectKey!, template);
      }
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ACL 已套用')),
        );
      }
    } catch (e) {
      setState(() {
        _error = '套用 ACL 失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePolicy(String policy) async {
    if (widget.objectKey != null) return; // Policy only at bucket level

    setState(() => _isLoading = true);
    try {
      await _permissionsService.setBucketPolicy(widget.bucket, policy);
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bucket Policy 已更新')),
        );
      }
    } catch (e) {
      setState(() {
        _error = '更新 Policy 失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCors(List<CorsRule> rules) async {
    if (widget.objectKey != null) return; // CORS only at bucket level

    setState(() => _isLoading = true);
    try {
      await _permissionsService.setBucketCors(
        widget.bucket,
        CorsConfiguration(rules: rules),
      );
      await _loadPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CORS 設定已更新')),
        );
      }
    } catch (e) {
      setState(() {
        _error = '更新 CORS 失敗: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isObjectLevel = widget.objectKey != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isObjectLevel ? '物件權限' : 'Bucket 權限'),
        bottom: isObjectLevel
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'ACL'),
                  Tab(text: 'Bucket Policy'),
                  Tab(text: 'CORS'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error,
                          size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPermissions,
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                )
              : isObjectLevel
                  ? _buildAclTab()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAclTab(),
                        _buildPolicyTab(),
                        _buildCorsTab(),
                      ],
                    ),
    );
  }

  Widget _buildAclTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick ACL Templates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速 ACL 範本',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAclTemplateButton('private', '私有'),
                      _buildAclTemplateButton('public-read', '公開讀取'),
                      if (widget.objectKey == null) ...[
                        _buildAclTemplateButton('authenticated-read', '已驗證讀取'),
                        _buildAclTemplateButton('log-delivery-write', '日誌寫入'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Current ACL Grants
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '目前授權清單',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_currentAcl == null || _currentAcl!.grants.isEmpty)
                    const Text('無授權記錄（或服務不支援 ACL 讀取）')
                  else
                    ..._currentAcl!.grants.map((grant) => ListTile(
                          leading: Icon(_getPermissionIcon(grant.permission)),
                          title: Text(grant.grantee),
                          subtitle: Text(_formatPermission(grant.permission)),
                          dense: true,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAclTemplateButton(String template, String label) {
    return ElevatedButton(
      onPressed: () => _applyAclTemplate(template),
      child: Text(label),
    );
  }

  Widget _buildPolicyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        'Bucket Policy (JSON)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _currentPolicy == null
                            ? null
                            : () => _showPolicyEditor(_currentPolicy!),
                        icon: const Icon(Icons.edit),
                        label: const Text('編輯'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentPolicy == null)
                    const Text('無 Bucket Policy（或服務不支援）')
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _currentPolicy!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        'CORS 設定',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: () => _showCorsEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('新增規則'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentCors == null || _currentCors!.rules.isEmpty)
                    const Text('無 CORS 規則（或服務不支援）')
                  else
                    ..._currentCors!.rules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rule = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('規則 ${index + 1}'),
                          subtitle: Text(
                            'Origin: ${rule.allowedOrigins.join(", ")}\n'
                            'Methods: ${rule.allowedMethods.join(", ")}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCorsRule(index),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyEditor(String initialPolicy) {
    final controller = TextEditingController(text: initialPolicy);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯 Bucket Policy'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '請輸入有效的 JSON Policy 文件',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePolicy(controller.text);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showCorsEditor() {
    final originController = TextEditingController();
    final methodsController = TextEditingController(text: 'GET, POST');
    final headersController = TextEditingController(text: '*');
    final maxAgeController = TextEditingController(text: '3600');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 CORS 規則'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: originController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Origins',
                  hintText: 'https://example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: methodsController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Methods',
                  hintText: 'GET, POST, PUT',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headersController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Headers',
                  hintText: '*',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxAgeController,
                decoration: const InputDecoration(
                  labelText: 'Max Age (seconds)',
                  hintText: '3600',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRule = CorsRule(
                allowedOrigins: originController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                allowedMethods: methodsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                allowedHeaders: headersController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                maxAgeSeconds: int.tryParse(maxAgeController.text),
              );
              final updatedRules = [...?_currentCors?.rules, newRule];
              Navigator.pop(context);
              _updateCors(updatedRules);
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  void _deleteCorsRule(int index) {
    if (_currentCors == null) return;
    final updatedRules = List<CorsRule>.from(_currentCors!.rules)
      ..removeAt(index);
    _updateCors(updatedRules);
  }

  IconData _getPermissionIcon(AclPermission permission) {
    switch (permission) {
      case AclPermission.fullControl:
        return Icons.admin_panel_settings;
      case AclPermission.read:
        return Icons.visibility;
      case AclPermission.write:
        return Icons.edit;
      case AclPermission.readAcp:
        return Icons.policy;
      case AclPermission.writeAcp:
        return Icons.security;
    }
  }

  String _formatPermission(AclPermission permission) {
    switch (permission) {
      case AclPermission.fullControl:
        return '完全控制';
      case AclPermission.read:
        return '讀取';
      case AclPermission.write:
        return '寫入';
      case AclPermission.readAcp:
        return '讀取 ACL';
      case AclPermission.writeAcp:
        return '寫入 ACL';
    }
  }
}

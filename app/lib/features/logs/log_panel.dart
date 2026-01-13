import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Log level for message categorization
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Log message entry
class LogMessage {
  LogMessage({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
    this.details,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;
  final String? details;

  IconData get icon {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return theme.colorScheme.primary;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return theme.colorScheme.error;
    }
  }
}

/// Global log manager for collecting and displaying logs
class LogManager extends ChangeNotifier {
  final List<LogMessage> _messages = [];
  final int _maxMessages = 1000;

  List<LogMessage> get messages => List.unmodifiable(_messages);

  void addLog(LogLevel level, String message, {String? source, String? details}) {
    final log = LogMessage(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
      details: details,
    );

    _messages.insert(0, log); // Latest first

    if (_messages.length > _maxMessages) {
      _messages.removeLast();
    }

    notifyListeners();
  }

  void debug(String message, {String? source, String? details}) {
    addLog(LogLevel.debug, message, source: source, details: details);
  }

  void info(String message, {String? source, String? details}) {
    addLog(LogLevel.info, message, source: source, details: details);
  }

  void warning(String message, {String? source, String? details}) {
    addLog(LogLevel.warning, message, source: source, details: details);
  }

  void error(String message, {String? source, String? details}) {
    addLog(LogLevel.error, message, source: source, details: details);
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  List<LogMessage> filterByLevel(LogLevel level) {
    return _messages.where((m) => m.level == level).toList();
  }

  int get errorCount => _messages.where((m) => m.level == LogLevel.error).length;
  int get warningCount => _messages.where((m) => m.level == LogLevel.warning).length;
}

/// Consolidated log and error display panel
/// 
/// Features:
/// - View all logs in chronological order
/// - Filter by log level (debug, info, warning, error)
/// - Search logs by keyword
/// - View detailed error information
/// - Export logs to file
/// - Clear log history
class LogPanel extends StatefulWidget {
  final LogManager logManager;

  const LogPanel({
    super.key,
    required this.logManager,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  LogLevel? _filterLevel;
  String _searchQuery = '';

  List<LogMessage> get _filteredMessages {
    var messages = widget.logManager.messages;

    // Apply level filter
    if (_filterLevel != null) {
      messages = messages.where((m) => m.level == _filterLevel).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      messages = messages.where((m) {
        return m.message.toLowerCase().contains(query) ||
            (m.source?.toLowerCase().contains(query) ?? false) ||
            (m.details?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return messages;
  }

  @override
  void initState() {
    super.initState();
    widget.logManager.addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    widget.logManager.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredMessages = _filteredMessages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日誌與錯誤訊息'),
        actions: [
          // Error/Warning count badges
          if (widget.logManager.errorCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: const Icon(Icons.error, size: 16, color: Colors.white),
                label: Text('${widget.logManager.errorCount}'),
                backgroundColor: theme.colorScheme.error,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (widget.logManager.warningCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: const Icon(Icons.warning, size: 16, color: Colors.white),
                label: Text('${widget.logManager.warningCount}'),
                backgroundColor: Colors.orange,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清除日誌'),
                  content: const Text('確定要清除所有日誌嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.logManager.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('清除'),
                    ),
                  ],
                ),
              );
            },
            tooltip: '清除日誌',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // Level filter buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: _filterLevel == null,
                      onSelected: (selected) {
                        setState(() => _filterLevel = null);
                      },
                    ),
                    FilterChip(
                      label: const Text('除錯'),
                      avatar: const Icon(Icons.bug_report, size: 16),
                      selected: _filterLevel == LogLevel.debug,
                      onSelected: (selected) {
                        setState(() => _filterLevel = selected ? LogLevel.debug : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('資訊'),
                      avatar: const Icon(Icons.info, size: 16),
                      selected: _filterLevel == LogLevel.info,
                      onSelected: (selected) {
                        setState(() => _filterLevel = selected ? LogLevel.info : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('警告'),
                      avatar: const Icon(Icons.warning, size: 16),
                      selected: _filterLevel == LogLevel.warning,
                      onSelected: (selected) {
                        setState(() => _filterLevel = selected ? LogLevel.warning : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('錯誤'),
                      avatar: const Icon(Icons.error, size: 16),
                      selected: _filterLevel == LogLevel.error,
                      onSelected: (selected) {
                        setState(() => _filterLevel = selected ? LogLevel.error : null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    hintText: '搜尋日誌內容...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),
          // Log list
          Expanded(
            child: filteredMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '無日誌記錄',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = filteredMessages[index];
                      return _buildLogItem(message);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogMessage message) {
    final theme = Theme.of(context);
    final color = message.getColor(context);
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(message.icon, color: color),
        title: Row(
          children: [
            Text(
              timeFormat.format(message.timestamp),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
            if (message.source != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(message.source!, style: const TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const Spacer(),
            Text(
              _getLevelText(message.level),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message.message),
            if (message.details != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  message.details!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: message.details != null
            ? () => _showDetailDialog(message)
            : null,
      ),
    );
  }

  String _getLevelText(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  void _showDetailDialog(LogMessage message) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(message.icon, color: message.getColor(context)),
            const SizedBox(width: 8),
            Text(_getLevelText(message.level)),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '時間: ${timeFormat.format(message.timestamp)}',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                if (message.source != null)
                  Text(
                    '來源: ${message.source}',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                const Divider(),
                Text(
                  '訊息:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(message.message),
                if (message.details != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '詳細資訊:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      message.details!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
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
}

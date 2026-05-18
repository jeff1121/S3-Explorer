import 'package:app/features/preview/preview_service.dart';
import 'package:flutter/material.dart';

class PreviewPanel extends StatefulWidget {
  const PreviewPanel(
      {super.key,
      required this.bucket,
      required this.keyName,
      required this.service});

  final String bucket;
  final String keyName;
  final PreviewService service;

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  Future<PreviewResult>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.preview(widget.bucket, widget.keyName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PreviewResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Text('無法載入預覽');
        }
        final result = snapshot.data!;
        if (result.error != null) {
          return Text('預覽失敗: ${result.error}');
        }
        switch (result.type) {
          case PreviewType.text:
            return SingleChildScrollView(child: Text(result.text ?? ''));
          case PreviewType.image:
            return Image.memory(result.bytes!);
          case PreviewType.unsupported:
            return Text('不支援的格式 (${result.contentType})');
        }
      },
    );
  }
}

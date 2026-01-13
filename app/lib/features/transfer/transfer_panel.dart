import 'package:app/services/transfer_queue.dart';
import 'package:app/models/entities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransferPanel extends StatelessWidget {
  const TransferPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<TransferQueue>();
    final tasks = queue.tasks;
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: const Text('目前沒有傳輸任務'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('傳輸佇列'),
          const SizedBox(height: 8),
          ...tasks.map((t) {
            final progress = t.progress.totalBytes == 0 ? null : (t.progress.bytesTransferred / t.progress.totalBytes).clamp(0.0, 1.0).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(t.type.name.toUpperCase())),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(t.status.name),
                  IconButton(
                    icon: Icon(t.status == TransferStatus.paused ? Icons.play_arrow : Icons.pause),
                    tooltip: t.status == TransferStatus.paused ? '繼續' : '暫停',
                    onPressed: () {
                      if (t.status == TransferStatus.paused) {
                        queue.resume(t.id);
                      } else {
                        queue.pause(t.id);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    tooltip: '取消',
                    onPressed: () => queue.cancel(t.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

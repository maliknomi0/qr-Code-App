import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';

class GenerateScreen extends ConsumerWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateVmProvider);
    final notifier = ref.watch(generateVmProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Data',
                hintText: 'Enter URL, text or Wi-Fi config',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              onChanged: notifier.updateData,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _QrPreview(bytes: state.pngBytes),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.pngBytes == null ? null : notifier.saveToHistory,
                    icon: const Icon(Icons.save),
                    label: state.isSaving
                        ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save to history'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.pngBytes == null
                        ? null
                        : () async {
                            final path = await notifier.exportPng();
                            if (path != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved to $path')),
                              );
                            }
                          },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export PNG'),
                  ),
                ),
              ],
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error!.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.bytes});

  final List<int>? bytes;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return const Text('Enter data to preview a QR code.');
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.memory(
        Uint8List.fromList(bytes!),
        width: 220,
        height: 220,
        fit: BoxFit.contain,
      ),
    );
  }
}

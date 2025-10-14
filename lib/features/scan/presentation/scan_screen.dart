import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/di/providers.dart';
import '../../../core/error/app_error.dart';
import '../../../core/logging/logger.dart';
import '../../history/application/history_vm.dart';
import 'widgets/scan_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanVmProvider, (previous, next) {
      if (next.error != null) {
        _showError(context, next.error!);
      }
    });

    final state = ref.watch(scanVmProvider);
    final historyVm = ref.watch(historyVmProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await historyVm.load();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                builder: (context) => const _HistorySheet(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null) {
                ref.read(scanVmProvider.notifier).onRawDetection(barcode);
              }
            },
          ),
          const ScanOverlay(),
          if (state.isProcessing)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (state.lastItem != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                child: ListTile(
                  title: Text(state.lastItem!.data.value),
                  subtitle: Text('Saved at ${state.lastItem!.createdAt}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, AppError error) {
    final logger = ref.read(loggerProvider);
    logger.error('Scan error: ${error.message}', error.cause);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyVmProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Recent History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No items yet. Start scanning to build your history.'),
              )
            else
              ...state.items.take(5).map(
                    (item) => ListTile(
                      title: Text(item.data.value),
                      subtitle: Text(item.createdAt.toLocal().toString()),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

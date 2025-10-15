import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/di/providers.dart';
import '../../../core/error/app_error.dart';
import '../../../core/logging/logger.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';
import '../../history/application/history_vm.dart';
import '../application/scan_vm.dart';
import 'widgets/scan_overlay.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _torchOn = false;
  bool _usingFrontCamera = false;

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

    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan'),
            Text(
              'Align the code within the frame',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flashlight_on_outlined,
            ),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await _controller.toggleTorch();
              if (!mounted) return;
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            tooltip: 'Flip camera',
            icon: Icon(_usingFrontCamera ? Icons.camera_front_rounded : Icons.camera_rear_rounded),
            onPressed: () async {
              HapticFeedback.selectionClick();
              await _controller.switchCamera();
              if (!mounted) return;
              setState(() => _usingFrontCamera = !_usingFrontCamera);
            },
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await historyVm.load();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                backgroundColor: theme.colorScheme.surface,
                builder: (context) => const _HistorySheet(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null) {
                  ref.read(scanVmProvider.notifier).onRawDetection(barcode);
                }
              },
            ),
          ),
          const Positioned.fill(child: ScanOverlay()),
          Positioned(
            top: kToolbarHeight + MediaQuery.paddingOf(context).top + 24,
            left: 24,
            right: 24,
            child: _TipPill(theme: theme),
          ),
          if (state.isProcessing)
            const _CaptureIndicator(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(state: state),
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

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final item = state.lastItem;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.6),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, math.max(bottomPadding + 16, 32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Hold steady. We auto-save the result once detected.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: item == null
                ? _ScanPlaceholder(theme: theme)
                : _ScanResultCard(item: item, theme: theme),
          ),
        ],
      ),
    );
  }
}

class _ScanPlaceholder extends StatelessWidget {
  const _ScanPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.swipe_up_rounded, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'View the last five scans anytime via the history shortcut.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.item, required this.theme});

  final QrItem item;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = _labelForType(item.type);
    final timestamp = _formatTimestamp(context, item.createdAt);

    return Container(
      key: ValueKey(item.id.value),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForType(item.type), color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                timestamp,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.data.value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CaptureIndicator extends StatelessWidget {
  const _CaptureIndicator();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      bottom: bottom + 120,
      left: 0,
      right: 0,
      child: Column(
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Processing…',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TipPill extends StatelessWidget {
  const _TipPill({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Better contrast? Enable the torch from the toolbar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(historyVmProvider);
    final items = state.items.take(5).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent history',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nothing to show yet — scan a QR code and it will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForType(item.type),
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.data.value,
                              style: theme.textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(context, item.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _labelForType(QrType type) {
  switch (type) {
    case QrType.text:
      return 'Plain text';
    case QrType.url:
      return 'Website';
    case QrType.wifi:
      return 'Wi‑Fi network';
    case QrType.email:
      return 'Email address';
    case QrType.phone:
      return 'Phone number';
    case QrType.sms:
      return 'SMS shortcut';
    case QrType.vcard:
      return 'Contact card';
  }
}

IconData _iconForType(QrType type) {
  switch (type) {
    case QrType.text:
      return Icons.notes_rounded;
    case QrType.url:
      return Icons.public_rounded;
    case QrType.wifi:
      return Icons.wifi_rounded;
    case QrType.email:
      return Icons.alternate_email_rounded;
    case QrType.phone:
      return Icons.call_rounded;
    case QrType.sms:
      return Icons.sms_rounded;
    case QrType.vcard:
      return Icons.account_box_rounded;
  }
}

String _formatTimestamp(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  final time = TimeOfDay.fromDateTime(date).format(context);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (_isSameDay(now, date)) return 'Today · $time';
  if (_isSameDay(now.subtract(const Duration(days: 1)), date)) {
    return 'Yesterday · $time';
  }
  if (diff.inDays < 7) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[(date.weekday - 1) % names.length]} · $time';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day · $time';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

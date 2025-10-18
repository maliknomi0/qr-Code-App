import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code/core/utils/qr_parsers.dart';
import 'package:qr_code/domain/entities/qr_item.dart';
import 'package:qr_code/domain/entities/qr_source.dart';
import 'package:qr_code/features/scan/presentation/widgets/scan_result_sheet.dart';

import '../../../app/di/providers.dart';
import '../../../core/error/app_error.dart';
import '../../../core/logging/logger.dart';
import '../../../domain/entities/qr_type.dart';
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
  Widget build(BuildContext context) {
    ref.listen(scanVmProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showError(context, next.error!);
      }

      final previousId = previous?.lastItem?.id;
      final nextItem = next.lastItem;
      if (nextItem != null && nextItem.id != previousId) {
        final autoSaved = ref.read(settingsVmProvider).autoSaveScanned;
        _showResult(context, nextItem, autoSaved: autoSaved);
      }
    });

    final state = ref.watch(scanVmProvider);
    final historyVm = ref.watch(historyVmProvider.notifier);

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final overlayTextColor = isLight
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final overlaySubtleColor = overlayTextColor.withOpacity(
      isLight ? 0.72 : 0.75,
    );
    final headerBase = Color.alphaBlend(
      theme.colorScheme.scrim.withOpacity(isLight ? 0.25 : 0.4),
      theme.colorScheme.surface,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: overlayTextColor,
        iconTheme: IconThemeData(color: overlayTextColor),
        actionsIconTheme: IconThemeData(color: overlayTextColor),
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan'),
            Text(
              'Align the code within the frame',
              style: theme.textTheme.bodySmall?.copyWith(
                // Use a dark color in light theme for better readability.
                color: isLight ? Colors.black87 : overlaySubtleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [headerBase, theme.colorScheme.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
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
            icon: Icon(
              _usingFrontCamera
                  ? Icons.camera_front_rounded
                  : Icons.camera_rear_rounded,
            ),
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

          if (state.isProcessing) const _CaptureIndicator(),
        ],
      ),
    );
  }

  void _showError(BuildContext context, AppError error) {
    final logger = ref.read(loggerProvider);
    logger.error('Scan error: ${error.message}', error.cause);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }

  void _showResult(
    BuildContext context,
    QrItem item, {
    required bool autoSaved,
  }) {
    unawaited(_controller.stop());
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (context) => ScanResultSheet(
        item: item,
        autoSaved: autoSaved,
        onSave: autoSaved
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                final messenger = ScaffoldMessenger.of(context);
                final error = await ref
                    .read(scanVmProvider.notifier)
                    .saveItem(item);
                if (!context.mounted) return;
                if (error != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Saved to history.')),
                  );
                }
              },
      ),
    ).whenComplete(() {
      if (!mounted) return;
      _controller.start();
    });
  }
}

class _CaptureIndicator extends StatelessWidget {
  const _CaptureIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final subtleColor =
        (isLight ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)
            .withOpacity(isLight ? 0.72 : 0.75);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      bottom: bottom + 120,
      left: 0,
      right: 0,
      child: Column(
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Processing…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subtleColor,
              fontWeight: FontWeight.w600,
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          32 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent history',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
                  child: _HistorySheetItem(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySheetItem extends StatelessWidget {
  const _HistorySheetItem({required this.item});

  final QrItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summaryForItem(item);
    final iconColor = theme.colorScheme.primary;
    final chips = <Widget>[
      _HistorySheetChip(label: _formatTimestamp(context, item.createdAt)),
      _HistorySheetChip(
        label: _sourceLabel(item.source),
        icon: _iconForSource(item.source),
      ),
      if (item.isFavorite)
        const _HistorySheetChip(
          label: 'Pinned',
          icon: Icons.push_pin_rounded,
        ),
      _HistorySheetChip(
        label: item.id.value.substring(0, 8),
        icon: Icons.fingerprint_rounded,
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: iconColor.withOpacity(0.12),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelForType(item.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              // ),
              IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded),
                  color: iconColor,
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: item.data.value),
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard.'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySheetChip extends StatelessWidget {
  const _HistorySheetChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

String _summaryForItem(QrItem item) {
  final wifi = item.type == QrType.wifi ? parseWifi(item.data.value) : null;
  final email = item.type == QrType.email ? parseEmail(item.data.value) : null;
  final sms = item.type == QrType.sms ? parseSms(item.data.value) : null;
  return wifi?.ssid ?? email?.to ?? sms?.phoneNumber ?? item.data.value;
}

String _sourceLabel(QrSource source) {
  switch (source) {
    case QrSource.generated:
      return 'Generated';
    case QrSource.scanned:
      return 'Scanned';
    case QrSource.unknown:
      return 'Uncategorized';
  }
}

IconData _iconForSource(QrSource source) {
  switch (source) {
    case QrSource.generated:
      return Icons.qr_code_2_rounded;
    case QrSource.scanned:
      return Icons.document_scanner_rounded;
    case QrSource.unknown:
      return Icons.help_outline_rounded;
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

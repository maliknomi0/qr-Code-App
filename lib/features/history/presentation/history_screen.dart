import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code/domain/entities/qr_source.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di/providers.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';

enum _HistoryFilter { all, generated, scanned }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    Future.microtask(() => ref.read(historyVmProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyVmProvider);
    final notifier = ref.watch(historyVmProvider.notifier);
    final theme = Theme.of(context);
    final sourceFilter = switch (_filter) {
      _HistoryFilter.all => null,
      _HistoryFilter.generated => QrSource.generated,
      _HistoryFilter.scanned => QrSource.scanned,
    };

    final normalizedQuery = _query.trim().toLowerCase();
    final filteredItems = state.items.where((item) {
      if (sourceFilter != null && item.source != sourceFilter) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      final value = item.data.value.toLowerCase();
      final typeLabel = _labelForType(item.type).toLowerCase();
      final sourceLabel = _sourceLabel(item.source).toLowerCase();
      final idMatch = item.id.value.toLowerCase().contains(normalizedQuery);
      return value.contains(normalizedQuery) ||
          typeLabel.contains(normalizedQuery) ||
          sourceLabel.contains(normalizedQuery) ||
          idMatch;
    }).toList();

    final totalCount = state.items.length;
    final filteredCount = filteredItems.length;
    final isFiltered =
        _filter != _HistoryFilter.all || normalizedQuery.isNotEmpty;
    final subtitle = totalCount == 0
        ? 'Codes you create or scan live here'
        : isFiltered
        ? '$filteredCount of $totalCount saved QR ${filteredCount == 1 ? 'code' : 'codes'}'
        : '$totalCount saved QR ${totalCount == 1 ? 'code' : 'codes'}';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History'),
            const SizedBox(height: 2),
            Text(
              subtitle,

              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Export as PDF',
              onPressed: state.items.isEmpty
                  ? null
                  : () async {
                      HapticFeedback.selectionClick();
                      final path = await notifier.exportPdf();
                      if (path != null && context.mounted) {
                        await Share.shareXFiles([
                          XFile(
                            path,
                            mimeType: 'application/pdf',
                            name: 'qr_history.pdf',
                          ),
                        ]);
                      }
                    },
              icon: const Icon(Icons.picture_as_pdf_rounded),
            ),
          ),
        ],
        flexibleSpace: _GradientAppBarBackground(
          color: theme.colorScheme.primary,
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator.adaptive(
          onRefresh: notifier.load,
          displacement: 90,
          edgeOffset: 16,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              if (state.error != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorBanner(message: state.error!.message),
                  ),
                ),
              if (!state.isLoading && (state.items.isNotEmpty || isFiltered))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _SearchAndFilterBar(
                      controller: _searchController,
                      query: _query,
                      filter: _filter,
                      onQueryChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      onFilterChanged: (value) {
                        setState(() {
                          _filter = value;
                        });
                      },
                    ),
                  ),
                ),
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingPlaceholder(),
                )
              else if (state.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoResults(
                    onClear: () {
                      setState(() {
                        _query = '';
                        _filter = _HistoryFilter.all;
                        _searchController.clear();
                      });
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final position = state.items.indexWhere(
                        (element) => element.id == item.id,
                      );
                      final displayIndex = position == -1 ? index : position;
                      return _HistoryCard(
                        item: item,
                        index: displayIndex,
                        onFavorite: () =>
                            notifier.toggleFavorite(item.id.value),
                        onDelete: () => notifier.delete(item.id.value),
                        onCopy: (ctx) async {
                          HapticFeedback.selectionClick();
                          await Clipboard.setData(
                            ClipboardData(text: item.data.value),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard.'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          notifier.load();
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ),
    );
  }
}

class _GradientAppBarBackground extends StatelessWidget {
  const _GradientAppBarBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.errorContainer,
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String query;
  final _HistoryFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_HistoryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          controller: controller,
          hintText: 'Search history',
          leading: const Icon(Icons.search_rounded),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: onQueryChanged,
          trailing: query.isEmpty
              ? null
              : [
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<_HistoryFilter>(
          segments: const [
            ButtonSegment(
              value: _HistoryFilter.all,
              label: Text('All'),
              icon: Icon(Icons.history_rounded),
            ),
            ButtonSegment(
              value: _HistoryFilter.generated,
              label: Text('Generated'),
              icon: Icon(Icons.qr_code_2_rounded),
            ),
            ButtonSegment(
              value: _HistoryFilter.scanned,
              label: Text('Scanned'),
              icon: Icon(Icons.document_scanner_rounded),
            ),
          ],
          selected: <_HistoryFilter>{filter},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            onFilterChanged(selection.first);
          },
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ),
            child: Icon(
              Icons.filter_alt_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('No matches found', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            'Try a different search term or reset your filters to see everything again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.index,
    required this.onFavorite,
    required this.onDelete,
    required this.onCopy,
  });

  final QrItem item;
  final int index;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final Future<void> Function(BuildContext) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = item.type;
    final icon = _iconForType(type);
    final accent = theme.colorScheme.secondaryContainer;

    return Dismissible(
      key: ValueKey(item.id.value),
      background: _DismissBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.star_rounded,
        label: item.isFavorite ? 'Unfavorite' : 'Favorite',
        color: theme.colorScheme.primary,
      ),
      secondaryBackground: _DismissBackground(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        label: 'Delete',
        color: theme.colorScheme.error,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          onFavorite();
          return false;
        }
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog.adaptive(
                title: const Text('Delete QR?'),
                content: const Text(
                  'This action removes the item from your history.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
        if (confirmed) {
          HapticFeedback.mediumImpact();
          onDelete();
        }
        return confirmed;
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: () {
            HapticFeedback.selectionClick();
            _showActionsSheet(context, onCopy);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.2),
                            accent.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForType(type),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.data.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Copy data',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                unawaited(onCopy(context));
                              },
                              icon: const Icon(Icons.copy_rounded),
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            IconButton(
                              tooltip: item.isFavorite
                                  ? 'Remove favorite'
                                  : 'Add to favorites',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onFavorite();
                              },
                              icon: Icon(
                                item.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                              ),
                              color: item.isFavorite
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: _formatTimestamp(context, item.createdAt)),
                    _Chip(label: _formatTimestamp(context, item.createdAt)),
                    _Chip(
                      label: _sourceLabel(item.source),
                      icon: _iconForSource(item.source),
                    ),
                    if (item.isFavorite)
                      _Chip(label: 'Pinned', icon: Icons.push_pin_rounded),
                    _Chip(
                      label: item.id.value.substring(0, 8),
                      icon: Icons.fingerprint_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsSheet(
    BuildContext context,
    Future<void> Function(BuildContext) onCopy,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick actions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.copy_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Copy data'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await onCopy(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    item.isFavorite ? 'Unfavorite' : 'Add to favorites',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onFavorite();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirmed =
                        await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog.adaptive(
                            title: const Text('Delete QR?'),
                            content: const Text(
                              'This action removes the item from your history.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (confirmed) {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

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

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignment,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
                stops: const [0.4, 1],
              ),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your timeline is waiting',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Generate or scan a QR code to start tracking it in history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  final time = TimeOfDay.fromDateTime(date).format(context);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (_isSameDay(now, date)) {
    return 'Today · $time';
  }

  if (_isSameDay(now.subtract(const Duration(days: 1)), date)) {
    return 'Yesterday · $time';
  }

  if (difference.inDays < 7) {
    return '${_weekdayName(date.weekday)} · $time';
  }

  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day · $time';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekdayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[(weekday - 1) % names.length];
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

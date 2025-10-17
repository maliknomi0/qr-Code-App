import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/di/providers.dart';
import '../../../domain/entities/qr_customization.dart';
import '../application/generate_vm.dart';

/// Mobile-first redesign for the QR generator screen.
///
/// Drop-in replacement; uses the same GenerateState / GenerateVm.
/// Focus: clearer hierarchy, bigger tap targets, sticky bottom actions.
class GenerateScreen extends ConsumerWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateVmProvider);
    final notifier = ref.watch(generateVmProvider.notifier);
    final theme = Theme.of(context);

    final canShare = state.pngBytes != null || state.data.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Design QR Code'),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Save',
              onPressed: state.pngBytes == null
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final path = await notifier.saveToHistory();
                      if (!context.mounted) return;
                      final error = notifier.state.error;
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                        return;
                      }
                      final message = path != null && path.isNotEmpty
                          ? 'Saved to history & gallery'
                          : 'Saved to history';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    },
              icon: const Icon(Icons.bookmark_add_outlined),
            ),

          // Share
          IconButton(
            tooltip: 'Share',
            onPressed: canShare
                ? () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet<void>(
                      context: context,
                      useSafeArea: true,
                      showDragHandle: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      builder: (context) => _ShareSheet(state: state),
                    );
                  }
                : null,
            icon: const Icon(Icons.share_rounded),
          ),

          // Export PNG
          IconButton(
            tooltip: 'Export PNG',
            onPressed: state.pngBytes == null
                ? null
                : () async {
                    HapticFeedback.lightImpact();
                    final path = await notifier.exportPng();
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Saved to $path')));
                    }
                  },
            icon: const Icon(Icons.ios_share),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  _PreviewCard(state: state),
                  const SizedBox(height: 16),
                  _ContentCard(
                    initial: state.data,
                    tags: state.tags,
                    maxTags: GenerateVm.maxTags,
                    onChanged: notifier.updateData,
                    onAddTag: notifier.addTag,
                    onRemoveTag: notifier.removeTag,
                    onClearTags: notifier.clearTags,
                  ),
                  const SizedBox(height: 16),
                  _BrandingCard(state: state, notifier: notifier),
                  const SizedBox(height: 16),
                  _AppearanceCard(state: state, notifier: notifier),
                  const SizedBox(height: 24),
                  if (state.error != null)
                    _ErrorBanner(message: state.error!.message),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),

      // ⛔️ Removed bottom bar
      // bottomNavigationBar: _BottomActions(state: state, notifier: notifier),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.state});
  final GenerateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = state.backgroundColor;
    final fg = state.foregroundColor;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [bg.withOpacity(0.92), bg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    color: theme.colorScheme.shadow.withOpacity(
                      theme.brightness == Brightness.light ? 0.16 : 0.6,
                    ),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state.pngBytes == null
                      ? _EmptyPreview(foregroundColor: fg, compact: true)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ColoredBox(
                            color: bg,
                            child: Image.memory(
                              Uint8List.fromList(state.pngBytes!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.pngBytes == null
                  ? 'Start typing to see a live preview.'
                  : 'Looks great! Save it or export a high-quality PNG.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatefulWidget {
  const _ContentCard({
    this.initial,
    required this.onChanged,
    required this.tags,
    required this.maxTags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onClearTags,
  });
  final String? initial;
  final ValueChanged<String> onChanged;
  final List<String> tags;
  final int maxTags;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onClearTags;

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial ?? '',
  );
  late final TextEditingController _tagCtrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _handleTagSubmit([String? value]) {
    final rawValue = value ?? _tagCtrl.text;
    var remaining = widget.maxTags - widget.tags.length;
    if (remaining <= 0) {
      _showTagLimitMessage();
      _tagCtrl.clear();
      return;
    }

    final parts = rawValue.split(RegExp(r'[;,]'));
    var added = false;
    var limitHit = false;
    for (final part in parts) {
      final normalized = part.trim();
      if (normalized.isEmpty) continue;
      if (remaining <= 0) {
        limitHit = true;
        break;
      }
      widget.onAddTag(normalized);
      remaining--;
      added = true;
    }
    if (added) {
      HapticFeedback.selectionClick();
    }
    if (limitHit) {
      _showTagLimitMessage();
    }
    _tagCtrl.clear();
  }

  void _showTagLimitMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You can add up to ${widget.maxTags} tags per QR code.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = widget.tags.length < widget.maxTags;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.text_fields, title: 'QR Content'),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Enter URL, text, Wi-Fi config, or contact card',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                widget.onChanged(v);
              },
            ),
            const SizedBox(height: 16),
            Text('Tags (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              'Add short keywords to group and filter saved QR codes later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.tags.isEmpty
                  ? Container(
                      key: const ValueKey('tag-empty'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sell_outlined,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No tags yet — add your first one below.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      key: const ValueKey('tag-list'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in widget.tags)
                          InputChip(
                            label: Text(tag),
                            onDeleted: () {
                              HapticFeedback.selectionClick();
                              widget.onRemoveTag(tag);
                            },
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    enabled: canAddMore,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.sell_outlined),
                      hintText: canAddMore
                          ? 'Type a tag and press enter'
                          : 'Tag limit reached',
                    ),
                    onSubmitted: _handleTagSubmit,
                    onChanged: (value) {
                      if (value.contains(',') || value.contains(';')) {
                        _handleTagSubmit(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: canAddMore ? () => _handleTagSubmit() : null,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onClearTags();
                  },
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear tags'),
                ),
              ),
            ],
            if (!canAddMore)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You can add up to ${widget.maxTags} tags.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandingCard extends StatelessWidget {
  const _BrandingCard({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLogo = state.logoBytes != null;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.badge_outlined, title: 'Branding'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 460;
                final preview = SizedBox(
                  width: isWide ? 160 : double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: hasLogo
                        ? _LogoLoadedPreview(
                            key: const ValueKey('logo-preview'),
                            bytes: state.logoBytes!,
                            fileName: state.logoFileName,
                            onRemove: () {
                              HapticFeedback.selectionClick();
                              notifier.updateLogo(null);
                            },
                          )
                        : const _LogoEmptyPreview(
                            key: ValueKey('logo-placeholder'),
                          ),
                  ),
                );

                final controls = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _pickLogo(context, notifier),
                        icon: Icon(
                          hasLogo
                              ? Icons.autorenew_rounded
                              : Icons.add_photo_alternate_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            hasLogo ? 'Replace logo' : 'Upload logo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Transparent PNGs or SVG exports work best.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasLogo) ...[
                      const SizedBox(height: 16),
                      Text('Logo size', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      _LogoSizeSlider(
                        value: state.logoScale,
                        onChanged: (value) =>
                            notifier.updateLogoScale(value, regenerate: false),
                        onChangeEnd: (value) =>
                            notifier.updateLogoScale(value, regenerate: true),
                      ),
                      Text(
                        '${(state.logoScale * 100).round()}% of the QR width',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      preview,
                      const SizedBox(width: 20),
                      Expanded(child: controls),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    preview,
                    const SizedBox(height: 16),
                    controls,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = theme.textTheme.labelLarge;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.brush_outlined, title: 'Appearance'),

            // Colors
            const SizedBox(height: 12),
            Text('QR color', style: label),
            const SizedBox(height: 8),
            _ColorPreviewRow(
              color: state.foregroundColor,
              onPick: () async {
                final color = await _showColorPicker(
                  context,
                  state.foregroundColor,
                );
                if (color != null) notifier.updateForegroundColor(color);
              },
            ),
            const SizedBox(height: 16),
            Text('Background', style: label),
            const SizedBox(height: 8),
            _ColorPreviewRow(
              color: state.backgroundColor,
              onPick: () async {
                final color = await _showColorPicker(
                  context,
                  state.backgroundColor,
                );
                if (color != null) notifier.updateBackgroundColor(color);
              },
            ),

            // Design + error correction
            const SizedBox(height: 16),
            Text('Design style', style: label),
            const SizedBox(height: 8),
            _EnumDropdown<QrDesign>(
              value: state.design,
              hint: 'Choose design',
              onChanged: (v) => notifier.updateDesign(v),
              items: QrDesign.values.map((design) {
                return DropdownMenuItem<QrDesign>(
                  value: design,
                  child: Row(
                    children: [
                      Icon(_iconForDesign(design)),
                      const SizedBox(width: 8),
                      Text(_labelForDesign(design)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick a module style that matches your vibe.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('Error correction', style: label),
            const SizedBox(height: 8),
            _EnumDropdown<QrErrorCorrection>(
              value: state.errorCorrection,
              hint: 'Choose level',
              onChanged: (v) => notifier.updateErrorCorrection(v),
              items: QrErrorCorrection.values.map((level) {
                return DropdownMenuItem<QrErrorCorrection>(
                  value: level,
                  child: Row(
                    children: [
                      Icon(_iconForCorrection(level)),
                      const SizedBox(width: 8),
                      Text(_labelForCorrection(level)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              'Higher levels make codes more resilient to damage but denser.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Export size + gapless
            const SizedBox(height: 16),
            Text('Export size', style: label),
            const SizedBox(height: 4),
            _SizeSlider(
              value: state.pixelSize.clamp(512, 2048).toDouble(),
              onChanged: (v) => notifier.updatePixelSize(v, regenerate: false),
              onChangeEnd: (v) => notifier.updatePixelSize(v, regenerate: true),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Current: ${state.pixelSize.round()} px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.gapless,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                notifier.updateGapless(v);
              },
              title: const Text('Gapless mode'),
              subtitle: const Text(
                'Remove spacing between modules for a crisp look',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.state});

  final GenerateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final data = state.data.trim();
    final hasData = data.isNotEmpty;
    final hasImage = state.pngBytes != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share & collaborate',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send your QR or its contents directly to other apps.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24, height: 8),
            ListTile(
              leading: Icon(
                Icons.image_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Share QR image'),
              subtitle: const Text('Send the generated PNG to chats or email'),
              enabled: hasImage,
              onTap: hasImage
                  ? () async {
                      HapticFeedback.lightImpact();
                      navigator.pop();
                      final pngBytes = state.pngBytes!;
                      final file = XFile.fromData(
                        Uint8List.fromList(pngBytes),
                        mimeType: 'image/png',
                        name: 'qr-code.png',
                      );
                      await Share.shareXFiles(
                        [file],
                        text: hasData ? data : null,
                        subject: 'QR code',
                      );
                    }
                  : null,
            ),
            ListTile(
              leading: Icon(
                Icons.notes_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Share content as text'),
              subtitle: const Text('Send the raw link or message'),
              enabled: hasData,
              onTap: hasData
                  ? () async {
                      HapticFeedback.lightImpact();
                      navigator.pop();
                      await Share.share(data, subject: 'QR code content');
                    }
                  : null,
            ),
            ListTile(
              leading: Icon(
                Icons.copy_all_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Copy content'),
              subtitle: const Text('Copy to clipboard for quick reuse'),
              enabled: hasData,
              onTap: hasData
                  ? () async {
                      HapticFeedback.lightImpact();
                      navigator.pop();
                      await Clipboard.setData(ClipboardData(text: data));
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ColorPreviewRow extends StatelessWidget {
  const _ColorPreviewRow({required this.color, required this.onPick});

  final Color color;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outline),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Selected: ${_hex(color)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onPick,
          icon: const Icon(Icons.colorize),
          label: const Text('Color picker'),
        ),
      ],
    );
  }
}

Future<Color?> _showColorPicker(BuildContext context, Color initialColor) {
  return showDialog<Color>(
    context: context,
    builder: (context) {
      var currentColor = initialColor;

      return AlertDialog(
        title: const Text('Pick a color'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (color) => setState(() => currentColor = color),
                enableAlpha: true,
                displayThumbColor: true,
                portraitOnly: true,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(currentColor),
            child: const Text('Select'),
          ),
        ],
      );
    },
  );
}

class _SizeSlider extends StatelessWidget {
  const _SizeSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        valueIndicatorTextStyle: Theme.of(context).textTheme.labelSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Slider(
            value: value,
            min: 512,
            max: 2048,
            divisions: 6,
            label: '${value.round()} px',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('512'),
              Text('1024'),
              Text('1536'),
              Text('2048'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoSizeSlider extends StatelessWidget {
  const _LogoSizeSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.12, 0.32);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: normalized,
        min: 0.12,
        max: 0.32,
        divisions: 10,
        label: '${(normalized * 100).round()}%',
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

class _LogoLoadedPreview extends StatelessWidget {
  const _LogoLoadedPreview({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String? fileName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName ?? 'Custom logo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed at the centre of your QR code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove logo',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _LogoEmptyPreview extends StatelessWidget {
  const _LogoEmptyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 36,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'No logo selected',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a PNG or JPG to brand your QR.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.foregroundColor, this.compact = false});

  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        ThemeData.estimateBrightnessForColor(foregroundColor) ==
            Brightness.light
        ? theme.colorScheme.primary
        : foregroundColor;
    return Center(
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 72,
            color: effectiveColor.withOpacity(0.8),
          ),
          const SizedBox(height: 8),
          Text(
            'Your QR preview will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Dropdown helper used to replace SegmentedButton ----------
class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      isExpanded: true,
      hint: hint == null ? null : Text(hint!),
      onChanged: (v) {
        if (v == null) return;
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ---------- Label/Icon helpers for enums ----------
String _labelForDesign(QrDesign design) {
  switch (design) {
    case QrDesign.classic:
      return 'Classic';
    case QrDesign.roundedEyes:
      return 'Rounded eyes';
    case QrDesign.roundedModules:
      return 'Rounded modules';
    case QrDesign.roundedAll:
      return 'Fully rounded';
  }
}

IconData _iconForDesign(QrDesign design) {
  switch (design) {
    case QrDesign.classic:
      return Icons.grid_view;
    case QrDesign.roundedEyes:
      return Icons.center_focus_weak;
    case QrDesign.roundedModules:
      return Icons.blur_circular;
    case QrDesign.roundedAll:
      return Icons.bubble_chart;
  }
}

String _labelForCorrection(QrErrorCorrection level) {
  switch (level) {
    case QrErrorCorrection.low:
      return 'Low';
    case QrErrorCorrection.medium:
      return 'Medium';
    case QrErrorCorrection.quartile:
      return 'Quartile';
    case QrErrorCorrection.high:
      return 'High';
  }
}

IconData _iconForCorrection(QrErrorCorrection level) {
  switch (level) {
    case QrErrorCorrection.low:
      return Icons.bolt_outlined;
    case QrErrorCorrection.medium:
      return Icons.shield_moon_outlined;
    case QrErrorCorrection.quartile:
      return Icons.shield_outlined;
    case QrErrorCorrection.high:
      return Icons.security_outlined;
  }
}

/// Helpers
String _hex(Color c) =>
    '#${c.alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}'
    '${c.red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
    '${c.green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
    '${c.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';

Color? _tryParseHex(String input) {
  var hex = input.trim();
  if (!hex.startsWith('#')) hex = '#$hex';
  // #RRGGBB or #AARRGGBB
  if (hex.length == 7) {
    final r = int.parse(hex.substring(1, 3), radix: 16);
    final g = int.parse(hex.substring(3, 5), radix: 16);
    final b = int.parse(hex.substring(5, 7), radix: 16);
    return Color.fromARGB(0xFF, r, g, b);
  } else if (hex.length == 9) {
    final a = int.parse(hex.substring(1, 3), radix: 16);
    final r = int.parse(hex.substring(3, 5), radix: 16);
    final g = int.parse(hex.substring(5, 7), radix: 16);
    final b = int.parse(hex.substring(7, 9), radix: 16);
    return Color.fromARGB(a, r, g, b);
  }
  return null;
}

// ---------- Logo picker (now used inside Appearance) ----------
Future<void> _pickLogo(BuildContext context, GenerateVm notifier) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to read the selected file.')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    await notifier.updateLogo(Uint8List.fromList(bytes), fileName: file.name);
  } catch (error) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Image selection failed.')),
    );
  }
}

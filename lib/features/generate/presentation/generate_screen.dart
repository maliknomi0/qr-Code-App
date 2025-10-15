import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(
                children: [
                  _HeaderBlurb(),
                  const SizedBox(height: 12),
                  _PreviewCard(state: state),
                  const SizedBox(height: 16),
                  _ContentCard(
                    initial: state.data,
                    onChanged: notifier.updateData,
                  ),
                  const SizedBox(height: 16),
                  _AppearanceCard(state: state, notifier: notifier),
                  const SizedBox(height: 24),
                  if (state.error != null)
                    _ErrorBanner(message: state.error!.message),
                  const SizedBox(height: 64), // spacer for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(state: state, notifier: notifier),
    );
  }
}

class _HeaderBlurb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Craft a scannable experience—enter content and tailor the style.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    color: Colors.black12,
                    offset: Offset(0, 10),
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
  const _ContentCard({this.initial, required this.onChanged});
  final String? initial;
  final ValueChanged<String> onChanged;

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                labelText: 'Data',
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _PresetChip(
                  label: 'URL',
                  onTap: () => _applyPreset('https://example.com'),
                ),
                _PresetChip(
                  label: 'Text',
                  onTap: () => _applyPreset('Hello from QR ✨'),
                ),
                _PresetChip(
                  label: 'Wi-Fi',
                  onTap: () => _applyPreset('WIFI:T:WPA;S:MyWiFi;P:password;;'),
                ),
                _PresetChip(
                  label: 'vCard',
                  onTap: () => _applyPreset(
                    'BEGIN:VCARD\nVERSION:3.0\nN:Doe;Jane;;;\nTEL;CELL:+123456789\nEMAIL:jane@example.com\nEND:VCARD',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(String value) {
    _ctrl.text = value;
    _ctrl.selection = TextSelection.collapsed(offset: value.length);
    HapticFeedback.lightImpact();
    widget.onChanged(value);
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
            const SizedBox(height: 12),
            Text('QR color', style: label),
            const SizedBox(height: 8),
            _SwatchGrid(
              colors: _Palette.colors,
              selectedColor: state.foregroundColor,
              onSelect: (c) => notifier.updateForegroundColor(c),
            ),
            _HexField(
              initial: _hex(state.foregroundColor),
              onSubmitted: (hex) {
                final c = _tryParseHex(hex);
                if (c != null) notifier.updateForegroundColor(c);
              },
            ),
            const SizedBox(height: 16),
            Text('Background', style: label),
            const SizedBox(height: 8),
            _SwatchGrid(
              colors: _Palette.backgrounds,
              selectedColor: state.backgroundColor,
              onSelect: (c) => notifier.updateBackgroundColor(c),
            ),
            _HexField(
              initial: _hex(state.backgroundColor),
              onSubmitted: (hex) {
                final c = _tryParseHex(hex);
                if (c != null) notifier.updateBackgroundColor(c);
              },
            ),
            const SizedBox(height: 16),
            Text('Error correction', style: label),
            const SizedBox(height: 8),
            SegmentedButton<QrErrorCorrection>(
              segments: QrErrorCorrection.values
                  .map(
                    (level) => ButtonSegment(
                      value: level,
                      label: Text(_labelForCorrection(level)),
                      icon: Icon(_iconForCorrection(level)),
                    ),
                  )
                  .toList(),
              selected: {state.errorCorrection},
              onSelectionChanged: (v) {
                HapticFeedback.selectionClick();
                notifier.updateErrorCorrection(v.first);
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Higher levels make codes more resilient to damage but denser.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    final canShare = state.pngBytes != null || state.data.trim().isNotEmpty;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
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
              icon: state.isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(state.isSaving ? 'Saving…' : 'Save'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: canShare
                  ? () {
                      HapticFeedback.selectionClick();
                      _showShareSheet(context, state);
                    }
                  : null,
              icon: const Icon(Icons.share_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Share'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.pngBytes == null
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      final path = await notifier.exportPng();
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Saved to $path')),
                        );
                      }
                    },
              icon: const Icon(Icons.ios_share),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Export PNG'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, GenerateState state) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _ShareSheet(state: state),
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

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({
    required this.colors,
    required this.selectedColor,
    required this.onSelect,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors
          .map(
            (c) => _ColorSwatch(
              color: c,
              isSelected: selectedColor.value == c.value,
              onTap: () => onSelect(c),
            ),
          )
          .toList(),
    );
  }
}

class _HexField extends StatefulWidget {
  const _HexField({required this.initial, required this.onSubmitted});
  final String initial;
  final ValueChanged<String> onSubmitted;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final TextEditingController _hexCtrl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _hexCtrl,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'HEX',
          hintText: '#000000',
          prefixIcon: const Icon(Icons.palette_outlined),
          helperText: 'Enter color as #RRGGBB or #AARRGGBB',
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
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

/// Swatches & palette — kept from your original, just bigger tap targets.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;
    final iconColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: isSelected ? Icon(Icons.check, color: iconColor) : null,
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.add, size: 16),
      onPressed: onTap,
    );
  }
}

class _Palette {
  static const List<Color> colors = [
    Color(0xFF111827),
    Color(0xFF1D4ED8),
    Color(0xFF059669),
    Color(0xFFCA8A04),
    Color(0xFFBE123C),
    Color(0xFF7C3AED),
  ];

  static const List<Color> backgrounds = [
    Color(0xFFFFFFFF),
    Color(0xFFF9FAFB),
    Color(0xFFF1F5F9),
    Color(0xFFFFF7ED),
    Color(0xFFFDE68A),
    Color(0xFF111827),
  ];
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

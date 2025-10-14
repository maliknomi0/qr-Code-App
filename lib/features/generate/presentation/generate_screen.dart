import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../application/generate_vm.dart';
import '../../../domain/entities/qr_customization.dart';

class GenerateScreen extends ConsumerWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateVmProvider);
    final notifier = ref.watch(generateVmProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Design QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _GenerationPanel(
                            state: state,
                            notifier: notifier,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _PreviewPanel(
                            state: state,
                            notifier: notifier,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PreviewPanel(
                          state: state,
                          notifier: notifier,
                        ),
                        const SizedBox(height: 24),
                        _GenerationPanel(
                          state: state,
                          notifier: notifier,
                        ),
                      ],
                    );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GenerationPanel extends StatelessWidget {
  const _GenerationPanel({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Craft a scannable experience', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Enter the content and tailor the appearance of your QR code to match your brand or personal style.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QR Content', style: titleStyle),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    hintText: 'Enter URL, text, Wi-Fi config or contact card',
                  ),
                  minLines: 3,
                  maxLines: 6,
                  onChanged: notifier.updateData,
                ),
                const SizedBox(height: 20),
                Text('Customization', style: titleStyle),
                const SizedBox(height: 12),
                Text('QR color', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _Palette.colors
                      .map(
                        (color) => _ColorSwatch(
                          color: color,
                          isSelected: state.foregroundColor.value == color.value,
                          onTap: () {
                            notifier.updateForegroundColor(color);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text('Background', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _Palette.backgrounds
                      .map(
                        (color) => _ColorSwatch(
                          color: color,
                          isSelected: state.backgroundColor.value == color.value,
                          onTap: () {
                            notifier.updateBackgroundColor(color);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text('Error correction', style: theme.textTheme.labelLarge),
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
                  onSelectionChanged: (values) {
                    notifier.updateErrorCorrection(values.first);
                  },
                ),
                const SizedBox(height: 20),
                Text('Export size', style: theme.textTheme.labelLarge),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: state.pixelSize.clamp(512, 2048).toDouble(),
                    min: 512,
                    max: 2048,
                    divisions: 6,
                    label: '${state.pixelSize.round()} px',
                    onChanged: (value) => notifier.updatePixelSize(value, regenerate: false),
                    onChangeEnd: (value) => notifier.updatePixelSize(value, regenerate: true),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Higher values create sharper exports. Current: ${state.pixelSize.round()} px',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.gapless,
                  onChanged: (value) {
                    notifier.updateGapless(value);
                  },
                  title: const Text('Gapless mode'),
                  subtitle: const Text('Remove spacing between modules for a crisp look'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ActionButtons(state: state, notifier: notifier),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _QrPreview(
                  bytes: state.pngBytes,
                  backgroundColor: state.backgroundColor,
                  foregroundColor: state.foregroundColor,
                ),
                const SizedBox(height: 20),
                Text(
                  state.pngBytes == null
                      ? 'Start typing to see a live preview of your QR code.'
                      : 'Looks great! Save it to your history or export a high-quality PNG.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: state.pngBytes == null
                ? null
                : () {
                    notifier.saveToHistory();
                  },
            icon: state.isSaving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(state.isSaving ? 'Saving…' : 'Save to history'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
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
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Export PNG'),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({
    required this.bytes,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final List<int>? bytes;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            backgroundColor.withOpacity(0.9),
            backgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 24, color: Colors.black12, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: bytes == null
              ? _EmptyPreview(foregroundColor: foregroundColor)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: backgroundColor,
                    child: Image.memory(
                      Uint8List.fromList(bytes!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.foregroundColor});

  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = ThemeData.estimateBrightnessForColor(foregroundColor) == Brightness.light
        ? theme.colorScheme.primary
        : foregroundColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2, size: 72, color: effectiveColor.withOpacity(0.8)),
          const SizedBox(height: 12),
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
    final borderColor = isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final iconColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
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
        child: isSelected
            ? Icon(
                Icons.check,
                color: iconColor,
              )
            : null,
      ),
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

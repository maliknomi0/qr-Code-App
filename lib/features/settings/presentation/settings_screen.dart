import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../app/theme/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsVmProvider);
    final notifier = ref.read(settingsVmProvider.notifier);
    final themeMode = ref.watch(themeControllerProvider);
    final themeController = ref.read(themeControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings'),
            const SizedBox(height: 2),
            Text(
              'Tailor the experience to your workflow',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.18),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + kToolbarHeight + 12, 16, 32),
          children: [
            _HeroCard(themeMode: themeMode, themeController: themeController),
            const SizedBox(height: 24),
            _SectionCard(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Switch between light, dark or system-matched themes.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                    ],
                    selected: {themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      HapticFeedback.selectionClick();
                      themeController.setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.insights_outlined,
              title: 'Privacy controls',
              subtitle: 'Decide how much you want to share about app usage.',
              child: SwitchListTile.adaptive(
                value: state.analyticsEnabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  notifier.setAnalytics(value);
                },
                title: const Text('Enable analytics'),
                subtitle: const Text('Opt-in to anonymous usage analytics that help us improve.'),
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.delete_sweep_outlined,
              title: 'Danger zone',
              subtitle: 'Clear your saved QR codes from this device.',
              tone: SectionTone.danger,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog.adaptive(
                          title: const Text('Clear history?'),
                          content: const Text('This permanently removes every saved QR code on this device.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.onErrorContainer,
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    await notifier.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('History cleared.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear history'),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: state.error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        state.error!.message,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.themeMode, required this.themeController});

  final ThemeMode themeMode;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.9),
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.18),
                ),
                child: const Icon(Icons.tune_rounded, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Make it yours',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Current theme: ${_modeLabel(themeMode)}',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              final next = _cycleTheme(themeMode);
              themeController.setThemeMode(next);
            },
            icon: const Icon(Icons.autorenew_rounded),
            label: const Text('Cycle theme'),
          ),
        ],
      ),
    );
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  ThemeMode _cycleTheme(ThemeMode current) {
    switch (current) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }
}

enum SectionTone { neutral, danger }

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.tone = SectionTone.neutral,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = tone == SectionTone.danger;
    final baseColor = isDanger ? theme.colorScheme.errorContainer : theme.cardColor;
    final borderColor = isDanger
        ? theme.colorScheme.error.withOpacity(0.3)
        : theme.colorScheme.outlineVariant.withOpacity(0.4);

    return Card(
      color: baseColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: (isDanger ? theme.colorScheme.error : theme.colorScheme.primary)
                      .withOpacity(0.15),
                  child: Icon(
                    icon,
                    color: isDanger ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

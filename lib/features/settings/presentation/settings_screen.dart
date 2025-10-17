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
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
            16,
            32,
          ),
          children: [
            _SectionCard(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Switch between light, dark or system-matched themes.',
              child: _ThemeDropdown(
                value: themeMode,
                onChanged: (m) {
                  HapticFeedback.selectionClick();
                  themeController.setThemeMode(m);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Privacy controls
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
                subtitle: const Text(
                  'Opt-in to anonymous usage analytics that help us improve.',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              icon: Icons.history_rounded,
              title: 'History & saving',
              subtitle: 'Choose when new QR codes are stored automatically.',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: state.autoSaveGenerated,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      notifier.setAutoSaveGenerated(value);
                    },
                    title: const Text('Auto-save generated codes'),
                    subtitle: const Text(
                      'Automatically store newly generated QR codes in history.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: state.autoSaveScanned,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      notifier.setAutoSaveScanned(value);
                    },
                    title: const Text('Auto-save scanned codes'),
                    subtitle: const Text(
                      'Save every scan to history as soon as it’s detected.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Danger zone
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
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog.adaptive(
                          title: const Text('Clear history?'),
                          content: const Text(
                            'This permanently removes every saved QR code on this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.errorContainer,
                                foregroundColor:
                                    theme.colorScheme.onErrorContainer,
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

            // Error
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: ref.watch(settingsVmProvider).error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        ref.watch(settingsVmProvider).error!.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown that replaces SegmentedButton for ThemeMode
class _ThemeDropdown extends StatelessWidget {
  const _ThemeDropdown({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<ThemeMode>(
      initialValue: value,
      isExpanded: true,
      items: const [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: _DropdownTile(
            icon: Icons.settings_suggest_outlined,
            label: 'System',
          ),
        ),
        DropdownMenuItem(
          value: ThemeMode.light,
          child: _DropdownTile(icon: Icons.light_mode_outlined, label: 'Light'),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: _DropdownTile(icon: Icons.dark_mode_outlined, label: 'Dark'),
        ),
      ],
      onChanged: (m) {
        if (m == null) return;
        HapticFeedback.selectionClick();
        onChanged(m);
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
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

    // Clean look: no inner "daba" box — just comfy spacing.
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      (isDanger
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary)
                          .withOpacity(0.12),
                  child: Icon(
                    icon,
                    color: isDanger
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
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
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

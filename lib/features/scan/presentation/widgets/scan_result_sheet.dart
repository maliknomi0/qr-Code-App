import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/qr_parsers.dart';
import '../../../../core/utils/uri_utils.dart';
import '../../../../domain/entities/qr_item.dart';
import '../../../../domain/entities/qr_type.dart';

class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.item,
    this.autoSaved = true,
    this.onSave,
  });

  final QrItem item;
  final bool autoSaved;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wifi = item.type == QrType.wifi ? parseWifi(item.data.value) : null;
    final email =
        item.type == QrType.email ? parseEmail(item.data.value) : null;
    final sms = item.type == QrType.sms ? parseSms(item.data.value) : null;
    final uri = item.type == QrType.url ? Uri.tryParse(item.data.value) : null;
final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: item.data.value));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard.')),
          );
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copy'),
      ),
    ];

    if (item.type == QrType.url && uri != null) {
      actions.insert(
        0,
        FilledButton.icon(
          onPressed: () async {
            final launched = await tryLaunchUrl(uri);
            if (!launched && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open the link.')),
              );
            }
          },
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Open in browser'),
        ),
      );
    }

    if (!autoSaved && onSave != null) {
      actions.add(
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save to history'),
        ),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headlineForType(item.type),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        autoSaved
                            ? 'Saved to history'
                            : 'Not saved automatically',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (wifi != null) ...[
              _InfoCard(
                icon: Icons.wifi_rounded,
                title: 'Network name',
                value: wifi.ssid,
                onCopy: () => _copyValue(
                  context,
                  wifi.ssid,
                  'Wi-Fi name',
                ),
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.lock_outline,
                title: 'Password',
                value: wifi.password ?? 'Not required',
                onCopy: wifi.password == null
                    ? null
                    : () => _copyValue(
                          context,
                          wifi.password!,
                          'Wi-Fi password',
                        ),
              ),
              ] else if (email != null) ...[
              _InfoCard(
                icon: Icons.person_outline_rounded,
                title: 'Recipient',
                value: email.to,
                onCopy: () =>
                    _copyValue(context, email.to, 'Email recipient'),
              ),
              if (email.subject != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.subject_rounded,
                  title: 'Subject',
                  value: email.subject!,
                  onCopy: () => _copyValue(
                    context,
                    email.subject!,
                    'Email subject',
                  ),
                ),
              ],
              if (email.body != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.notes_rounded,
                  title: 'Message',
                  value: email.body!,
                  onCopy: () => _copyValue(
                    context,
                    email.body!,
                    'Email body',
                  ),
                ),
              ],
            ] else if (sms != null) ...[
              _InfoCard(
                icon: Icons.phone_rounded,
                title: 'Send to',
                value: sms.phoneNumber,
                onCopy: () => _copyValue(
                  context,
                  sms.phoneNumber,
                  'SMS recipient',
                ),
              ),
              if (sms.message != null) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.sms_rounded,
                  title: 'Message',
                  value: sms.message!,
                  onCopy: () => _copyValue(
                    context,
                    sms.message!,
                    'SMS body',
                  ),
                ),
              ],
            ] else ...[
              _InfoCard(
                icon: _iconForType(item.type),
                title: _contentLabel(item.type),
                value: item.data.value,
                onCopy: () => _copyValue(
                  context,
                  item.data.value,
                  _contentLabel(item.type),
                ),
              ),
            ],
              if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width:
                            actions.length == 1 ? double.infinity : null,
                        child: action,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Future<void> _copyValue(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded),
                  color: theme.colorScheme.primary,
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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

String _headlineForType(QrType type) {
  switch (type) {
    case QrType.text:
      return 'Text detected';
    case QrType.url:
      return 'Link detected';
    case QrType.wifi:
      return 'Wi-Fi credentials';
    case QrType.email:
      return 'Email data';
    case QrType.phone:
      return 'Phone number';
    case QrType.sms:
      return 'SMS details';
    case QrType.vcard:
      return 'Contact card';
  }
}

String _contentLabel(QrType type) {
  switch (type) {
    case QrType.text:
      return 'Text';
    case QrType.url:
      return 'URL';
    case QrType.wifi:
      return 'Wi-Fi';
    case QrType.email:
      return 'Email';
    case QrType.phone:
      return 'Phone';
    case QrType.sms:
      return 'SMS';
    case QrType.vcard:
      return 'vCard';
  }
}

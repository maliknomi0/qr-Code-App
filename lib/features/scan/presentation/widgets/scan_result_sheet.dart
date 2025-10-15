import 'package:flutter/material.dart';

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
    final wifi = item.type == QrType.wifi ? _parseWifi(item.data.value) : null;
    final uri = item.type == QrType.url ? Uri.tryParse(item.data.value) : null;

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
                title: 'Wi-Fi network',
                value: wifi.ssid,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.lock_outline,
                title: 'Password',
                value: wifi.password ?? 'Not required',
              ),
            ] else ...[
              _InfoCard(
                icon: _iconForType(item.type),
                title: _contentLabel(item.type),
                value: item.data.value,
              ),
              if (item.type == QrType.url && uri != null) ...[
                const SizedBox(height: 16),
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
                 if (!autoSaved && onSave != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save to history'),
              ),
            ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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

class _WifiCredentials {
  const _WifiCredentials({
    required this.ssid,
    this.password,
  });

  final String ssid;
  final String? password;
}

_WifiCredentials? _parseWifi(String raw) {
  if (!raw.startsWith('WIFI:')) return null;
  final content = raw.substring(5);
  String? ssid;
  String? password;

  final parts = content.split(';');
  for (final part in parts) {
    if (part.isEmpty) continue;
    final separatorIndex = part.indexOf(':');
    if (separatorIndex == -1) continue;
    final key = part.substring(0, separatorIndex);
    final value = _unescape(part.substring(separatorIndex + 1));
    switch (key) {
      case 'S':
        ssid = value;
        break;
      case 'P':
        password = value.isEmpty ? null : value;
        break;
    }
  }

  if (ssid == null && password == null) {
    return null;
  }

  return _WifiCredentials(
    ssid: ssid == null || ssid.isEmpty ? 'Unknown network' : ssid,
    password: password,
  );
}

String _unescape(String input) {
  final buffer = StringBuffer();
  var isEscaping = false;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (isEscaping) {
      buffer.write(char);
      isEscaping = false;
    } else if (char == '\\') {
      isEscaping = true;
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
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

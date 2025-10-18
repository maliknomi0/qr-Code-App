import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/qr_type.dart';

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
                  _ContentCard(state: state, notifier: notifier),
                  const SizedBox(height: 16),
                  _LogoCard(state: state, notifier: notifier),
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
  const _ContentCard({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  static const List<QrType> _supportedTypes = <QrType>[
    QrType.url,
    QrType.text,
    QrType.email,
    QrType.sms,
    QrType.wifi,
  ];

  late QrType _selectedType;

  late final TextEditingController _textCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _emailToCtrl;
  late final TextEditingController _emailSubjectCtrl;
  late final TextEditingController _emailBodyCtrl;
  late final TextEditingController _smsPhoneCtrl;
  late final TextEditingController _smsMessageCtrl;
  late final TextEditingController _wifiSsidCtrl;
  late final TextEditingController _wifiPasswordCtrl;

  _WifiSecurity _wifiSecurity = _WifiSecurity.wpa;
  bool _wifiHidden = false;
  bool _showWifiPassword = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _urlCtrl = TextEditingController();
    _emailToCtrl = TextEditingController();
    _emailSubjectCtrl = TextEditingController();
    _emailBodyCtrl = TextEditingController();
    _smsPhoneCtrl = TextEditingController();
    _smsMessageCtrl = TextEditingController();
    _wifiSsidCtrl = TextEditingController();
    _wifiPasswordCtrl = TextEditingController();
    _selectedType = _normalizeType(widget.state.contentType);
    _syncFromState(widget.state, initialize: true);
  }

  @override
  void didUpdateWidget(covariant _ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.data != oldWidget.state.data ||
        widget.state.contentType != oldWidget.state.contentType) {
      _syncFromState(widget.state);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _urlCtrl.dispose();
    _emailToCtrl.dispose();
    _emailSubjectCtrl.dispose();
    _emailBodyCtrl.dispose();
    _smsPhoneCtrl.dispose();
    _smsMessageCtrl.dispose();
    _wifiSsidCtrl.dispose();
    _wifiPasswordCtrl.dispose();
    super.dispose();
  }

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
            _SectionHeader(icon: Icons.text_fields, title: 'QR Content'),
            const SizedBox(height: 8),
            Text('Choose what to encode', style: label),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _supportedTypes.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(_labelForType(type)),
                  avatar: Icon(
                    _iconForType(type),
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  selected: isSelected,
                  onSelected: (value) {
                    if (!value) return;
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedType = type;
                    });
                    _notifyChange();
                  },
                  selectedColor: theme.colorScheme.secondaryContainer,
                  labelStyle: isSelected
                      ? theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        )
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_selectedType),
                child: _buildFormForType(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  QrType _normalizeType(QrType type) {
    return _supportedTypes.contains(type) ? type : QrType.text;
  }

  void _syncFromState(GenerateState state, {bool initialize = false}) {
    final normalizedType = _normalizeType(state.contentType);
    final previousType = _selectedType;

    switch (normalizedType) {
      case QrType.text:
        _setControllerText(_textCtrl, state.data);
        break;
      case QrType.url:
        _setControllerText(_urlCtrl, state.data);
        break;
      case QrType.email:
        final email = _parseEmailFields(state.data);
        _setControllerText(_emailToCtrl, email.to);
        _setControllerText(_emailSubjectCtrl, email.subject);
        _setControllerText(_emailBodyCtrl, email.body);
        break;
      case QrType.sms:
        final sms = _parseSmsFields(state.data);
        _setControllerText(_smsPhoneCtrl, sms.phoneNumber);
        _setControllerText(_smsMessageCtrl, sms.message);
        break;
      case QrType.wifi:
        final wifi = _parseWifiFields(state.data);
        _setControllerText(_wifiSsidCtrl, wifi.ssid);
        _setControllerText(_wifiPasswordCtrl, wifi.password);
        _wifiSecurity = wifi.security;
        _wifiHidden = wifi.hidden;
        break;
      default:
        _setControllerText(_textCtrl, state.data);
        break;
    }

    if (initialize) {
      _selectedType = normalizedType;
      return;
    }

    if (previousType != normalizedType) {
      setState(() {
        _selectedType = normalizedType;
      });
    } else if (normalizedType == QrType.wifi) {
      setState(() {});
    }
  }

  void _notifyChange() {
    final data = _buildDataForType(_selectedType);
    widget.notifier.updateContent(_selectedType, data);
  }

  Widget _buildFormForType() {
    switch (_selectedType) {
      case QrType.url:
        return _UrlForm(controller: _urlCtrl, onChanged: _notifyChange);
      case QrType.email:
        return _EmailForm(
          toController: _emailToCtrl,
          subjectController: _emailSubjectCtrl,
          bodyController: _emailBodyCtrl,
          onChanged: _notifyChange,
        );
      case QrType.sms:
        return _SmsForm(
          phoneController: _smsPhoneCtrl,
          messageController: _smsMessageCtrl,
          onChanged: _notifyChange,
        );
      case QrType.wifi:
        return _WifiForm(
          ssidController: _wifiSsidCtrl,
          passwordController: _wifiPasswordCtrl,
          security: _wifiSecurity,
          hidden: _wifiHidden,
          showPassword: _showWifiPassword,
          onSecurityChanged: (value) {
            setState(() {
              _wifiSecurity = value;
            });
            _notifyChange();
          },
          onHiddenChanged: (value) {
            setState(() {
              _wifiHidden = value;
            });
            _notifyChange();
          },
          onTogglePasswordVisibility: () {
            setState(() {
              _showWifiPassword = !_showWifiPassword;
            });
          },
          onChanged: _notifyChange,
        );
      case QrType.text:
      default:
        return _TextForm(controller: _textCtrl, onChanged: _notifyChange);
    }
  }

  String _buildDataForType(QrType type) {
    switch (type) {
      case QrType.text:
        return _textCtrl.text;
      case QrType.url:
        return _urlCtrl.text.trim();
      case QrType.email:
        final to = _emailToCtrl.text.trim();
        final subject = _emailSubjectCtrl.text.trim();
        final body = _emailBodyCtrl.text.trim();
        if (to.isEmpty && subject.isEmpty && body.isEmpty) return '';
        final query = <String, String>{};
        if (subject.isNotEmpty) query['subject'] = subject;
        if (body.isNotEmpty) query['body'] = body;
        final uri = Uri(
          scheme: 'mailto',
          path: to,
          queryParameters: query.isEmpty ? null : query,
        );
        return uri.toString();
      case QrType.sms:
        final phone = _smsPhoneCtrl.text.trim();
        final message = _smsMessageCtrl.text.trim();
        if (phone.isEmpty && message.isEmpty) return '';
        final query = message.isEmpty
            ? null
            : <String, String>{'body': message};
        final uri = Uri(scheme: 'sms', path: phone, queryParameters: query);
        return uri.toString();
      case QrType.wifi:
        final ssid = _wifiSsidCtrl.text.trim();
        final password = _wifiPasswordCtrl.text;
        final hasPassword = password.trim().isNotEmpty;
        if (ssid.isEmpty && !hasPassword) return '';
        final buffer = StringBuffer('WIFI:');
        buffer.write('T:${_wifiSecurity.qrValue};');
        buffer.write('S:${_escapeWifiComponent(ssid)};');
        if (_wifiSecurity != _WifiSecurity.none &&
            (hasPassword || password.isNotEmpty)) {
          buffer.write('P:${_escapeWifiComponent(password)};');
        }
        if (_wifiHidden) {
          buffer.write('H:true;');
        }
        buffer.write(';');
        return buffer.toString();
      default:
        return _textCtrl.text;
    }
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  _EmailFields _parseEmailFields(String raw) {
    if (raw.isEmpty) return const _EmailFields();
    final lower = raw.toLowerCase();
    if (lower.startsWith('mailto:')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return _EmailFields(to: raw);
      final params = <String, String>{};
      for (final entry in uri.queryParameters.entries) {
        params[entry.key.toLowerCase()] = entry.value;
      }
      final to = uri.path.isNotEmpty ? uri.path : (params['to'] ?? '');
      return _EmailFields(
        to: to,
        subject: params['subject'] ?? '',
        body: params['body'] ?? '',
      );
    }

    if (lower.startsWith('matmsg:')) {
      final content = raw.substring(7);
      String to = '';
      String subject = '';
      String body = '';
      for (final part in content.split(';')) {
        if (part.isEmpty) continue;
        final normalized = part.startsWith('MATMSG:')
            ? part.substring(7)
            : part;
        final index = normalized.indexOf(':');
        if (index == -1) continue;
        final key = normalized.substring(0, index).toLowerCase();
        final value = _unescape(normalized.substring(index + 1));
        switch (key) {
          case 'to':
            to = value;
            break;
          case 'sub':
            subject = value;
            break;
          case 'body':
            body = value;
            break;
        }
      }
      return _EmailFields(to: to, subject: subject, body: body);
    }

    return _EmailFields(to: raw);
  }

  _SmsFields _parseSmsFields(String raw) {
    if (raw.isEmpty) return const _SmsFields();
    final lower = raw.toLowerCase();
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) {
      final scheme = lower.startsWith('sms:') ? 'sms' : 'smsto';
      final normalizedRaw = scheme == 'sms' ? raw : 'sms:${raw.substring(6)}';
      final uri = Uri.tryParse(normalizedRaw);
      if (uri == null) return _SmsFields(phoneNumber: raw);
      final phone = uri.path.isNotEmpty
          ? uri.path
          : (uri.queryParameters['to'] ?? '');
      final body = uri.queryParameters['body'] ?? '';
      return _SmsFields(phoneNumber: phone, message: body);
    }
    return _SmsFields(phoneNumber: raw);
  }

  _WifiFields _parseWifiFields(String raw) {
    if (!raw.toUpperCase().startsWith('WIFI:')) {
      return const _WifiFields();
    }
    final content = raw.substring(5);
    String ssid = '';
    String password = '';
    _WifiSecurity security = _WifiSecurity.wpa;
    bool hidden = false;
    for (final part in content.split(';')) {
      if (part.isEmpty) continue;
      final index = part.indexOf(':');
      if (index == -1) continue;
      final key = part.substring(0, index).toUpperCase();
      final value = _unescape(part.substring(index + 1));
      switch (key) {
        case 'T':
          security = _WifiSecurityExtension.fromQrValue(value);
          break;
        case 'S':
          ssid = value;
          break;
        case 'P':
          password = value;
          break;
        case 'H':
          hidden = value.toLowerCase() == 'true';
          break;
      }
    }
    return _WifiFields(
      ssid: ssid,
      password: password,
      security: security,
      hidden: hidden,
    );
  }

  String _escapeWifiComponent(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:');
  }

  String _unescape(String input) {
    final buffer = StringBuffer();
    var escaping = false;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (escaping) {
        switch (char) {
          case 'n':
            buffer.write('\n');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case 't':
            buffer.write('\t');
            break;
          default:
            buffer.write(char);
        }
        escaping = false;
      } else if (char == '\\') {
        escaping = true;
      } else {
        buffer.write(char);
      }
    }
    if (escaping) buffer.write('\\');
    return buffer.toString();
  }
}

class _TextForm extends StatelessWidget {
  const _TextForm({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Plain text',
        hintText: 'Type the message you want to share',
        alignLabelWithHint: true,
      ),
      minLines: 4,
      maxLines: 8,
      onChanged: (_) => onChanged(),
    );
  }
}

class _UrlForm extends StatelessWidget {
  const _UrlForm({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Website URL',
            hintText: 'https://example.com',
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        Text(
          'Include the full address so scanners can open it instantly.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.toController,
    required this.subjectController,
    required this.bodyController,
    required this.onChanged,
  });

  final TextEditingController toController;
  final TextEditingController subjectController;
  final TextEditingController bodyController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: toController,
          decoration: const InputDecoration(
            labelText: 'Recipient',
            hintText: 'name@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: subjectController,
          decoration: const InputDecoration(labelText: 'Subject (optional)'),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bodyController,
          decoration: const InputDecoration(
            labelText: 'Message (optional)',
            alignLabelWithHint: true,
          ),
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _SmsForm extends StatelessWidget {
  const _SmsForm({
    required this.phoneController,
    required this.messageController,
    required this.onChanged,
  });

  final TextEditingController phoneController;
  final TextEditingController messageController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+1 555 0100',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Message (optional)',
            alignLabelWithHint: true,
          ),
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _WifiForm extends StatelessWidget {
  const _WifiForm({
    required this.ssidController,
    required this.passwordController,
    required this.security,
    required this.hidden,
    required this.showPassword,
    required this.onSecurityChanged,
    required this.onHiddenChanged,
    required this.onTogglePasswordVisibility,
    required this.onChanged,
  });

  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final _WifiSecurity security;
  final bool hidden;
  final bool showPassword;
  final ValueChanged<_WifiSecurity> onSecurityChanged;
  final ValueChanged<bool> onHiddenChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<_WifiSecurity>(
          value: security,
          decoration: const InputDecoration(labelText: 'Security'),
          items: _WifiSecurity.values
              .map(
                (security) => DropdownMenuItem<_WifiSecurity>(
                  value: security,
                  child: Text(security.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onSecurityChanged(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ssidController,
          decoration: const InputDecoration(
            labelText: 'Network name (SSID)',
            hintText: 'Home Wi-Fi',
          ),
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: security == _WifiSecurity.none
                ? 'Password (not required)'
                : 'Password',
            suffixIcon: security == _WifiSecurity.none
                ? null
                : IconButton(
                    onPressed: onTogglePasswordVisibility,
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
          ),
          obscureText: security != _WifiSecurity.none && !showPassword,
          enabled: security != _WifiSecurity.none,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: hidden,
          onChanged: onHiddenChanged,
          title: const Text('Hidden network'),
          subtitle: Text(
            'Enable this if your Wi-Fi does not broadcast its name.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailFields {
  const _EmailFields({this.to = '', this.subject = '', this.body = ''});

  final String to;
  final String subject;
  final String body;
}

class _SmsFields {
  const _SmsFields({this.phoneNumber = '', this.message = ''});

  final String phoneNumber;
  final String message;
}

class _WifiFields {
  const _WifiFields({
    this.ssid = '',
    this.password = '',
    this.security = _WifiSecurity.wpa,
    this.hidden = false,
  });

  final String ssid;
  final String password;
  final _WifiSecurity security;
  final bool hidden;
}

enum _WifiSecurity { wpa, wep, none }

extension _WifiSecurityExtension on _WifiSecurity {
  String get label {
    switch (this) {
      case _WifiSecurity.wpa:
        return 'WPA/WPA2';
      case _WifiSecurity.wep:
        return 'WEP';
      case _WifiSecurity.none:
        return 'None';
    }
  }

  String get qrValue {
    switch (this) {
      case _WifiSecurity.wpa:
        return 'WPA';
      case _WifiSecurity.wep:
        return 'WEP';
      case _WifiSecurity.none:
        return 'nopass';
    }
  }

  static _WifiSecurity fromQrValue(String raw) {
    final normalized = raw.toUpperCase();
    switch (normalized) {
      case 'WPA':
      case 'WPA2':
        return _WifiSecurity.wpa;
      case 'WEP':
        return _WifiSecurity.wep;
      case '':
      case 'NOPASS':
        return _WifiSecurity.none;
      default:
        return _WifiSecurity.wpa;
    }
  }
}

String _labelForType(QrType type) {
  switch (type) {
    case QrType.text:
      return 'Text';
    case QrType.url:
      return 'URL';
    case QrType.email:
      return 'Email';
    case QrType.sms:
      return 'SMS';
    case QrType.wifi:
      return 'Wi-Fi';
    default:
      return 'Text';
  }
}

IconData _iconForType(QrType type) {
  switch (type) {
    case QrType.text:
      return Icons.notes_outlined;
    case QrType.url:
      return Icons.link_outlined;
    case QrType.email:
      return Icons.email_outlined;
    case QrType.sms:
      return Icons.sms_outlined;
    case QrType.wifi:
      return Icons.wifi;
    default:
      return Icons.notes_outlined;
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QrDesign.values.map((design) {
                final selected = state.design == design;
                return ChoiceChip(
                  label: Text(_labelForDesign(design)),
                  avatar: Icon(
                    _iconForDesign(design),
                    size: 20,
                    color: selected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  selected: selected,
                  onSelected: (value) {
                    if (!value) return;
                    HapticFeedback.selectionClick();
                    notifier.updateDesign(design);
                  },
                  selectedColor: theme.colorScheme.secondaryContainer,
                  labelStyle: selected
                      ? theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        )
                      : null,
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
            // const SizedBox(height: 16),
            // Text('Error correction', style: label),
            // const SizedBox(height: 8),
            // _EnumDropdown<QrErrorCorrection>(
            //   value: state.errorCorrection,
            //   hint: 'Choose level',
            //   onChanged: (v) => notifier.updateErrorCorrection(v),
            //   items: QrErrorCorrection.values.map((level) {
            //     return DropdownMenuItem<QrErrorCorrection>(
            //       value: level,
            //       child: Row(
            //         children: [
            //           Icon(_iconForCorrection(level)),
            //           const SizedBox(width: 8),
            //           Text(_labelForCorrection(level)),
            //         ],
            //       ),
            //     );
            //   }).toList(),
            // ),
            // const SizedBox(height: 6),
            // Text(
            //   'Higher levels make codes more resilient to damage but denser.',
            //   style: theme.textTheme.bodySmall?.copyWith(
            //     color: theme.colorScheme.onSurfaceVariant,
            //   ),
            // ),

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

// Logo (moved from old Branding card)
class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.state, required this.notifier});

  final GenerateState state;
  final GenerateVm notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLogo = state.logoBytes != null;
    final subtleTextColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.workspace_premium_rounded,
              title: 'Logo & branding',
            ),
            const SizedBox(height: 8),
            Text(
              'Drop a transparent PNG or SVG to make your QR look premium.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtleTextColor,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _pickLogo(context, notifier);
              },
              borderRadius: BorderRadius.circular(18),
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
            ),
            if (hasLogo) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    notifier.updateLogo(null);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove logo'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Logo size', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _LogoSizeSlider(
                value: state.logoScale,
                onChanged: (value) =>
                    notifier.updateLogoScale(value, regenerate: false),
                onChangeEnd: (value) =>
                    notifier.updateLogoScale(value, regenerate: true),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${(state.logoScale * 100).round()}% of QR width',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtleTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pro tip: bold, high-contrast logos with transparent backgrounds scan best.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtleTextColor,
                ),
              ),
            ],
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

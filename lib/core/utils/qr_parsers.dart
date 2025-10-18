class ParsedWifi {
  const ParsedWifi({required this.ssid, this.password});

  final String ssid;
  final String? password;
}

class ParsedEmail {
  const ParsedEmail({required this.to, this.subject, this.body});

  final String to;
  final String? subject;
  final String? body;
}

class ParsedSms {
  const ParsedSms({required this.phoneNumber, this.message});

  final String phoneNumber;
  final String? message;
}

ParsedWifi? parseWifi(String raw) {
  if (!raw.toUpperCase().startsWith('WIFI:')) return null;
  final content = raw.substring(5);
  String? ssid;
  String? password;

  for (final part in content.split(';')) {
    if (part.isEmpty) continue;
    final separatorIndex = part.indexOf(':');
    if (separatorIndex == -1) continue;
    final key = part.substring(0, separatorIndex).toUpperCase();
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

  if ((ssid == null || ssid.isEmpty) && (password == null || password!.isEmpty)) {
    return null;
  }

  return ParsedWifi(
    ssid: (ssid == null || ssid.isEmpty) ? 'Unknown network' : ssid,
    password: password,
  );
}

ParsedEmail? parseEmail(String raw) {
  final lower = raw.toLowerCase();
  if (lower.startsWith('mailto:')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final parameters = Map<String, String>.fromEntries(
      uri.queryParameters.entries.map(
            (entry) => MapEntry(entry.key.toLowerCase(), entry.value),
      ),
    );
    final recipientsParam = parameters['to'];
    final toValue = uri.path.isNotEmpty ? uri.path : recipientsParam;
    final subject = parameters['subject'];
    final body = parameters['body'];
    if ((toValue == null || toValue.isEmpty) &&
        (subject == null || subject.isEmpty) &&
        (body == null || body.isEmpty)) {
      return null;
    }
    return ParsedEmail(
      to: (toValue == null || toValue.isEmpty) ? 'Unknown recipient' : toValue,
      subject: _normalizeOptional(subject),
      body: _normalizeOptional(body),
    );
  }

  if (!raw.startsWith('MATMSG:')) return null;
  final content = raw.substring(7);
  String? to;
  String? subject;
  String? body;

  for (final part in content.split(';')) {
    if (part.isEmpty) continue;
    final normalizedPart = part.startsWith('MATMSG:') ? part.substring(7) : part;
    final separatorIndex = normalizedPart.indexOf(':');
    if (separatorIndex == -1) continue;
    final key = normalizedPart.substring(0, separatorIndex).toUpperCase();
    final value = _unescape(normalizedPart.substring(separatorIndex + 1));
    switch (key) {
      case 'TO':
        to = value;
        break;
      case 'SUB':
        subject = value;
        break;
      case 'BODY':
        body = value;
        break;
    }
  }

  if ((to == null || to!.trim().isEmpty) &&
      (subject == null || subject!.trim().isEmpty) &&
      (body == null || body!.trim().isEmpty)) {
    return null;
  }

  return ParsedEmail(
    to: (to == null || to.trim().isEmpty) ? 'Unknown recipient' : to.trim(),
    subject: _normalizeOptional(subject),
    body: _normalizeOptional(body),
  );
}

ParsedSms? parseSms(String raw) {
  final lower = raw.toLowerCase();
  if (lower.startsWith('sms:')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final phone = uri.path.isNotEmpty ? uri.path : uri.queryParameters['to'];
    final body = uri.queryParameters['body'];
    if ((phone == null || phone.isEmpty) && (body == null || body.isEmpty)) {
      return null;
    }
    return ParsedSms(
      phoneNumber: (phone == null || phone.isEmpty) ? 'Unknown recipient' : phone,
      message: _normalizeOptional(body),
    );
  }

  if (!lower.startsWith('smsto:')) return null;
  final content = raw.substring(6);
  final firstSeparator = content.indexOf(':');
  String? phone;
  String? message;
  if (firstSeparator == -1) {
    phone = content;
  } else {
    phone = content.substring(0, firstSeparator);
    message = content.substring(firstSeparator + 1);
  }
  if ((phone == null || phone.trim().isEmpty) &&
      (message == null || message.trim().isEmpty)) {
    return null;
  }
  return ParsedSms(
    phoneNumber: (phone == null || phone.trim().isEmpty)
        ? 'Unknown recipient'
        : phone.trim(),
    message: _normalizeOptional(message),
  );
}

String? _normalizeOptional(String? value) {
  if (value == null) return null;
  final normalized = _unescape(value).trim();
  return normalized.isEmpty ? null : normalized;
}

String _unescape(String input) {
  final buffer = StringBuffer();
  var isEscaping = false;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (isEscaping) {
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
      isEscaping = false;
    } else if (char == '\\') {
      isEscaping = true;
    } else {
      buffer.write(char);
    }
  }
  if (isEscaping) buffer.write('\\');
  return buffer.toString();
}
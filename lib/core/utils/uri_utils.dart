import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> tryLaunchUrl(Uri uri) async {
  if (!await canLaunchUrl(uri)) {
    return false;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return true;
  } on PlatformException {
    // Fallback to platform default below.
  }

  return launchUrl(
    uri,
    mode: LaunchMode.platformDefault,
    webOnlyWindowName: '_blank',
  );
}

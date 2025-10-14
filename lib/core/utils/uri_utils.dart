import 'package:url_launcher/url_launcher.dart';

Future<bool> tryLaunchUrl(Uri uri) async {
  if (!await canLaunchUrl(uri)) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

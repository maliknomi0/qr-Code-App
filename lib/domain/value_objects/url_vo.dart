import 'package:validators/validators.dart' as validators;

import '../../core/error/app_error.dart';
import 'non_empty_string.dart';

class UrlVo {
  UrlVo._(this.value);

  final String value;

  factory UrlVo(String input) {
    final value = NonEmptyString(input).value;
    if (!validators.isURL(value)) {
      throw const ValidationError('Invalid URL');
    }
    return UrlVo._(value);
  }

  Uri toUri() => Uri.parse(value);
}

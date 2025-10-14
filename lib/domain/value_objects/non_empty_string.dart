import '../../core/error/app_error.dart';

class NonEmptyString {
  NonEmptyString._(this.value);

  final String value;

  factory NonEmptyString(String input) {
    if (input.trim().isEmpty) {
      throw const ValidationError('Value cannot be empty');
    }
    return NonEmptyString._(input.trim());
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is NonEmptyString && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

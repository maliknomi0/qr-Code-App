import 'package:uuid/v4.dart';

class Uuid {
  Uuid._(this.value);

  final String value;

  static Uuid generate() => Uuid._(const UuidV4().generate());

  factory Uuid.fromString(String input) {
    if (input.isEmpty) {
      throw ArgumentError('UUID cannot be empty');
    }
    return Uuid._(input);
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is Uuid && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

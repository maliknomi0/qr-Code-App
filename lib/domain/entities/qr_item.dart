import '../value_objects/non_empty_string.dart';
import '../value_objects/uuid.dart';
import 'qr_source.dart';
import 'qr_type.dart';

class QrItem {
  QrItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.source = QrSource.unknown,
    this.isFavorite = false,
  });

  final Uuid id;
  final QrType type;
  final NonEmptyString data;
  final DateTime createdAt;
  final QrSource source;
  final bool isFavorite;

  QrItem copyWith({bool? isFavorite, QrSource? source}) {
    return QrItem(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
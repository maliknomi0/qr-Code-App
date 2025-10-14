import '../value_objects/non_empty_string.dart';
import '../value_objects/uuid.dart';
import 'qr_type.dart';

class QrItem {
  QrItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isFavorite = false,
  });

  final Uuid id;
  final QrType type;
  final NonEmptyString data;
  final DateTime createdAt;
  final bool isFavorite;

  QrItem copyWith({bool? isFavorite}) {
    return QrItem(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

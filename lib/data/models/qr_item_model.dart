import 'package:hive/hive.dart';

import '../../domain/entities/qr_item.dart';
import '../../domain/entities/qr_source.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/value_objects/non_empty_string.dart';
import '../../domain/value_objects/uuid.dart';

class QrItemModel extends HiveObject {
  QrItemModel({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.isFavorite,
    required this.source,
  });

  String id;
  int type;
  String data;
  DateTime createdAt;
  bool isFavorite;
  int source;

  factory QrItemModel.fromEntity(QrItem item) => QrItemModel(
    id: item.id.value,
    type: item.type.index,
    data: item.data.value,
    createdAt: item.createdAt,
    isFavorite: item.isFavorite,
    source: item.source.index,
  );

  QrItem toEntity() {
    final normalizedSource = source.clamp(0, QrSource.values.length - 1);
    return QrItem(
      id: Uuid.fromString(id),
      type: QrType.values[type],
      data: NonEmptyString(data),
      createdAt: createdAt,
      source: QrSource.values[normalizedSource],
      isFavorite: isFavorite,
    );
  }
}

class QrItemModelAdapter extends TypeAdapter<QrItemModel> {
  @override
  final int typeId = 1;

  @override
  QrItemModel read(BinaryReader reader) {
    final id = reader.readString();
    final type = reader.readInt();
    final data = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final isFavorite = reader.readBool();
    int source;
    try {
      source = reader.readInt();
    } catch (_) {
      source = QrSource.unknown.index;
    }
    return QrItemModel(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      isFavorite: isFavorite,
      source: source,
    );
  }

  @override
  void write(BinaryWriter writer, QrItemModel obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.type)
      ..writeString(obj.data)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeBool(obj.isFavorite)
      ..writeInt(obj.source);
  }
}

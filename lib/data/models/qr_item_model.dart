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
    List<String>? tags,
  }) : tags = tags ?? <String>[];

  String id;
  int type;
  String data;
  DateTime createdAt;
  bool isFavorite;
  int source;
  List<String> tags;

  factory QrItemModel.fromEntity(QrItem item) => QrItemModel(
    id: item.id.value,
    type: item.type.index,
    data: item.data.value,
    createdAt: item.createdAt,
    isFavorite: item.isFavorite,
    source: item.source.index,
    tags: List<String>.from(item.tags),
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
      tags: List<String>.unmodifiable(tags),
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
    List<String> tags;
    try {
      final dynamic raw = reader.read();
      if (raw is List) {
        tags = raw.cast<String>();
      } else {
        tags = <String>[];
      }
    } catch (_) {
      tags = <String>[];
    }
    return QrItemModel(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      isFavorite: isFavorite,
      source: source,
      tags: tags,
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
      ..writeInt(obj.source)
      ..write(obj.tags);
  }
}

import 'package:hive/hive.dart';

import '../../models/qr_item_model.dart';

Future<void> registerHiveAdapters() async {
  final adapter = QrItemModelAdapter();
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

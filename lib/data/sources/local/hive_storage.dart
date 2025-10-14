import 'package:hive/hive.dart';

import '../../models/qr_item_model.dart';
import 'hive_boxes.dart';

class HiveStorage {
  Future<Box<QrItemModel>> openHistoryBox() async {
    if (Hive.isBoxOpen(HiveBoxes.history)) {
      return Hive.box<QrItemModel>(HiveBoxes.history);
    }
    return Hive.openBox<QrItemModel>(HiveBoxes.history);
  }
}

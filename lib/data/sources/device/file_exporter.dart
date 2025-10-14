import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileExporter {
  Future<String> saveFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

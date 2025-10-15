import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class FileExporter {
  Future<String> saveFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<bool> saveImageToGallery(List<int> bytes, String fileName) async {
    try {
      await Gal.putImageBytes(
        Uint8List.fromList(bytes),
        name: fileName,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

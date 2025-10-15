import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

class FileExporter {
  Future<String> saveFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> saveImageToGallery(List<int> bytes, String fileName) async {
    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(bytes),
      name: fileName,
      quality: 100,
    );
    final path = result['filePath'] ?? result['file_path'];
    if (path is String && path.isNotEmpty) {
      return path;
    }
    final data = result['file'] ?? result['path'];
    return data is String && data.isNotEmpty ? data : null;
  }
}

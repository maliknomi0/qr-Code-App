import '../../core/functional/result.dart';
import '../repositories/export_repository.dart';

class SaveToGalleryUc {
  SaveToGalleryUc(this._repository);

  final ExportRepository _repository;

  Future<Result<String>> call(
    List<int> bytes, {
    required String fileName,
  }) {
    return _repository.saveToGallery(bytes, fileName: fileName);
  }
}

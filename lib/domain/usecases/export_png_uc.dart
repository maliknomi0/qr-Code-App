import '../../core/functional/result.dart';
import '../repositories/export_repository.dart';

class ExportPngUc {
  ExportPngUc(this._repository);

  final ExportRepository _repository;

  Future<Result<String>> call(List<int> bytes, {required String fileName}) {
    return _repository.exportPng(bytes, fileName: fileName);
  }
}

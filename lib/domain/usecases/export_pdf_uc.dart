import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import '../repositories/export_repository.dart';

class ExportPdfUc {
  ExportPdfUc(this._repository);

  final ExportRepository _repository;

  Future<Result<String>> call(List<QrItem> items, {required String fileName}) {
    return _repository.exportPdf(items, fileName: fileName);
  }
}

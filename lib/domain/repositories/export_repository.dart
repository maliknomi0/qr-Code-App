import '../../core/functional/result.dart';
import '../entities/qr_item.dart';

abstract class ExportRepository {
  Future<Result<String>> exportPng(List<int> bytes, {required String fileName});
  Future<Result<String>> exportPdf(List<QrItem> items, {required String fileName});
  Future<Result<String>> saveToGallery(List<int> bytes, {required String fileName});
}

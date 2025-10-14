import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import 'export_repository.dart';

abstract class HistoryRepository implements ExportRepository {
  Future<Result<List<QrItem>>> fetchAll();
  Future<Result<void>> save(QrItem item);
  Future<Result<void>> toggleFavorite(String id);
  Future<Result<void>> delete(String id);
}

import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import '../repositories/history_repository.dart';

class FetchHistoryUc {
  FetchHistoryUc(this._repository);

  final HistoryRepository _repository;

  Future<Result<List<QrItem>>> call() => _repository.fetchAll();
}

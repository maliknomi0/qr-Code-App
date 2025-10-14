import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import '../repositories/history_repository.dart';

class SaveItemUc {
  SaveItemUc(this._repository);

  final HistoryRepository _repository;

  Future<Result<void>> call(QrItem item) => _repository.save(item);
}

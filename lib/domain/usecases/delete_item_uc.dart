import '../../core/functional/result.dart';
import '../repositories/history_repository.dart';

class DeleteItemUc {
  DeleteItemUc(this._repository);

  final HistoryRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

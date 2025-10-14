import '../../core/functional/result.dart';
import '../repositories/history_repository.dart';

class ToggleFavoriteUc {
  ToggleFavoriteUc(this._repository);

  final HistoryRepository _repository;

  Future<Result<void>> call(String id) => _repository.toggleFavorite(id);
}

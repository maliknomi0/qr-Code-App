import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import '../repositories/scan_repository.dart';

class DecodeImageUc {
  DecodeImageUc(this._repository);

  final ScanRepository _repository;

  Future<Result<QrItem>> call(String path) => _repository.decodeFromImage(path);
}

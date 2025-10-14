import '../../core/functional/result.dart';
import '../entities/qr_item.dart';
import '../repositories/scan_repository.dart';

class ScanCodeUc {
  ScanCodeUc(this._repository);

  final ScanRepository _repository;

  Future<Result<QrItem>> call() => _repository.scanLive();
}

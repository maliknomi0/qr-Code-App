import '../../core/functional/result.dart';
import '../entities/qr_item.dart';

abstract class ScanRepository {
  Future<Result<QrItem>> scanLive();
  Future<Result<QrItem>> decodeFromImage(String path);
}

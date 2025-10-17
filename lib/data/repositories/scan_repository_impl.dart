import '../../core/error/app_error.dart';
import '../../core/functional/result.dart';
import '../../core/logging/logger.dart';
import '../../domain/entities/qr_item.dart';
import '../../domain/entities/qr_source.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/value_objects/non_empty_string.dart';
import '../../domain/value_objects/uuid.dart';

class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl(this._logger);

  final AppLogger _logger;

  @override
  Future<Result<QrItem>> scanLive() async {
    // In a real implementation this would bridge camera events.
    return Err(CameraError('Live scanning is handled directly by the UI layer'));
  }

  @override
  Future<Result<QrItem>> decodeFromImage(String path) async {
    try {
      _logger.info('Decoding image at $path');
      final data = NonEmptyString('Decoded from $path');
      final item = QrItem(
        id: Uuid.generate(),
        type: QrType.text,
        data: data,
        createdAt: DateTime.now(),
        source: QrSource.scanned,
      );
      return Ok(item);
    } catch (error, stackTrace) {
      _logger.error('Failed to decode image', error, stackTrace);
      return Err(UnknownAppError('Unable to decode image', error));
    }
  }
}

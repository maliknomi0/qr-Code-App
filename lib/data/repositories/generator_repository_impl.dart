import 'dart:typed_data';

import 'package:qr_flutter/qr_flutter.dart';

import '../../core/error/app_error.dart';
import '../../core/functional/result.dart';
import '../../core/logging/logger.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/repositories/generator_repository.dart';

class GeneratorRepositoryImpl implements GeneratorRepository {
  GeneratorRepositoryImpl(this._logger);

  final AppLogger _logger;

  @override
  Future<Result<List<int>>> generatePng({required String data, required QrType type}) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
      );
      final imageData = await painter.toImageData(2048);
      if (imageData == null) {
        return Err(UnknownAppError('Failed to generate QR image'));
      }
      return Ok(Uint8List.view(imageData.buffer));
    } catch (error, stackTrace) {
      _logger.error('Generate QR failed', error, stackTrace);
      return Err(UnknownAppError('Unable to generate QR code', error));
    }
  }
}

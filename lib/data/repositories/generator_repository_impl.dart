import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../../core/error/app_error.dart';
import '../../core/functional/result.dart';
import '../../core/logging/logger.dart';
import '../../domain/entities/qr_customization.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/repositories/generator_repository.dart';

class GeneratorRepositoryImpl implements GeneratorRepository {
  GeneratorRepositoryImpl(this._logger);

  final AppLogger _logger;

  @override
  Future<Result<List<int>>> generatePng({
    required String data,
    required QrType type,
    QrCustomization customization = const QrCustomization(),
  }) async {
    try {
      final color = Color(customization.foregroundColor);
      final background = Color(customization.backgroundColor);
      final logoBytes = customization.logoBytes;
      final logoScale = customization.logoScale.clamp(0.1, 0.35).toDouble();
      final embeddedStyle = logoBytes == null
          ? null
          : QrEmbeddedImageStyle(
              size: Size.square(customization.size * logoScale),
            );

      ui.Image? embeddedImage;
      if (logoBytes != null) {
        final codec = await instantiateImageCodec(Uint8List.fromList(logoBytes));
        final frame = await codec.getNextFrame();
        embeddedImage = frame.image;
      }

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: customization.gapless,
        errorCorrectionLevel: _mapCorrection(customization.errorCorrection),
        color: color,
        emptyColor: background,
        eyeStyle: _eyeStyleFor(customization.design, color) ?? QrEyeStyle(color: color),
        dataModuleStyle: _moduleStyleFor(customization.design, color) ?? QrDataModuleStyle(color: color),
        embeddedImage: embeddedImage,
        embeddedImageStyle: embeddedStyle,
      );
      final imageData = await painter.toImageData(
        customization.size.toDouble(),
      );
      if (imageData == null) {
        return Err(UnknownAppError('Failed to generate QR image'));
      }
      return Ok(Uint8List.view(imageData.buffer));
    } catch (error, stackTrace) {
      _logger.error('Generate QR failed', error, stackTrace);
      return Err(UnknownAppError('Unable to generate QR code', error));
    }
  }

  int _mapCorrection(QrErrorCorrection level) {
    switch (level) {
      case QrErrorCorrection.low:
        return QrErrorCorrectLevel.L;
      case QrErrorCorrection.medium:
        return QrErrorCorrectLevel.M;
      case QrErrorCorrection.quartile:
        return QrErrorCorrectLevel.Q;
      case QrErrorCorrection.high:
        return QrErrorCorrectLevel.H;
    }
  }

  QrEyeStyle? _eyeStyleFor(QrDesign design, Color color) {
    switch (design) {
      case QrDesign.classic:
        return null;
      case QrDesign.roundedModules:
        return null;
      case QrDesign.roundedEyes:
        return QrEyeStyle(color: color, eyeShape: QrEyeShape.circle);
      case QrDesign.roundedAll:
        return QrEyeStyle(color: color, eyeShape: QrEyeShape.circle);
    }
  }

  QrDataModuleStyle? _moduleStyleFor(QrDesign design, Color color) {
    switch (design) {
      case QrDesign.classic:
        return null;
      case QrDesign.roundedEyes:
        return null;
      case QrDesign.roundedModules:
        return QrDataModuleStyle(
          color: color,
          dataModuleShape: QrDataModuleShape.circle,
        );
      case QrDesign.roundedAll:
        return QrDataModuleStyle(
          color: color,
          dataModuleShape: QrDataModuleShape.circle,
        );
    }
  }
}

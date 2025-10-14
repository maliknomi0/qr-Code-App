/// Configuration options used when creating a QR code image.
class QrCustomization {
  const QrCustomization({
    this.foregroundColor = 0xFF000000,
    this.backgroundColor = 0xFFFFFFFF,
    this.errorCorrection = QrErrorCorrection.medium,
    this.gapless = true,
    this.size = 1024,
  });

  /// The primary color of the QR code modules.
  final int foregroundColor;

  /// The background color that surrounds the QR code.
  final int backgroundColor;

  /// The error correction level applied when generating the QR code image.
  final QrErrorCorrection errorCorrection;

  /// Controls whether empty spaces between modules are removed.
  final bool gapless;

  /// Pixel size of the generated image.
  final int size;

  QrCustomization copyWith({
    int? foregroundColor,
    int? backgroundColor,
    QrErrorCorrection? errorCorrection,
    bool? gapless,
    int? size,
  }) {
    return QrCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      gapless: gapless ?? this.gapless,
      size: size ?? this.size,
    );
  }
}

/// Available error correction levels for the QR generation process.
enum QrErrorCorrection { low, medium, quartile, high }

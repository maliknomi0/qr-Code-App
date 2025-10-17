/// Configuration options used when creating a QR code image.
class QrCustomization {
  const QrCustomization({
    this.foregroundColor = 0xFF000000,
    this.backgroundColor = 0xFFFFFFFF,
    this.errorCorrection = QrErrorCorrection.medium,
    this.gapless = true,
    this.size = 1024,
    this.design = QrDesign.classic,
    this.logoBytes,
    this.logoScale = 0.22,
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

  /// The overall styling preset applied to the QR modules and eyes.
  final QrDesign design;

  /// Optional logo that will be embedded at the centre of the QR code.
  final List<int>? logoBytes;

  /// Desired footprint of the logo relative to the QR size (0-1 range).
  final double logoScale;

  static const Object _sentinel = Object();

  QrCustomization copyWith({
    int? foregroundColor,
    int? backgroundColor,
    QrErrorCorrection? errorCorrection,
    bool? gapless,
    int? size,
    QrDesign? design,
    Object? logoBytes = _sentinel,
    double? logoScale,
  }) {
    return QrCustomization(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      gapless: gapless ?? this.gapless,
      size: size ?? this.size,
      design: design ?? this.design,
      logoBytes:
          identical(logoBytes, _sentinel) ? this.logoBytes : logoBytes as List<int>?,
      logoScale: logoScale ?? this.logoScale,
    );
  }
}

/// Available error correction levels for the QR generation process.
enum QrErrorCorrection { low, medium, quartile, high }

/// Curated module + eye combinations that deliver distinct looks.
enum QrDesign {
  /// Default square modules and square eyes.
  classic,

  /// Rounded eyes with classic square modules.
  roundedEyes,

  /// Rounded modules with square eyes.
  roundedModules,

  /// Both modules and eyes use circular styling.
  roundedAll,
}

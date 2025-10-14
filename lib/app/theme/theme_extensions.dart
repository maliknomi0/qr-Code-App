import 'package:flutter/material.dart';

@immutable
class EmphasisColors extends ThemeExtension<EmphasisColors> {
  const EmphasisColors({
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color warning;
  final Color danger;

  @override
  ThemeExtension<EmphasisColors> lerp(ThemeExtension<EmphasisColors>? other, double t) {
    if (other is! EmphasisColors) return this;
    return EmphasisColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }

  @override
  EmphasisColors copyWith({Color? success, Color? warning, Color? danger}) {
    return EmphasisColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  static EmphasisColors of(BuildContext context) {
    return Theme.of(context).extension<EmphasisColors>() ??
        const EmphasisColors(
          success: Color(0xFF12B76A),
          warning: Color(0xFFF79009),
          danger: Color(0xFFD92D20),
        );
  }
}

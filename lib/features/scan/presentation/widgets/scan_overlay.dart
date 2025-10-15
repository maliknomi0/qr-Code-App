import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final isLight = theme.brightness == Brightness.light;
          final colorScheme = theme.colorScheme;
          final size = constraints.biggest;
          final edge = math.min(size.width, size.height) * 0.80;
          final scrimColor = colorScheme.scrim;
          final highlightColor = isLight
              ? colorScheme.onInverseSurface
              : colorScheme.onSurface;
          final cornerColor = highlightColor.withOpacity(0.9);
          final frameShadow = scrimColor.withOpacity(isLight ? 0.35 : 0.6);
          final innerBorderColor = highlightColor.withOpacity(
            isLight ? 0.22 : 0.18,
          );
          final beamColor = highlightColor.withOpacity(0.85);

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: [
                      scrimColor.withOpacity(0),
                      scrimColor.withOpacity(isLight ? 0.45 : 0.6),
                      scrimColor.withOpacity(isLight ? 0.65 : 0.8),
                    ],
                    stops: const [0.5, 0.82, 1],
                    center: Alignment.center,
                  ),
                ),
              ),
              Align(
                child: Container(
                  width: edge,
                  height: edge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: cornerColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: frameShadow,
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: innerBorderColor),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final position =
                              (_controller.value * 2) - 1; // -1 to 1
                          return Align(
                            alignment: Alignment(0, position),
                            child: Container(
                              height: 8,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    beamColor.withOpacity(0),
                                    beamColor,
                                    beamColor.withOpacity(0),
                                  ],
                                  stops: const [0, 0.5, 1],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

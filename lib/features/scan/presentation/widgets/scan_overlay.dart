import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
        ),
        margin: const EdgeInsets.all(48),
      ),
    );
  }
}

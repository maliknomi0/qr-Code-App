import 'package:mobile_scanner/mobile_scanner.dart';

class CameraScanner {
  CameraScanner();

  final MobileScannerController controller = MobileScannerController();

  void dispose() {
    controller.dispose();
  }
}

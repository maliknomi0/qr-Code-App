import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';
import '../../data/repositories/generator_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/repositories/generator_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/usecases/decode_image_uc.dart';
import '../../domain/usecases/delete_item_uc.dart';
import '../../domain/usecases/export_pdf_uc.dart';
import '../../domain/usecases/export_png_uc.dart';
import '../../domain/usecases/fetch_history_uc.dart';
import '../../domain/usecases/generate_qr_uc.dart';
import '../../domain/usecases/save_item_uc.dart';
import '../../domain/usecases/save_to_gallery_uc.dart';
import '../../domain/usecases/scan_code_uc.dart';
import '../../domain/usecases/toggle_favorite_uc.dart';
import '../../features/generate/application/generate_vm.dart';
import '../../features/history/application/history_vm.dart';
import '../../features/scan/application/scan_vm.dart';
import '../../features/settings/application/settings_vm.dart';
import '../router.dart';

final appRouterProvider = Provider((ref) => buildAppRouter(ref));

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(ref.read(loggerProvider));
});

final generatorRepositoryProvider = Provider<GeneratorRepository>((ref) {
  return GeneratorRepositoryImpl(ref.read(loggerProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.read(loggerProvider));
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ref.read(historyRepositoryProvider);
});

final scanCodeUcProvider = Provider((ref) => ScanCodeUc(ref.read(scanRepositoryProvider)));
final decodeImageUcProvider = Provider((ref) => DecodeImageUc(ref.read(scanRepositoryProvider)));
final generateQrUcProvider = Provider((ref) => GenerateQrUc(ref.read(generatorRepositoryProvider)));
final saveItemUcProvider = Provider((ref) => SaveItemUc(ref.read(historyRepositoryProvider)));
final saveToGalleryUcProvider = Provider((ref) => SaveToGalleryUc(ref.read(exportRepositoryProvider)));
final fetchHistoryUcProvider = Provider((ref) => FetchHistoryUc(ref.read(historyRepositoryProvider)));
final toggleFavoriteUcProvider = Provider((ref) => ToggleFavoriteUc(ref.read(historyRepositoryProvider)));
final deleteItemUcProvider = Provider((ref) => DeleteItemUc(ref.read(historyRepositoryProvider)));
final exportPngUcProvider = Provider((ref) => ExportPngUc(ref.read(exportRepositoryProvider)));
final exportPdfUcProvider = Provider((ref) => ExportPdfUc(ref.read(exportRepositoryProvider)));

final scanVmProvider = StateNotifierProvider.autoDispose<ScanVm, ScanState>((ref) {
  return ScanVm(
    ref.read(scanCodeUcProvider),
    ref.read(saveItemUcProvider),
    ref.read(fetchHistoryUcProvider),
  );
});

final generateVmProvider = StateNotifierProvider.autoDispose<GenerateVm, GenerateState>((ref) {
  return GenerateVm(
    ref.read(generateQrUcProvider),
    ref.read(saveItemUcProvider),
    ref.read(exportPngUcProvider),
    ref.read(saveToGalleryUcProvider),
  );
});

final historyVmProvider = StateNotifierProvider<HistoryVm, HistoryState>((ref) {
  return HistoryVm(
    ref.read(fetchHistoryUcProvider),
    ref.read(toggleFavoriteUcProvider),
    ref.read(deleteItemUcProvider),
    ref.read(exportPdfUcProvider),
  );
});

final settingsVmProvider = StateNotifierProvider<SettingsVm, SettingsState>((ref) {
  return SettingsVm(ref.read(historyRepositoryProvider));
});

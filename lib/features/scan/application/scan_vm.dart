import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/functional/result.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';
import '../../../domain/usecases/fetch_history_uc.dart';
import '../../../domain/usecases/save_item_uc.dart';
import '../../../domain/usecases/scan_code_uc.dart';
import '../../../domain/value_objects/non_empty_string.dart';
import '../../../domain/value_objects/uuid.dart';

class ScanState {
  const ScanState({
    this.isProcessing = false,
    this.lastItem,
    this.error,
  });

  final bool isProcessing;
  final QrItem? lastItem;
  final AppError? error;

  ScanState copyWith({bool? isProcessing, QrItem? lastItem, AppError? error}) {
    return ScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastItem: lastItem ?? this.lastItem,
      error: error,
    );
  }
}

class ScanVm extends StateNotifier<ScanState> {
  ScanVm(this._scanCode, this._saveItem, this._fetchHistory) : super(const ScanState());

  final ScanCodeUc _scanCode;
  final SaveItemUc _saveItem;
  final FetchHistoryUc _fetchHistory;

  Future<void> start() async {
    state = state.copyWith(isProcessing: true, error: null);
    final result = await _scanCode();
    state = state.copyWith(isProcessing: false);
    if (result is Err<QrItem>) {
      state = state.copyWith(error: result.error);
    }
  }

  Future<void> onRawDetection(String rawValue) async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final item = QrItem(
        id: Uuid.generate(),
        type: _inferType(rawValue),
        data: NonEmptyString(rawValue),
        createdAt: DateTime.now(),
      );
      final result = await _saveItem(item);
      state = state.copyWith(
        isProcessing: false,
        lastItem: item,
        error: result.errorOrNull,
      );
    } on AppError catch (error) {
      state = state.copyWith(isProcessing: false, error: error);
    }
  }

  Future<List<QrItem>> loadHistory() async {
    final res = await _fetchHistory();
    return res.when(
      ok: (value) => value,
      err: (error) {
        state = state.copyWith(error: error);
        return const [];
      },
    );
  }

  QrType _inferType(String value) {
    if (value.startsWith('http')) return QrType.url;
    if (value.startsWith('WIFI')) return QrType.wifi;
    if (value.startsWith('BEGIN:VCARD')) return QrType.vcard;
    return QrType.text;
  }
}

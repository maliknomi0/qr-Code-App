import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code/core/error/app_error.dart';
import 'package:qr_code/core/functional/result.dart';

import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_source.dart';
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
  ScanVm(
    this._scanCode,
    this._saveItem,
    this._fetchHistory,
    this._autoSaveEnabled,
  ) : super(const ScanState());

  final ScanCodeUc _scanCode;
  final SaveItemUc _saveItem;
  final FetchHistoryUc _fetchHistory;
  final bool Function() _autoSaveEnabled;

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
        source: QrSource.scanned,
      );
      if (_autoSaveEnabled()) {
        final result = await _saveItem(item);
        state = state.copyWith(
          isProcessing: false,
          lastItem: item,
          error: result.errorOrNull,
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          lastItem: item,
        );
      }
    } on AppError catch (error) {
      state = state.copyWith(isProcessing: false, error: error);
    }
  }

  Future<AppError?> saveItem(QrItem item) async {
    final result = await _saveItem(item);
    if (result.isErr) {
      state = state.copyWith(error: result.errorOrNull);
    }
    return result.errorOrNull;
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
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return QrType.url;
    }
    if (value.startsWith('WIFI')) return QrType.wifi;
    if (value.startsWith('BEGIN:VCARD')) return QrType.vcard;
    if (lower.startsWith('mailto:') || value.startsWith('MATMSG:')) {
      return QrType.email;
    }
    if (lower.startsWith('tel:') || value.startsWith('TEL:')) {
      return QrType.phone;
    }
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) {
      return QrType.sms;
    }
    return QrType.text;
  }
}
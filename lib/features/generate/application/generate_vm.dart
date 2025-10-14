import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/functional/result.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';
import '../../../domain/usecases/export_png_uc.dart';
import '../../../domain/usecases/generate_qr_uc.dart';
import '../../../domain/usecases/save_item_uc.dart';
import '../../../domain/value_objects/non_empty_string.dart';
import '../../../domain/value_objects/uuid.dart';

class GenerateState {
  const GenerateState({
    this.data = '',
    this.pngBytes,
    this.error,
    this.isSaving = false,
  });

  final String data;
  final List<int>? pngBytes;
  final AppError? error;
  final bool isSaving;

  GenerateState copyWith({
    String? data,
    List<int>? pngBytes,
    AppError? error,
    bool? isSaving,
  }) {
    return GenerateState(
      data: data ?? this.data,
      pngBytes: pngBytes ?? this.pngBytes,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class GenerateVm extends StateNotifier<GenerateState> {
  GenerateVm(this._generate, this._saveItem, this._exportPng) : super(const GenerateState());

  final GenerateQrUc _generate;
  final SaveItemUc _saveItem;
  final ExportPngUc _exportPng;

  Future<void> updateData(String data) async {
    state = state.copyWith(data: data, error: null);
    if (data.isEmpty) {
      state = state.copyWith(pngBytes: null);
      return;
    }
    final result = await _generate(data: data, type: _inferType(data));
    state = state.copyWith(
      pngBytes: result.valueOrNull,
      error: result.errorOrNull,
    );
  }

  Future<void> saveToHistory() async {
    final png = state.pngBytes;
    if (png == null || state.data.isEmpty) return;
    state = state.copyWith(isSaving: true);
    try {
      final item = QrItem(
        id: Uuid.generate(),
        type: _inferType(state.data),
        data: NonEmptyString(state.data),
        createdAt: DateTime.now(),
      );
      final result = await _saveItem(item);
      state = state.copyWith(
        isSaving: false,
        error: result.errorOrNull,
      );
    } on AppError catch (error) {
      state = state.copyWith(isSaving: false, error: error);
    }
  }

  Future<String?> exportPng() async {
    final png = state.pngBytes;
    if (png == null) return null;
    final res = await _exportPng(png, fileName: 'qr_${DateTime.now().millisecondsSinceEpoch}');
    return res.valueOrNull;
  }

  QrType _inferType(String value) {
    if (value.startsWith('http')) return QrType.url;
    if (value.startsWith('WIFI')) return QrType.wifi;
    if (value.startsWith('BEGIN:VCARD')) return QrType.vcard;
    return QrType.text;
  }
}

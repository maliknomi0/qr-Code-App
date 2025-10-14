import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/functional/result.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';
import '../../../domain/entities/qr_customization.dart';
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
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.errorCorrection = QrErrorCorrection.medium,
    this.gapless = true,
    this.pixelSize = 1024,
  });

  final String data;
  final List<int>? pngBytes;
  final AppError? error;
  final bool isSaving;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrErrorCorrection errorCorrection;
  final bool gapless;
  final double pixelSize;

  static const Object _sentinel = Object();

  GenerateState copyWith({
    String? data,
    Object? pngBytes = _sentinel,
    Object? error = _sentinel,
    bool? isSaving,
    Color? foregroundColor,
    Color? backgroundColor,
    QrErrorCorrection? errorCorrection,
    bool? gapless,
    double? pixelSize,
  }) {
    return GenerateState(
      data: data ?? this.data,
      pngBytes: identical(pngBytes, _sentinel) ? this.pngBytes : pngBytes as List<int>?,
      error: identical(error, _sentinel) ? this.error : error as AppError?,
      isSaving: isSaving ?? this.isSaving,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      gapless: gapless ?? this.gapless,
      pixelSize: pixelSize ?? this.pixelSize,
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
    await _regenerate();
  }

  Future<void> saveToHistory() async {
    final png = state.pngBytes;
    final data = state.data.trim();
    if (png == null || data.isEmpty) return;
    state = state.copyWith(isSaving: true);
    try {
      final item = QrItem(
        id: Uuid.generate(),
        type: _inferType(data),
        data: NonEmptyString(data),
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

  Future<void> updateForegroundColor(Color color) async {
    if (color.value == state.foregroundColor.value) return;
    state = state.copyWith(foregroundColor: color, error: null);
    await _regenerate();
  }

  Future<void> updateBackgroundColor(Color color) async {
    if (color.value == state.backgroundColor.value) return;
    state = state.copyWith(backgroundColor: color, error: null);
    await _regenerate();
  }

  Future<void> updateErrorCorrection(QrErrorCorrection level) async {
    if (level == state.errorCorrection) return;
    state = state.copyWith(errorCorrection: level, error: null);
    await _regenerate();
  }

  Future<void> updateGapless(bool value) async {
    if (value == state.gapless) return;
    state = state.copyWith(gapless: value, error: null);
    await _regenerate();
  }

  void updatePixelSize(double value, {bool regenerate = true}) {
    final normalized = value.clamp(512, 2048).toDouble();
    if (normalized != state.pixelSize) {
      state = state.copyWith(pixelSize: normalized, error: null);
    }
    if (regenerate) {
      unawaited(_regenerate());
    }
  }

  Future<void> _regenerate() async {
    final trimmed = state.data.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(pngBytes: null, error: null);
      return;
    }
    final result = await _generate(
      data: trimmed,
      type: _inferType(trimmed),
      customization: QrCustomization(
        foregroundColor: state.foregroundColor.value,
        backgroundColor: state.backgroundColor.value,
        errorCorrection: state.errorCorrection,
        gapless: state.gapless,
        size: state.pixelSize.round(),
      ),
    );
    state = state.copyWith(
      pngBytes: result.valueOrNull,
      error: result.errorOrNull,
    );
  }

  QrType _inferType(String value) {
    if (value.startsWith('http')) return QrType.url;
    if (value.startsWith('WIFI')) return QrType.wifi;
    if (value.startsWith('BEGIN:VCARD')) return QrType.vcard;
    return QrType.text;
  }
}

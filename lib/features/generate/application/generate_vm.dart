import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code/domain/entities/qr_source.dart';

import '../../../core/error/app_error.dart';
import '../../../core/functional/result.dart';
import '../../../domain/entities/qr_customization.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/entities/qr_type.dart';
import '../../../domain/usecases/export_png_uc.dart';
import '../../../domain/usecases/generate_qr_uc.dart';
import '../../../domain/usecases/save_item_uc.dart';
import '../../../domain/usecases/save_to_gallery_uc.dart';
import '../../../domain/value_objects/non_empty_string.dart';
import '../../../domain/value_objects/uuid.dart';

class GenerateState {
  const GenerateState({
    this.data = '',
    this.contentType = QrType.text,
    this.pngBytes,
    this.error,
    this.isSaving = false,
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.errorCorrection = QrErrorCorrection.medium,
    this.gapless = true,
    this.pixelSize = 1024,
    this.design = QrDesign.classic,
    this.logoBytes,
    this.logoFileName,
    this.logoScale = 0.22,
  });

  final String data;
  final QrType contentType;
  final List<int>? pngBytes;
  final AppError? error;
  final bool isSaving;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrErrorCorrection errorCorrection;
  final bool gapless;
  final double pixelSize;
  final QrDesign design;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final double logoScale;

  static const Object _sentinel = Object();

  GenerateState copyWith({
    String? data,
    QrType? contentType,
    Object? pngBytes = _sentinel,
    Object? error = _sentinel,
    bool? isSaving,
    Color? foregroundColor,
    Color? backgroundColor,
    QrErrorCorrection? errorCorrection,
    bool? gapless,
    double? pixelSize,
    QrDesign? design,
    Object? logoBytes = _sentinel,
    Object? logoFileName = _sentinel,
    double? logoScale,
  }) {
    return GenerateState(
      data: data ?? this.data,
      contentType: contentType ?? this.contentType,
      pngBytes: identical(pngBytes, _sentinel)
          ? this.pngBytes
          : pngBytes as List<int>?,
      error: identical(error, _sentinel) ? this.error : error as AppError?,
      isSaving: isSaving ?? this.isSaving,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      gapless: gapless ?? this.gapless,
      pixelSize: pixelSize ?? this.pixelSize,
      design: design ?? this.design,
      logoBytes: identical(logoBytes, _sentinel)
          ? this.logoBytes
          : logoBytes as Uint8List?,
      logoFileName: identical(logoFileName, _sentinel)
          ? this.logoFileName
          : logoFileName as String?,
      logoScale: logoScale ?? this.logoScale,
    );
  }
}

class GenerateVm extends StateNotifier<GenerateState> {
  GenerateVm(
    this._generate,
    this._saveItem,
    this._exportPng,
    this._saveToGallery,
    this._autoSaveGeneratedEnabled,
  ) : super(const GenerateState());

  final GenerateQrUc _generate;
  final SaveItemUc _saveItem;
  final ExportPngUc _exportPng;
  final SaveToGalleryUc _saveToGallery;
  final bool Function() _autoSaveGeneratedEnabled;
  bool _autoSaving = false;
  String? _lastAutoSavedSignature;

  Future<void> updateContent(QrType type, String data) async {
    final sanitized = type == QrType.text ? data : data.trim();
    if (sanitized == state.data && type == state.contentType) return;
    state = state.copyWith(data: sanitized, contentType: type, error: null);
    await _regenerate();
  }

  Future<void> updateData(String data) async {
    state = state.copyWith(data: data, error: null);
    await _regenerate();
  }

  Future<String?> saveToHistory() async {
    final png = state.pngBytes;
    final data = state.data.trim();
    if (png == null || data.isEmpty) return null;
    state = state.copyWith(isSaving: true);
    try {
      final item = QrItem(
        id: Uuid.generate(),
        type: state.contentType,
        data: NonEmptyString(data),
        createdAt: DateTime.now(),
        source: QrSource.generated,
      );
      final result = await _saveItem(item);
      if (result.isErr) {
        state = state.copyWith(isSaving: false, error: result.errorOrNull);
        return null;
      }
      _lastAutoSavedSignature = _contentSignature(state.contentType, data);

      final galleryResult = await _saveToGallery(
        png,
        fileName: 'qr_${item.id.value}',
      );
      state = state.copyWith(isSaving: false, error: galleryResult.errorOrNull);
      return galleryResult.valueOrNull;
    } on AppError catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      return null;
    }
  }

  Future<void> _autoSaveCurrent(String data, QrType type) async {
    if (!_autoSaveGeneratedEnabled()) return;
    if (state.pngBytes == null) return;
    if (_autoSaving) return;
    final signature = _contentSignature(type, data);
    if (_lastAutoSavedSignature == signature) return;
    _autoSaving = true;
    try {
      final item = QrItem(
        id: Uuid.generate(),
        type: type,
        data: NonEmptyString(data),
        createdAt: DateTime.now(),
        source: QrSource.generated,
      );
      final result = await _saveItem(item);
      if (result.isErr) {
        state = state.copyWith(error: result.errorOrNull);
        return;
      }
      _lastAutoSavedSignature = signature;
    } on AppError catch (error) {
      state = state.copyWith(error: error);
    } finally {
      _autoSaving = false;
    }
  }

  Future<String?> exportPng() async {
    final png = state.pngBytes;
    if (png == null) return null;
    final res = await _exportPng(
      png,
      fileName: 'qr_${DateTime.now().millisecondsSinceEpoch}',
    );
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

  Future<void> updateDesign(QrDesign design) async {
    if (design == state.design) return;
    state = state.copyWith(design: design, error: null);
    await _regenerate();
  }

  Future<void> updateLogo(Uint8List? bytes, {String? fileName}) async {
    state = state.copyWith(
      logoBytes: bytes,
      logoFileName: fileName,
      error: null,
    );
    await _regenerate();
  }

  void updateLogoScale(double value, {bool regenerate = true}) {
    final normalized = value.clamp(0.12, 0.32);
    if ((normalized - state.logoScale).abs() > 0.0005) {
      state = state.copyWith(logoScale: normalized, error: null);
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
      type: state.contentType,
      customization: QrCustomization(
        foregroundColor: state.foregroundColor.value,
        backgroundColor: state.backgroundColor.value,
        errorCorrection: state.errorCorrection,
        gapless: state.gapless,
        size: state.pixelSize.round(),
        design: state.design,
        logoBytes: state.logoBytes,
        logoScale: state.logoScale,
      ),
    );
    state = state.copyWith(
      pngBytes: result.valueOrNull,
      error: result.errorOrNull,
    );
    if (result.isOk) {
      unawaited(_autoSaveCurrent(trimmed, state.contentType));
    }
  }

  String _contentSignature(QrType type, String data) {
    return '${type.name}|$data';
  }
}

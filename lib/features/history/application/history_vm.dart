import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/functional/result.dart';
import '../../../domain/entities/qr_item.dart';
import '../../../domain/usecases/delete_item_uc.dart';
import '../../../domain/usecases/export_pdf_uc.dart';
import '../../../domain/usecases/fetch_history_uc.dart';
import '../../../domain/usecases/toggle_favorite_uc.dart';

class HistoryState {
  const HistoryState({
    this.items = const [],
    this.error,
    this.isLoading = false,
  });

  final List<QrItem> items;
  final AppError? error;
  final bool isLoading;

  HistoryState copyWith({List<QrItem>? items, AppError? error, bool? isLoading}) {
    return HistoryState(
      items: items ?? this.items,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HistoryVm extends StateNotifier<HistoryState> {
  HistoryVm(this._fetchHistory, this._toggleFavorite, this._deleteItem, this._exportPdf)
      : super(const HistoryState());

  final FetchHistoryUc _fetchHistory;
  final ToggleFavoriteUc _toggleFavorite;
  final DeleteItemUc _deleteItem;
  final ExportPdfUc _exportPdf;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _fetchHistory();
    state = state.copyWith(
      isLoading: false,
      items: result.valueOrNull ?? state.items,
      error: result.errorOrNull,
    );
  }

  Future<void> toggleFavorite(String id) async {
    final result = await _toggleFavorite(id);
    if (result.isErr) {
      state = state.copyWith(error: result.errorOrNull);
    } else {
      await load();
    }
  }

  Future<void> delete(String id) async {
    final result = await _deleteItem(id);
    if (result.isErr) {
      state = state.copyWith(error: result.errorOrNull);
    } else {
      await load();
    }
  }

  Future<String?> exportPdf() async {
    final result = await _exportPdf(state.items, fileName: 'qr_history');
    return result.valueOrNull;
  }
}

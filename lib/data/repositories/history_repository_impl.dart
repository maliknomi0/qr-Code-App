import 'package:hive/hive.dart';

import '../../core/error/app_error.dart';
import '../../core/functional/result.dart';
import '../../core/logging/logger.dart';
import '../../domain/entities/qr_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/qr_item_model.dart';
import '../sources/device/file_exporter.dart';
import '../sources/device/pdf_maker.dart';
import '../sources/local/hive_adapters.dart';
import '../sources/local/hive_storage.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._logger)
    : _storage = HiveStorage(),
      _fileExporter = FileExporter(),
      _pdfMaker = PdfMaker();

  final AppLogger _logger;
  final HiveStorage _storage;
  final FileExporter _fileExporter;
  final PdfMaker _pdfMaker;

  Future<Box<QrItemModel>> _ensureBox() async {
    await registerHiveAdapters();
    return _storage.openHistoryBox();
  }

  @override
  Future<Result<List<QrItem>>> fetchAll() async {
    try {
      final box = await _ensureBox();
      final items = box.values.map((model) => model.toEntity()).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Ok(items);
    } catch (error, stackTrace) {
      _logger.error('Fetch history failed', error, stackTrace);
      return Err(StorageError('Unable to load history', error));
    }
  }

  @override
  Future<Result<void>> save(QrItem item) async {
    try {
      final box = await _ensureBox();
      await box.put(item.id.value, QrItemModel.fromEntity(item));
      return const Ok(null);
    } catch (error, stackTrace) {
      _logger.error('Save history failed', error, stackTrace);
      return Err(StorageError('Unable to save item', error));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String id) async {
    try {
      final box = await _ensureBox();
      final model = box.get(id);
      if (model == null) {
        return Err(StorageError('Item not found'));
      }
      model.isFavorite = !model.isFavorite;
      await model.save();
      return const Ok(null);
    } catch (error, stackTrace) {
      _logger.error('Toggle favorite failed', error, stackTrace);
      return Err(StorageError('Unable to update favorite', error));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final box = await _ensureBox();
      await box.delete(id);
      return const Ok(null);
    } catch (error, stackTrace) {
      _logger.error('Delete history failed', error, stackTrace);
      return Err(StorageError('Unable to delete item', error));
    }
  }

  @override
  Future<Result<String>> exportPng(
    List<int> bytes, {
    required String fileName,
  }) async {
    try {
      final path = await _fileExporter.saveFile(bytes, '$fileName.png');
      return Ok(path);
    } catch (error, stackTrace) {
      _logger.error('PNG export failed', error, stackTrace);
      return Err(StorageError('Unable to export PNG', error));
    }
  }

  @override
  Future<Result<String>> saveToGallery(
    List<int> bytes, {
    required String fileName,
  }) async {
    try {
      final success = await _fileExporter.saveImageToGallery(bytes, fileName);
      if (!success) {
        return Err(StorageError('Unable to save image to gallery'));
      }
      return Ok(fileName);
    } catch (error, stackTrace) {
      _logger.error('Save to gallery failed', error, stackTrace);
      return Err(StorageError('Unable to save image to gallery', error));
    }
  }

  @override
  Future<Result<String>> exportPdf(
    List<QrItem> items, {
    required String fileName,
  }) async {
    try {
      final models = items.map(QrItemModel.fromEntity).toList();
      final data = await _pdfMaker.createHistoryPdf(models);
      final path = await _fileExporter.saveFile(data, '$fileName.pdf');
      return Ok(path);
    } catch (error, stackTrace) {
      _logger.error('PDF export failed', error, stackTrace);
      return Err(StorageError('Unable to export PDF', error));
    }
  }
}

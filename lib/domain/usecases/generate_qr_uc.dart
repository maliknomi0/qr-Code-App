import '../../core/functional/result.dart';
import '../entities/qr_customization.dart';
import '../entities/qr_type.dart';
import '../repositories/generator_repository.dart';

class GenerateQrUc {
  GenerateQrUc(this._repository);

  final GeneratorRepository _repository;

  Future<Result<List<int>>> call({
    required String data,
    required QrType type,
    QrCustomization customization = const QrCustomization(),
  }) {
    return _repository.generatePng(data: data, type: type, customization: customization);
  }
}

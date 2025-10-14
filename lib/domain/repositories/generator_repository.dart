import '../../core/functional/result.dart';
import '../entities/qr_type.dart';

abstract class GeneratorRepository {
  Future<Result<List<int>>> generatePng({required String data, required QrType type});
}

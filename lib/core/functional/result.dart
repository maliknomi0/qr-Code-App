import '../error/app_error.dart';

sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T value) ok, required R Function(AppError error) err});
}

class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  R when<R>({required R Function(T value) ok, required R Function(AppError error) err}) {
    return ok(value);
  }
}

class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;

  @override
  R when<R>({required R Function(T value) ok, required R Function(AppError error) err}) {
    return err(error);
  }
}

extension ResultX<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok(value: final value) => value,
        _ => null,
      };

  AppError? get errorOrNull => switch (this) {
        Err(error: final error) => error,
        _ => null,
      };
}

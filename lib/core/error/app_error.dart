sealed class AppError {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;
}

class ValidationError extends AppError {
  const ValidationError(String message) : super(message: message);
}

class StorageError extends AppError {
  const StorageError(String message, [Object? cause]) : super(message: message, cause: cause);
}

class CameraError extends AppError {
  const CameraError(String message, [Object? cause]) : super(message: message, cause: cause);
}

class UnknownAppError extends AppError {
  const UnknownAppError(String message, [Object? cause]) : super(message: message, cause: cause);
}

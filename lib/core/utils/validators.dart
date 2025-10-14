import '../error/app_error.dart';

typedef Validator<T> = T Function();

T validate<T>(Validator<T> validator) {
  try {
    return validator();
  } on AppError {
    rethrow;
  } catch (error) {
    throw ValidationError(error.toString());
  }
}

T guard<T>(T Function() body, {required T Function(Object error) onError}) {
  try {
    return body();
  } catch (error) {
    return onError(error);
  }
}

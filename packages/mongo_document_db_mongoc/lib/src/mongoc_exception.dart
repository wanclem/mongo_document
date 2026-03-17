final class MongocException implements Exception {
  MongocException(this.message);
  final String message;

  @override
  String toString() => 'MongocException: $message';
}


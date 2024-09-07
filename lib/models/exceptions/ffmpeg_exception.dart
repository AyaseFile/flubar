class FfmpegException implements Exception {
  final String message;

  FfmpegException(this.message);

  @override
  String toString() => message;
}

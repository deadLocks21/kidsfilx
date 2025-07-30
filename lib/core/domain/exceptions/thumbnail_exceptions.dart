abstract class ThumbnailException implements Exception {
  final String message;
  const ThumbnailException(this.message);

  @override
  String toString() => 'ThumbnailException: $message';
}

class ThumbnailGenerationException extends ThumbnailException {
  const ThumbnailGenerationException(super.message);

  @override
  String toString() => 'ThumbnailGenerationException: $message';
}

class ThumbnailStorageException extends ThumbnailException {
  const ThumbnailStorageException(super.message);

  @override
  String toString() => 'ThumbnailStorageException: $message';
}

class ThumbnailNotFoundException extends ThumbnailException {
  const ThumbnailNotFoundException(super.message);

  @override
  String toString() => 'ThumbnailNotFoundException: $message';
}
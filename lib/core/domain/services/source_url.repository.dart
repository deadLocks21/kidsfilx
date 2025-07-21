abstract class SourceUrlRepository {
  Future<SourceValidationResult> validateUrl(String sourceUrl);
}

class SourceValidationResult {
  final bool isValid;
  final String? sourceName;
  final String message;

  SourceValidationResult({
    required this.isValid,
    this.sourceName,
    required this.message,
  });
}

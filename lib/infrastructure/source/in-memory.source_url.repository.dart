import 'dart:math';

import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/core/domain/services/source_url.repository.dart';

class InMemorySourceRepository implements SourceUrlRepository {
  final List<Source> _sources = [];

  InMemorySourceRepository({List<Source>? initialSources}) {
    if (initialSources != null && initialSources.isNotEmpty) {
      _sources.addAll(initialSources);
    } else {
      _sources.add(
        Source(
          url: 'https://kidflix.example.com/tchoupi/volume1.json',
          name: 'Tchoupi Volume 1',
          episodeCount: 10,
        ),
      );
      _sources.add(
        Source(
          url: 'https://kidflix.example.com/tchoupi/volume2.json',
          name: 'Tchoupi Volume 2',
          episodeCount: 8,
        ),
      );
    }
  }

  @override
  Future<SourceValidationResult> validateUrl(String sourceUrl) async {
    final source = _sources.firstWhere((source) => source.url == sourceUrl);
    final isValid = _sources.any((source) => source.url == sourceUrl);
    await Future.delayed(Duration(milliseconds: Random().nextInt(3000)));

    if (isValid) {
      return SourceValidationResult(
        isValid: isValid,
        sourceName: source.name,
        message: 'Source valide - ${source.episodeCount} épisode(s) détecté(s)',
      );
    }

    return SourceValidationResult(
      isValid: isValid,
      message: 'Source non trouvée',
    );
  }
}

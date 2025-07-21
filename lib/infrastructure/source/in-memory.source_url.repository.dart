import 'dart:math';

import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/core/domain/services/source_url.repository.dart';

class InMemorySourceRepository implements SourceUrlRepository {
  final List<Source> _sources = [];
  final int _delay;

  InMemorySourceRepository({List<Source>? initialSources, int delay = 0})
    : _delay = delay {
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
    final source = _sources
        .where((source) => source.url == sourceUrl)
        .firstOrNull;
    final isValid = source != null;
    await Future.delayed(
      Duration(milliseconds: _delay != 0 ? _delay : Random().nextInt(3000)),
    );

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

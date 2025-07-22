import '../../core/domain/model/source.dart';
import '../../core/domain/services/source.repository.dart';

class InMemorySourceRepository implements SourceRepository {
  final List<Source> _sources = [];

  InMemorySourceRepository({List<Source>? initialSources}) {
    if (initialSources != null) {
      _sources.addAll(initialSources);
    } else {
      // Sources par défaut pour les tests
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
  Future<List<Source>> getAll() async {
    return List.from(_sources);
  }

  @override
  Future<void> saveAll(List<Source> sources) async {
    _sources.clear();
    _sources.addAll(sources);
  }
}

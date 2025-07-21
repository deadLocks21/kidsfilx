import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/source.repository.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/infrastructure/source/provider.source.repository.dart';

part 'save_all_sources_query.g.dart';

@riverpod
SaveAllSourcesQuery saveAllSourcesQuery(Ref ref) {
  return SaveAllSourcesQuery(ref.watch(sourceRepositoryProvider));
}

class SaveAllSourcesQuery {
  final SourceRepository _sourceRepository;

  SaveAllSourcesQuery(this._sourceRepository);

  Future<void> call(List<Source> sources) async {
    await _sourceRepository.saveAll(sources);
  }
}

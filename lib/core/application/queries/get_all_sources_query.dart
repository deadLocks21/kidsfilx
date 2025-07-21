import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/source.repository.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/infrastructure/source/provider.source.repository.dart';

part 'get_all_sources_query.g.dart';

@riverpod
GetAllSourcesQuery getAllSourcesQuery(Ref ref) {
  return GetAllSourcesQuery(ref.watch(sourceRepositoryProvider));
}

class GetAllSourcesQuery {
  final SourceRepository _sourceRepository;

  GetAllSourcesQuery(this._sourceRepository);

  Future<List<Source>> call() async {
    return await _sourceRepository.getAll();
  }
}

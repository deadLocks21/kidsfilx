import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidflix/core/domain/services/source.repository.dart';
import 'package:kidflix/core/domain/model/source.dart';
import 'package:kidflix/infrastructure/source/provider.source.repository.dart';

part 'save_all_sources_command.g.dart';

@riverpod
SaveAllSourcesCommand saveAllSourcesCommand(Ref ref) {
  return SaveAllSourcesCommand(ref.watch(sourceRepositoryProvider));
}

class SaveAllSourcesCommand {
  final SourceRepository _sourceRepository;

  SaveAllSourcesCommand(this._sourceRepository);

  Future<void> call(List<Source> sources) async {
    await _sourceRepository.saveAll(sources);
  }
}

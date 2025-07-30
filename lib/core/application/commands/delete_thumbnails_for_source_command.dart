import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/thumbnail.repository.dart';
import '../../../infrastructure/thumbnail/provider.thumbnail.repository.dart';

part 'delete_thumbnails_for_source_command.g.dart';

@riverpod
DeleteThumbnailsForSourceCommand deleteThumbnailsForSourceCommand(Ref ref) {
  final repository = ref.watch(thumbnailRepositoryProvider);
  return DeleteThumbnailsForSourceCommand(repository);
}

class DeleteThumbnailsForSourceCommand {
  final ThumbnailRepository _repository;

  const DeleteThumbnailsForSourceCommand(this._repository);

  Future<void> execute(String sourceName) async {
    await _repository.deleteThumbnailsForSource(sourceName);
  }
}
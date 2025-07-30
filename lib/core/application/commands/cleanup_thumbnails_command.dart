import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/thumbnail.repository.dart';
import '../../../infrastructure/thumbnail/provider.thumbnail.repository.dart';

part 'cleanup_thumbnails_command.g.dart';

@riverpod
CleanupThumbnailsCommand cleanupThumbnailsCommand(Ref ref) {
  final repository = ref.watch(thumbnailRepositoryProvider);
  return CleanupThumbnailsCommand(repository);
}

class CleanupThumbnailsCommand {
  final ThumbnailRepository _repository;

  const CleanupThumbnailsCommand(this._repository);

  Future<void> execute() async {
    await _repository.cleanupOrphanedThumbnails();
  }
}
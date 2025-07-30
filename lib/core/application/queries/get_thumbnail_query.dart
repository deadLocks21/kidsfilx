import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/model/thumbnail.dart';
import '../../domain/services/thumbnail.repository.dart';
import '../../../infrastructure/thumbnail/provider.thumbnail.repository.dart';

part 'get_thumbnail_query.g.dart';

@riverpod
GetThumbnailQuery getThumbnailQuery(Ref ref) {
  final repository = ref.watch(thumbnailRepositoryProvider);
  return GetThumbnailQuery(repository);
}

class GetThumbnailQuery {
  final ThumbnailRepository _repository;

  const GetThumbnailQuery(this._repository);

  Future<Thumbnail?> execute({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  }) async {
    return await _repository.getThumbnail(
      sourceName: sourceName,
      episodeName: episodeName,
      episodeIndex: episodeIndex,
    );
  }
}
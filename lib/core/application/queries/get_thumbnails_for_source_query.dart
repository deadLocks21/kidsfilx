import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/model/thumbnail.dart';
import '../../domain/services/thumbnail.repository.dart';
import '../../../infrastructure/thumbnail/provider.thumbnail.repository.dart';

part 'get_thumbnails_for_source_query.g.dart';

@riverpod
GetThumbnailsForSourceQuery getThumbnailsForSourceQuery(Ref ref) {
  final repository = ref.watch(thumbnailRepositoryProvider);
  return GetThumbnailsForSourceQuery(repository);
}

class GetThumbnailsForSourceQuery {
  final ThumbnailRepository _repository;

  const GetThumbnailsForSourceQuery(this._repository);

  Future<List<Thumbnail>> execute(String sourceName) async {
    return await _repository.getThumbnailsForSource(sourceName);
  }
}
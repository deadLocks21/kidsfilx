import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/domain/services/thumbnail.repository.dart';
import '../../shared/dependancy_injection.dart';
import 'in_memory.thumbnail.repository.dart';
import 'video_thumbnail_shared_preferences.thumbnail.repository.dart';

part 'provider.thumbnail.repository.g.dart';

@riverpod
ThumbnailRepository thumbnailRepository(Ref ref) {
  if (DependancyInjection.isProduction) {
    return VideoThumbnailSharedPreferencesRepository();
  }
  return InMemoryThumbnailRepository();
}

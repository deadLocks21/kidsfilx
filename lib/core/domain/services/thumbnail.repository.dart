import '../model/thumbnail.dart';

abstract class ThumbnailRepository {
  Future<Thumbnail> generateThumbnail({
    required String sourceName,
    required String episodeName,
    required String videoUrl,
    required int episodeIndex,
  });

  Future<Thumbnail?> getThumbnail({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  });

  Future<List<Thumbnail>> getThumbnailsForSource(String sourceName);

  Future<void> saveThumbnail(Thumbnail thumbnail);

  Future<void> deleteThumbnail(String thumbnailId);

  Future<void> deleteThumbnailsForSource(String sourceName);

  Future<bool> thumbnailExists({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  });

  Future<void> cleanupOrphanedThumbnails();
}

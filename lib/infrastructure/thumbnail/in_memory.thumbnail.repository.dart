import '../../core/domain/model/thumbnail.dart';
import '../../core/domain/services/thumbnail.repository.dart';

class InMemoryThumbnailRepository implements ThumbnailRepository {
  InMemoryThumbnailRepository._({List<Thumbnail>? initialThumbnails}) {
    if (initialThumbnails != null) {
      for (final thumbnail in initialThumbnails) {
        _thumbnails[thumbnail.id] = thumbnail;
      }
    }
  }

  static InMemoryThumbnailRepository? _instance;
  static final Map<String, Thumbnail> _thumbnails = {};

  factory InMemoryThumbnailRepository({List<Thumbnail>? initialThumbnails}) {
    _instance ??= InMemoryThumbnailRepository._(initialThumbnails: initialThumbnails);
    return _instance!;
  }

  static void reset() {
    _instance = null;
    _thumbnails.clear();
  }

  @override
  Future<Thumbnail> generateThumbnail({
    required String sourceName,
    required String episodeName,
    required String videoUrl,
    required int episodeIndex,
  }) async {
    final id = _generateThumbnailId(sourceName, episodeName, episodeIndex);
    final filePath = '/mock/path/thumbnail_$id.jpg';
    
    final thumbnail = Thumbnail(
      id: id,
      sourceName: sourceName,
      episodeName: episodeName,
      filePath: filePath,
      createdAt: DateTime.now(),
      episodeIndex: episodeIndex,
      isGenerated: true,
    );

    _thumbnails[id] = thumbnail;
    return thumbnail;
  }

  @override
  Future<Thumbnail?> getThumbnail({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  }) async {
    final id = _generateThumbnailId(sourceName, episodeName, episodeIndex);
    return _thumbnails[id];
  }

  @override
  Future<List<Thumbnail>> getThumbnailsForSource(String sourceName) async {
    return _thumbnails.values
        .where((thumbnail) => thumbnail.sourceName == sourceName)
        .toList();
  }

  @override
  Future<void> saveThumbnail(Thumbnail thumbnail) async {
    _thumbnails[thumbnail.id] = thumbnail;
  }

  @override
  Future<void> deleteThumbnail(String thumbnailId) async {
    _thumbnails.remove(thumbnailId);
  }

  @override
  Future<void> deleteThumbnailsForSource(String sourceName) async {
    _thumbnails.removeWhere(
      (key, thumbnail) => thumbnail.sourceName == sourceName,
    );
  }

  @override
  Future<bool> thumbnailExists({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  }) async {
    final id = _generateThumbnailId(sourceName, episodeName, episodeIndex);
    return _thumbnails.containsKey(id);
  }

  @override
  Future<void> cleanupOrphanedThumbnails() async {
    // In-memory implementation doesn't need cleanup
  }

  String _generateThumbnailId(String sourceName, String episodeName, int episodeIndex) {
    return '${sourceName}_${episodeName}_$episodeIndex'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}
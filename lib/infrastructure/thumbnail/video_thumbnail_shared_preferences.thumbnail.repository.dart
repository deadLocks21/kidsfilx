import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/domain/model/thumbnail.dart';
import '../../core/domain/services/thumbnail.repository.dart';
import '../../core/domain/exceptions/thumbnail_exceptions.dart';

class VideoThumbnailSharedPreferencesRepository implements ThumbnailRepository {
  static const String _thumbnailsKey = 'thumbnails_data';

  @override
  Future<Thumbnail> generateThumbnail({
    required String sourceName,
    required String episodeName,
    required String videoUrl,
    required int episodeIndex,
  }) async {
    try {
      final id = _generateThumbnailId(sourceName, episodeName, episodeIndex);
      final directory = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory('${directory.path}/thumbnails');
      
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      final filePath = '${thumbnailsDir.path}/$id.jpg';

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: filePath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );

      if (thumbnailPath == null) {
        throw const ThumbnailGenerationException('Failed to generate thumbnail');
      }

      final thumbnail = Thumbnail(
        id: id,
        sourceName: sourceName,
        episodeName: episodeName,
        filePath: thumbnailPath,
        createdAt: DateTime.now(),
        episodeIndex: episodeIndex,
        isGenerated: true,
      );

      await saveThumbnail(thumbnail);
      return thumbnail;
    } catch (e) {
      if (e is ThumbnailException) rethrow;
      throw ThumbnailGenerationException('Error generating thumbnail: $e');
    }
  }

  @override
  Future<Thumbnail?> getThumbnail({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  }) async {
    try {
      final thumbnails = await _loadThumbnails();
      final id = _generateThumbnailId(sourceName, episodeName, episodeIndex);
      
      final thumbnail = thumbnails[id];
      
      // Verify file still exists
      if (thumbnail != null && await File(thumbnail.filePath).exists()) {
        return thumbnail;
      } else if (thumbnail != null) {
        // File doesn't exist anymore, remove from storage
        await deleteThumbnail(id);
      }
      
      return null;
    } catch (e) {
      throw ThumbnailStorageException('Error retrieving thumbnail: $e');
    }
  }

  @override
  Future<List<Thumbnail>> getThumbnailsForSource(String sourceName) async {
    try {
      final thumbnails = await _loadThumbnails();
      final sourceThumbnails = thumbnails.values
          .where((thumbnail) => thumbnail.sourceName == sourceName)
          .toList();
      
      // Filter out thumbnails with missing files
      final validThumbnails = <Thumbnail>[];
      for (final thumbnail in sourceThumbnails) {
        if (await File(thumbnail.filePath).exists()) {
          validThumbnails.add(thumbnail);
        } else {
          await deleteThumbnail(thumbnail.id);
        }
      }
      
      return validThumbnails;
    } catch (e) {
      throw ThumbnailStorageException('Error retrieving thumbnails for source: $e');
    }
  }

  @override
  Future<void> saveThumbnail(Thumbnail thumbnail) async {
    try {
      final thumbnails = await _loadThumbnails();
      thumbnails[thumbnail.id] = thumbnail;
      await _saveThumbnails(thumbnails);
    } catch (e) {
      throw ThumbnailStorageException('Error saving thumbnail: $e');
    }
  }

  @override
  Future<void> deleteThumbnail(String thumbnailId) async {
    try {
      final thumbnails = await _loadThumbnails();
      final thumbnail = thumbnails[thumbnailId];
      
      if (thumbnail != null) {
        // Delete file
        final file = File(thumbnail.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from storage
        thumbnails.remove(thumbnailId);
        await _saveThumbnails(thumbnails);
      }
    } catch (e) {
      throw ThumbnailStorageException('Error deleting thumbnail: $e');
    }
  }

  @override
  Future<void> deleteThumbnailsForSource(String sourceName) async {
    try {
      final thumbnails = await _loadThumbnails();
      final toDelete = thumbnails.entries
          .where((entry) => entry.value.sourceName == sourceName)
          .toList();
      
      for (final entry in toDelete) {
        final file = File(entry.value.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        thumbnails.remove(entry.key);
      }
      
      await _saveThumbnails(thumbnails);
    } catch (e) {
      throw ThumbnailStorageException('Error deleting thumbnails for source: $e');
    }
  }

  @override
  Future<bool> thumbnailExists({
    required String sourceName,
    required String episodeName,
    required int episodeIndex,
  }) async {
    try {
      final thumbnail = await getThumbnail(
        sourceName: sourceName,
        episodeName: episodeName,
        episodeIndex: episodeIndex,
      );
      return thumbnail != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> cleanupOrphanedThumbnails() async {
    try {
      final thumbnails = await _loadThumbnails();
      final toRemove = <String>[];
      
      for (final entry in thumbnails.entries) {
        final file = File(entry.value.filePath);
        if (!await file.exists()) {
          toRemove.add(entry.key);
        }
      }
      
      for (final id in toRemove) {
        thumbnails.remove(id);
      }
      
      if (toRemove.isNotEmpty) {
        await _saveThumbnails(thumbnails);
      }
    } catch (e) {
      throw ThumbnailStorageException('Error cleaning up orphaned thumbnails: $e');
    }
  }

  Future<Map<String, Thumbnail>> _loadThumbnails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_thumbnailsKey);
      
      if (data == null) return {};
      
      final Map<String, dynamic> decoded = jsonDecode(data);
      final Map<String, Thumbnail> thumbnails = {};
      
      for (final entry in decoded.entries) {
        final thumbnailData = entry.value as Map<String, dynamic>;
        thumbnails[entry.key] = Thumbnail(
          id: thumbnailData['id'],
          sourceName: thumbnailData['sourceName'],
          episodeName: thumbnailData['episodeName'],
          filePath: thumbnailData['filePath'],
          createdAt: DateTime.parse(thumbnailData['createdAt']),
          episodeIndex: thumbnailData['episodeIndex'],
          isGenerated: thumbnailData['isGenerated'],
        );
      }
      
      return thumbnails;
    } catch (e) {
      throw ThumbnailStorageException('Error loading thumbnails: $e');
    }
  }

  Future<void> _saveThumbnails(Map<String, Thumbnail> thumbnails) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};
      
      for (final entry in thumbnails.entries) {
        data[entry.key] = {
          'id': entry.value.id,
          'sourceName': entry.value.sourceName,
          'episodeName': entry.value.episodeName,
          'filePath': entry.value.filePath,
          'createdAt': entry.value.createdAt.toIso8601String(),
          'episodeIndex': entry.value.episodeIndex,
          'isGenerated': entry.value.isGenerated,
        };
      }
      
      await prefs.setString(_thumbnailsKey, jsonEncode(data));
    } catch (e) {
      throw ThumbnailStorageException('Error saving thumbnails: $e');
    }
  }

  String _generateThumbnailId(String sourceName, String episodeName, int episodeIndex) {
    return '${sourceName}_${episodeName}_$episodeIndex'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/domain/model/source.dart';
import '../../core/domain/services/source.repository.dart';

class SharedPreferencesSourceRepository implements SourceRepository {
  static const String _sourcesKey = 'video_sources';

  @override
  Future<List<Source>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = prefs.getStringList(_sourcesKey) ?? [];

    return sourcesJson.map((json) {
      final Map<String, dynamic> sourceMap = Map<String, dynamic>.from(
        jsonDecode(json) as Map,
      );
      return Source(
        url: sourceMap['url'] as String,
        name: sourceMap['name'] as String,
        episodeCount: sourceMap['episodeCount'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> saveAll(List<Source> sources) async {
    final prefs = await SharedPreferences.getInstance();
    final sourcesJson = sources
        .map(
          (source) => jsonEncode({
            'url': source.url,
            'name': source.name,
            'episodeCount': source.episodeCount,
          }),
        )
        .toList();
    await prefs.setStringList(_sourcesKey, sourcesJson);
  }
}

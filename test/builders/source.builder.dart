import 'package:kidflix/core/domain/model/source.dart';

class SourceBuilder {
  final String _url;
  final String _name;
  final int _episodeCount;

  SourceBuilder._({
    required String url,
    required String name,
    required int episodeCount,
  }) : _url = url,
       _name = name,
       _episodeCount = episodeCount;

  SourceBuilder withUrl(String url) {
    return SourceBuilder._(url: url, name: _name, episodeCount: _episodeCount);
  }

  SourceBuilder withName(String name) {
    return SourceBuilder._(url: _url, name: name, episodeCount: _episodeCount);
  }

  SourceBuilder withEpisodeCount(int episodeCount) {
    return SourceBuilder._(url: _url, name: _name, episodeCount: episodeCount);
  }

  static SourceBuilder create() {
    return SourceBuilder._(
      url: 'https://kidflix.example.com/tchoupi/volume1.json',
      name: 'Tchoupi Volume 1',
      episodeCount: 10,
    );
  }

  Source build() {
    return Source(url: _url, name: _name, episodeCount: _episodeCount);
  }
}

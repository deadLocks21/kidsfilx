class Thumbnail {
  final String id;
  final String sourceName;
  final String episodeName;
  final String filePath;
  final DateTime createdAt;
  final int episodeIndex;
  final bool isGenerated;

  const Thumbnail({
    required this.id,
    required this.sourceName,
    required this.episodeName,
    required this.filePath,
    required this.createdAt,
    required this.episodeIndex,
    required this.isGenerated,
  });

  Thumbnail copyWith({
    String? id,
    String? sourceName,
    String? episodeName,
    String? filePath,
    DateTime? createdAt,
    int? episodeIndex,
    bool? isGenerated,
  }) {
    return Thumbnail(
      id: id ?? this.id,
      sourceName: sourceName ?? this.sourceName,
      episodeName: episodeName ?? this.episodeName,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Thumbnail &&
        other.id == id &&
        other.sourceName == sourceName &&
        other.episodeName == episodeName &&
        other.filePath == filePath &&
        other.createdAt == createdAt &&
        other.episodeIndex == episodeIndex &&
        other.isGenerated == isGenerated;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sourceName.hashCode ^
        episodeName.hashCode ^
        filePath.hashCode ^
        createdAt.hashCode ^
        episodeIndex.hashCode ^
        isGenerated.hashCode;
  }

  @override
  String toString() {
    return 'Thumbnail(id: $id, sourceName: $sourceName, episodeName: $episodeName, filePath: $filePath, createdAt: $createdAt, episodeIndex: $episodeIndex, isGenerated: $isGenerated)';
  }
}
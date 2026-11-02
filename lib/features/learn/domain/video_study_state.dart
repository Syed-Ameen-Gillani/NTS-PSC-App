typedef VideoStudyKey = ({String userId, String lessonId, String source});

class VideoStudyNote {
  const VideoStudyNote({
    required this.id,
    required this.seconds,
    required this.text,
  });
  final String id;
  final int seconds;
  final String text;

  Map<String, Object> toJson() => {'id': id, 'seconds': seconds, 'text': text};
}

class VideoStudyState {
  const VideoStudyState({
    this.positionMs = 0,
    this.speed = 1,
    this.captions = false,
    this.volume = 1,
    this.notes = const [],
  });
  final int positionMs;
  final double speed;
  final bool captions;
  final double volume;
  final List<VideoStudyNote> notes;

  VideoStudyState copyWith({
    int? positionMs,
    double? speed,
    bool? captions,
    double? volume,
    List<VideoStudyNote>? notes,
  }) => VideoStudyState(
    positionMs: positionMs ?? this.positionMs,
    speed: speed ?? this.speed,
    captions: captions ?? this.captions,
    volume: volume ?? this.volume,
    notes: notes ?? this.notes,
  );

  Duration resumePosition(Duration duration) {
    if (positionMs < 0 ||
        duration.inMilliseconds <= 0 ||
        positionMs >= duration.inMilliseconds - 2000) {
      return Duration.zero;
    }
    return Duration(milliseconds: positionMs);
  }

  Map<String, Object> toJson() => {
    'positionMs': positionMs,
    'speed': speed,
    'captions': captions,
    'volume': volume,
    'notes': notes.map((note) => note.toJson()).toList(),
  };

  factory VideoStudyState.fromJson(Map<String, dynamic> value) {
    final position = value['positionMs'];
    final speed = value['speed'];
    final volume = value['volume'];
    final notes = <VideoStudyNote>[];
    if (value['notes'] case final List items) {
      for (final item in items) {
        if (item is Map &&
            item['id'] is String &&
            item['text'] is String &&
            item['seconds'] is int &&
            item['seconds'] >= 0 &&
            (item['text'] as String).trim().isNotEmpty) {
          notes.add(
            VideoStudyNote(
              id: item['id'],
              seconds: item['seconds'],
              text: item['text'],
            ),
          );
        }
      }
    }
    return VideoStudyState(
      positionMs: position is int && position >= 0 ? position : 0,
      speed: speed is num && speed.isFinite && speed >= 0.5 && speed <= 2
          ? speed.toDouble()
          : 1,
      captions: value['captions'] == true,
      volume: volume is num && volume.isFinite && volume >= 0 && volume <= 1
          ? volume.toDouble()
          : 1,
      notes: List.unmodifiable(notes),
    );
  }
}

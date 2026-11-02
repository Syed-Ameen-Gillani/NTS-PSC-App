import 'dart:io';

import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';

class MemoryVideoStudyRepository extends VideoStudyRepository {
  MemoryVideoStudyRepository() : super(() async => Directory.systemTemp);
  final values = <VideoStudyKey, VideoStudyState>{};
  bool failWrites = false;

  @override
  Future<VideoStudyState> read(VideoStudyKey key) async =>
      values[key] ?? const VideoStudyState();
  @override
  Future<void> write(VideoStudyKey key, VideoStudyState state) async {
    if (failWrites) throw const FileSystemException('Test disk failure');
    values[key] = state;
  }

  @override
  Future<void> writePlayback(VideoStudyKey key, VideoStudyState state) async {
    await write(
      key,
      (values[key] ?? const VideoStudyState()).copyWith(
        positionMs: state.positionMs,
        speed: state.speed,
        captions: state.captions,
        volume: state.volume,
      ),
    );
  }
}

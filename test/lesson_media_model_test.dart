import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';

void main() {
  test('lesson copy retains hosted video identity', () {
    final lesson = LessonModel(
      id: 'lesson',
      title: 'Urdu lecture',
      durationMinutes: 10,
      videoPath: 'teacher/lesson/version.mp4',
    );
    final updated = lesson.copyWith(isCompleted: true);
    expect(updated.videoPath, lesson.videoPath);
    expect(updated.isCompleted, isTrue);
  });

  test('lesson media parses versioned transcript and upload size', () {
    final media = LessonMedia.fromRow({
      'id': 'version',
      'lesson_id': 'lesson',
      'object_path': 'teacher/lesson/version.mp4',
      'status': 'needs_review',
      'processing_error': null,
      'byte_size': 12345,
      'transcript_segments': [
        {'start': 0, 'end': 5.2, 'text': 'The constitution'},
      ],
    });
    expect(media.byteSize, 12345);
    expect(media.segments.single['end'], 5.2);
    expect(maxLessonVideoBytes, 25 * 1024 * 1024);
  });
}

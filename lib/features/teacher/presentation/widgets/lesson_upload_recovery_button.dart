import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_video_preview.dart';

class LessonUploadRecoveryButton extends ConsumerWidget {
  const LessonUploadRecoveryButton({
    super.key,
    required this.mediaId,
    required this.run,
    required this.path,
    required this.uploading,
  });

  final String mediaId;
  final String path;
  final bool uploading;
  final Future<void> Function(Future<void> Function()) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    icon: Icon(uploading ? Icons.refresh : Icons.play_circle_outline),
    label: Text(uploading ? 'Recover uploaded video' : 'Preview video'),
    onPressed: uploading
        ? () => run(() async {
            final repository = ref.read(lessonMediaRepositoryProvider);
            await repository.finalizeUpload(mediaId);
            await repository.retryTranscript(mediaId);
          })
        : () => showDialog<void>(
            context: context,
            builder: (_) => TeacherVideoPreview(path: path),
          ),
  );
}

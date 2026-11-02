import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_video_preview_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';

class TeacherVideoPreview extends ConsumerWidget {
  const TeacherVideoPreview({
    super.key,
    required this.path,
    this.title = 'Video preview',
    this.segments = const [],
  });
  final String path;
  final String title;
  final List<Map<String, dynamic>> segments;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(teacherVideoPreviewProvider(path))
      .when(
        loading: () => const VideoPlayerStatus(loading: true),
        error: (_, _) => VideoPlayerStatus(
          message: 'Preview could not be loaded.',
          onRetry: () => ref.invalidate(teacherVideoPreviewProvider(path)),
        ),
        data: (controller) => ProfessionalVideoPlayer(
          controller: controller,
          title: title,
          segments: segments,
          onRetry: () => ref.invalidate(teacherVideoPreviewProvider(path)),
        ),
      );
}

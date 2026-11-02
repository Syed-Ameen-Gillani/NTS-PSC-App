import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/hosted_lesson_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/offline_completion_button.dart';

class OfflineLessonScreen extends ConsumerWidget {
  const OfflineLessonScreen({super.key, required this.lesson});
  final LessonModel lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(
      authControllerProvider.select((s) => s.value?.user?.id),
    );
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: userId == null
          ? const Center(child: Text('Sign in to watch your downloads.'))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    HostedLessonPlayer(
                      key: ValueKey((userId, lesson.id)),
                      lesson: lesson,
                      trackLearning: true,
                    ),
                    OfflineCompletionButton(lessonId: lesson.id),
                  ],
                ),
              ),
            ),
    );
  }
}

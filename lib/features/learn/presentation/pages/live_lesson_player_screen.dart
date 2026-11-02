import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

import 'package:nts_psc_app/features/learn/presentation/widgets/hosted_lesson_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_content.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/source_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import '../../domain/lesson_navigation_item.dart';
import '../widgets/non_video_lesson_item.dart';

final _selectedLesson = StateProvider.autoDispose.family<LessonModel?, String>(
  (ref, id) => null,
);
final _autoplay = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);
final _autoStart = StateProvider.autoDispose.family<String?, String>(
  (ref, id) => null,
);
final _selectedItem = StateProvider.autoDispose.family<String?, String>(
  (ref, id) => null,
);

class LiveLessonPlayerScreen extends ConsumerWidget {
  const LiveLessonPlayerScreen({
    super.key,
    required this.course,
    this.initialLesson,
    this.mode = LessonPlayerMode.learning,
  });

  final CourseModel course;
  final LessonModel? initialLesson;
  final LessonPlayerMode mode;

  String _stateKey(WidgetRef ref) =>
      '${ref.read(authControllerProvider).value?.user?.id ?? 'signed-out'}:${course.id}:${mode.name}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider.select((value) => value.value?.user?.id));
    final scope = _stateKey(ref);
    final lessons = course.modules.expand((module) => module.lessons).toList();
    final selectedId =
        ref.watch(_selectedLesson(scope))?.id ?? initialLesson?.id;
    final lesson =
        lessons.where((item) => item.id == selectedId).firstOrNull ??
        lessons.where((item) => !item.isLocked).firstOrNull;
    final items = LessonNavigationItem.fromCourse(course);
    final itemKey = ref.watch(_selectedItem(scope));
    final currentItem =
        items
            .where(
              (item) => item.key == itemKey && item.lesson.id == lesson?.id,
            )
            .firstOrNull ??
        items.where((item) => item.lesson.id == lesson?.id).firstOrNull;
    final itemIndex = currentItem == null ? -1 : items.indexOf(currentItem);
    ref.listen<AsyncValue<String>>(learningEvidenceChangesProvider, (
      previous,
      next,
    ) {
      next.whenData((lessonId) {
        if (lessonId == lesson?.id) {
          ref.invalidate(lessonAccessCourseProvider(course.id));
        }
      });
    });
    final completed = {
      ...lessons.where((item) => item.isCompleted).map((item) => item.id),
    };

    final index = lesson == null
        ? -1
        : lessons.indexWhere((item) => item.id == lesson.id);
    final autoplay = ref.watch(_autoplay(scope));
    final autoStart = ref.watch(_autoStart(scope));

    void select(LessonModel item, {bool play = false}) {
      if (item.isLocked) return;
      if (_stateKey(ref) != scope) return;
      ref.read(_autoStart(scope).notifier).state = play ? item.id : null;
      ref.read(_selectedLesson(scope).notifier).state = item;
      ref.read(_selectedItem(scope).notifier).state = null;
    }

    void selectItem(LessonNavigationItem item) {
      if (item.lesson.isLocked || _stateKey(ref) != scope) return;
      select(item.lesson);
      ref.read(_selectedItem(scope).notifier).state = item.key;
    }

    Future<void> ended() async {
      if (lesson == null || index < 0) return;
      if (mode == LessonPlayerMode.instructorPreview) return;
      await ref.read(learningEvidenceRepositoryProvider).sync();
      if (!context.mounted) return;
      ref.invalidate(lessonAccessCourseProvider(course.id));
      if (_stateKey(ref) != scope ||
          ref.read(_selectedItem(scope)) != itemKey ||
          (ref.read(_selectedLesson(scope))?.id ?? lesson.id) != lesson.id) {
        return;
      }
      if (!ref.read(_autoplay(scope))) return;
      CourseModel? refreshed;
      try {
        refreshed = await ref.read(
          lessonAccessCourseProvider(course.id).future,
        );
      } catch (_) {
        return;
      }
      if (!context.mounted || refreshed == null) return;
      final updated = refreshed.modules.expand((m) => m.lessons).toList();
      final current = updated.indexWhere((l) => l.id == lesson.id);
      if (current < 0 ||
          current + 1 >= updated.length ||
          updated[current + 1].isLocked) {
        return;
      }
      if (GoRouter.of(context).state.uri.path ==
          AppRoute.videoFullscreen.path) {
        context.pop();
        await WidgetsBinding.instance.endOfFrame;
      }
      if (context.mounted) select(updated[current + 1], play: true);
    }

    final validUrl = Uri.tryParse(lesson?.videoUrl ?? '');
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: lesson == null
          ? const Center(child: Text('No lessons available yet'))
          : ListView(
              children: [
                _RetainedLessonPlayback(
                  key: ValueKey(lesson.id),
                  child: Column(
                    children: [
                      if (lesson.isLocked)
                        const VideoPlayerStatus(
                          message: 'Enroll to watch this lesson',
                        )
                      else if (currentItem != null && !currentItem.isVideo)
                        NonVideoLessonItem(
                          courseId: course.id,
                          item: currentItem,
                          isInstructorPreview:
                              mode == LessonPlayerMode.instructorPreview,
                        )
                      else if (lesson.videoPath.isNotEmpty)
                        HostedLessonPlayer(
                          key: ValueKey(lesson.id),
                          lesson: lesson,
                          autoPlay: autoStart == lesson.id,
                          trackLearning: mode == LessonPlayerMode.learning,
                          instructorPreview:
                              mode == LessonPlayerMode.instructorPreview,
                          onEnded: ended,
                        )
                      else if (validUrl != null &&
                          validUrl.scheme == 'https' &&
                          validUrl.host.isNotEmpty)
                        SourceVideoPlayer(
                          key: ValueKey(lesson.id),
                          lessonId: lesson.id,
                          autoPlay: autoStart == lesson.id,
                          trackLearning: mode == LessonPlayerMode.learning,
                          onEnded: ended,
                          source: (location: lesson.videoUrl, asset: false),
                          title: lesson.title,
                        )
                      else
                        _LessonCover(course: course),
                    ],
                  ),
                ),
                // Reading lessons show their notes and materials below.
                LiveLessonContent(
                  course: course,
                  lesson: lesson,
                  lessons: lessons,
                  completedLessonIds: completed,
                  currentIndex: index,
                  savingProgress: false,
                  autoplay: autoplay,
                  onSelectLesson: select,
                  onMarkComplete: () {},
                  onAutoplayChanged: (value) =>
                      ref.read(_autoplay(scope).notifier).state = value,
                  isInstructorPreview:
                      mode == LessonPlayerMode.instructorPreview,
                  itemNavigation: (
                    index: itemIndex,
                    count: items.length,
                    previous:
                        itemIndex > 0 && !items[itemIndex - 1].lesson.isLocked
                        ? () => selectItem(items[itemIndex - 1])
                        : null,
                    next:
                        itemIndex >= 0 &&
                            itemIndex + 1 < items.length &&
                            !items[itemIndex + 1].lesson.isLocked
                        ? () => selectItem(items[itemIndex + 1])
                        : null,
                  ),
                  contentTitle: currentItem?.activity?.kind == 'video'
                      ? null
                      : currentItem?.activity?.title,
                ),
              ],
            ),
    );
  }
}

class _LessonCover extends StatelessWidget {
  const _LessonCover({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final hasCover =
        course.imagePath.trim().isNotEmpty ||
        (Uri.tryParse(course.coverUrl ?? '')?.hasAbsolutePath ?? false);
    return Semantics(
      image: true,
      label: '${course.title} course cover',
      child: SizedBox(
        width: double.infinity,
        height: 208.h,
        child: hasCover
            ? DashboardCourseCover(
                imagePath: course.imagePath,
                coverUrl: course.coverUrl,
                width: MediaQuery.sizeOf(context).width,
                height: 208.h,
              )
            : ColoredBox(
                color: AppColors.settingsCardBackground,
                child: Center(
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.primary,
                    size: 40.w,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Keep the current controller/session alive while viewers scroll through
/// lesson resources. Changing lessons or leaving the page still disposes it.
class _RetainedLessonPlayback extends StatefulWidget {
  const _RetainedLessonPlayback({super.key, required this.child});
  final Widget child;

  @override
  State<_RetainedLessonPlayback> createState() =>
      _RetainedLessonPlaybackState();
}

class _RetainedLessonPlaybackState extends State<_RetainedLessonPlayback>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

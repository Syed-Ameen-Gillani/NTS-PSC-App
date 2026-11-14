import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
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

bool shouldTrackLessonProgress({
  required LessonPlayerMode mode,
  required bool hasEntitlement,
}) => mode == LessonPlayerMode.learning && hasEntitlement;

class LiveLessonPlayerScreen extends ConsumerStatefulWidget {
  const LiveLessonPlayerScreen({
    super.key,
    required this.course,
    this.initialLesson,
    this.mode = LessonPlayerMode.learning,
  });

  final CourseModel course;
  final LessonModel? initialLesson;
  final LessonPlayerMode mode;

  @override
  ConsumerState<LiveLessonPlayerScreen> createState() =>
      _LiveLessonPlayerScreenState();
}

class _LiveLessonPlayerScreenState extends ConsumerState<LiveLessonPlayerScreen>
    with RestorationMixin {
  final _restoredLessonId = RestorableStringN(null);
  final _restoredItemKey = RestorableStringN(null);
  CourseModel get course => widget.course;
  LessonModel? get initialLesson => widget.initialLesson;
  LessonPlayerMode get mode => widget.mode;

  @override
  String get restorationId => 'lesson-player-${course.id}-${mode.name}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredLessonId, 'lesson');
    registerForRestoration(_restoredItemKey, 'item');
  }

  @override
  void dispose() {
    _restoredLessonId.dispose();
    _restoredItemKey.dispose();
    super.dispose();
  }

  String _stateKey() =>
      '${ref.read(authControllerProvider).value?.user?.id ?? 'signed-out'}:${course.id}:${mode.name}';

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(
      authControllerProvider.select((value) => value.value?.user?.id),
    );
    final accessState = AppConfig.isSupabaseEnabled
        ? ref.watch(lessonAccessCourseProvider(course.id))
        : null;
    final refreshedCourse = accessState?.value;
    final activeCourse = refreshedCourse ?? course;
    final scope = _stateKey();
    final lessons = activeCourse.modules
        .expand((module) => module.lessons)
        .toList();
    final selectedId =
        ref.watch(_selectedLesson(scope))?.id ??
        _restoredLessonId.value ??
        initialLesson?.id;
    final lesson =
        lessons.where((item) => item.id == selectedId).firstOrNull ??
        lessons.where((item) => !item.isLocked).firstOrNull;
    final items = LessonNavigationItem.fromCourse(activeCourse);
    final itemKey = ref.watch(_selectedItem(scope)) ?? _restoredItemKey.value;
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
          ref.invalidate(learningOutcomeProvider(lessonId));
          ref.invalidate(lessonAccessCourseProvider(activeCourse.id));
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
    final trackLearning = shouldTrackLessonProgress(
      mode: mode,
      hasEntitlement: activeCourse.hasEntitlement,
    );
    final verifyingAccess =
        mode == LessonPlayerMode.learning &&
        currentUserId != null &&
        !course.hasEntitlement &&
        refreshedCourse == null &&
        accessState?.isLoading == true;
    final accessFailed =
        mode == LessonPlayerMode.learning &&
        currentUserId != null &&
        !course.hasEntitlement &&
        refreshedCourse == null &&
        accessState?.hasError == true;

    void select(LessonModel item, {bool play = false}) {
      if (item.isLocked) return;
      if (_stateKey() != scope) return;
      ref.read(_autoStart(scope).notifier).state = play ? item.id : null;
      _restoredLessonId.value = item.id;
      _restoredItemKey.value = null;
      ref.read(_selectedLesson(scope).notifier).state = item;
      ref.read(_selectedItem(scope).notifier).state = null;
    }

    void selectItem(LessonNavigationItem item) {
      if (item.lesson.isLocked || _stateKey() != scope) return;
      select(item.lesson);
      _restoredItemKey.value = item.key;
      ref.read(_selectedItem(scope).notifier).state = item.key;
    }

    Future<void> ended() async {
      if (lesson == null || index < 0) return;
      if (mode == LessonPlayerMode.instructorPreview) return;
      await ref.read(learningEvidenceRepositoryProvider).sync();
      if (!context.mounted) return;
      ref.invalidate(learningOutcomeProvider(lesson.id));
      ref.invalidate(lessonAccessCourseProvider(activeCourse.id));
      if (_stateKey() != scope ||
          ref.read(_selectedItem(scope)) != itemKey ||
          (ref.read(_selectedLesson(scope))?.id ?? lesson.id) != lesson.id) {
        return;
      }
      if (!ref.read(_autoplay(scope))) return;
      CourseModel? refreshed;
      try {
        refreshed = await ref.read(
          lessonAccessCourseProvider(activeCourse.id).future,
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
      body: SafeArea(
        bottom: false,
        child: lesson == null
            ? Stack(
                children: [
                  const Center(child: Text('No lessons available yet')),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: BackButton(onPressed: () => context.pop()),
                  ),
                ],
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _RetainedLessonPlayback(
                    key: ValueKey(lesson.id),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            if (verifyingAccess)
                              const VideoPlayerStatus(loading: true)
                            else if (accessFailed)
                              VideoPlayerStatus(
                                message: 'Course access could not be verified.',
                                onRetry: () => ref.invalidate(
                                  lessonAccessCourseProvider(course.id),
                                ),
                              )
                            else if (lesson.isLocked)
                              const VideoPlayerStatus(
                                message: 'Enroll to watch this lesson',
                              )
                            else if (currentItem != null &&
                                !currentItem.isVideo)
                              NonVideoLessonItem(
                                courseId: activeCourse.id,
                                item: currentItem,
                                isInstructorPreview:
                                    mode == LessonPlayerMode.instructorPreview,
                              )
                            else if (lesson.videoPath.isNotEmpty)
                              HostedLessonPlayer(
                                key: ValueKey(lesson.id),
                                lesson: lesson,
                                autoPlay: autoStart == lesson.id,
                                trackLearning: trackLearning,
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
                                trackLearning: trackLearning,
                                onEnded: ended,
                                source: (
                                  location: lesson.videoUrl,
                                  asset: false,
                                ),
                                title: lesson.title,
                              )
                            else
                              _LessonCover(course: activeCourse),
                          ],
                        ),
                        Positioned(
                          top: 4.r,
                          left: 4.r,
                          child: IconButton(
                            tooltip: 'Back',
                            onPressed: () => context.pop(),
                            icon: Icon(
                              Icons.arrow_back,
                              size: 24.r.clamp(24, 28),
                              color: AppColors.videoForeground,
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reading lessons show their notes and materials below.
                  LiveLessonContent(
                    course: activeCourse,
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

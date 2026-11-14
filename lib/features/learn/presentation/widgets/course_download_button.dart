import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/course_download_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_action_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class CourseDownloadButton extends ConsumerWidget {
  const CourseDownloadButton({
    super.key,
    required this.course,
    this.compact = false,
  });

  final CourseModel course;
  final bool compact;

  // Multiple course/player surfaces can be mounted together.
  static final _announced = <String, CourseDownloadPhase>{};

  void _announce(
    BuildContext context,
    String owner,
    CourseDownloadState state,
  ) {
    final phase = state.phase;
    final key = '$owner:${course.id}';
    if (_announced[key] == phase) return;
    _announced[key] = phase;
    if (!context.mounted) return;
    switch (phase) {
      case CourseDownloadPhase.preparing:
        CustomToast.showInfo(context, message: 'Download started', top: true);
      case CourseDownloadPhase.paused:
        CustomToast.showInfo(context, message: 'Download paused', top: true);
      case CourseDownloadPhase.completed:
        CustomToast.showSuccess(
          context,
          message: 'Download completed',
          top: true,
        );
      case CourseDownloadPhase.cancelled:
        CustomToast.showInfo(context, message: 'Download cancelled', top: true);
      case CourseDownloadPhase.failed:
        CustomToast.showError(
          context,
          message: state.errorMessage ?? 'Download failed. Tap Retry.',
          top: true,
        );
      default:
        break;
    }
  }

  Future<void> _startDownload(BuildContext context, WidgetRef ref) async {
    final pending = ref.read(courseDownloadPendingProvider(course.id)).value;
    final wifiOnly = pending?.remainingLessonIds.isNotEmpty == true
        ? pending!.wifiOnly
        : await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Download course lessons?'),
              content: const Text(
                'Videos are saved inside the app for offline viewing.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Any network'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Wi-Fi only'),
                ),
              ],
            ),
          );
    if (wifiOnly == null || !context.mounted) return;
    try {
      await ref
          .read(courseDownloadProvider(course.id).notifier)
          .download(course, wifiOnly: wifiOnly);
    } catch (_) {
      // The controller publishes the failed state; the listener announces it.
    }
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    CourseDownloadState state,
  ) async {
    final controller = ref.read(courseDownloadProvider(course.id).notifier);
    if (state.phase == CourseDownloadPhase.paused) {
      try {
        await controller.resume();
        if (context.mounted) {
          CustomToast.showInfo(context, message: 'Download resumed', top: true);
        }
      } catch (_) {
        if (context.mounted) {
          CustomToast.showError(
            context,
            message: 'Could not resume. Check your connection and retry.',
            top: true,
          );
        }
      }
    } else if (state.running) {
      final accepted = await controller.pause();
      if (!accepted && context.mounted) {
        CustomToast.showError(
          context,
          message: 'This transfer cannot be paused yet.',
          top: true,
        );
      }
    } else {
      await _startDownload(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(
      authControllerProvider.select((value) => value.value?.user?.id),
    );
    final state = ref.watch(courseDownloadProvider(course.id));
    ref.listen(courseDownloadProvider(course.id), (previous, next) {
      if (previous?.phase != next.phase && owner != null) {
        _announce(context, owner, next);
      }
    });
    final queued = ref.watch(courseDownloadPendingProvider(course.id)).value;
    final persistedTransfer = ref
        .watch(courseDownloadTransferProvider(course.id))
        .value;
    final downloads = ref.watch(offlineDownloadsProvider).value ?? const [];
    final videos = course.modules
        .expand((module) => module.lessons)
        .where((lesson) => lesson.videoPath.isNotEmpty)
        .toList();
    final allSaved =
        videos.isNotEmpty &&
        videos.every(
          (lesson) => downloads.any(
            (entry) =>
                entry.lessonId == lesson.id &&
                entry.mediaPath == lesson.videoPath &&
                !entry.needsAccessRefresh,
          ),
        );
    // The completed phase describes the last transfer, not the current files.
    // A saved video can be removed from Downloads without resetting that phase.
    final downloaded = allSaved;
    final recoveredPaused =
        !state.running && persistedTransfer?.status == TaskStatus.paused;
    final paused = state.phase == CourseDownloadPhase.paused || recoveredPaused;
    final busy = state.running && !paused;
    final currentProgress = recoveredPaused
        ? persistedTransfer!.progress
        : state.progress;
    final progress = currentProgress > 0 && currentProgress < 1
        ? currentProgress
        : null;
    final percentage = progress == null ? '' : ' ${(progress * 100).round()}%';
    final label = downloaded
        ? 'Downloaded'
        : paused
        ? 'Resume$percentage'
        : busy
        ? state.phase == CourseDownloadPhase.preparing
              ? 'Preparing'
              : state.phase == CourseDownloadPhase.pausing
              ? 'Pausing'
              : 'Pause$percentage'
        : state.phase == CourseDownloadPhase.failed
        ? 'Retry'
        : queued?.remainingLessonIds.isNotEmpty == true
        ? 'Continue download'
        : 'Download';
    final iconData = downloaded
        ? Icons.download_done_rounded
        : paused
        ? Icons.play_arrow_rounded
        : busy
        ? Icons.pause_rounded
        : state.phase == CourseDownloadPhase.failed
        ? Icons.refresh_rounded
        : Icons.download_outlined;
    final showProgress = !downloaded && (busy || paused);
    final icon = SizedBox.square(
      dimension: 32.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: showProgress ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: SizedBox.square(
              dimension: 31.w,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: showProgress ? currentProgress.clamp(0.0, 1.0) : 0,
                ),
                duration: const Duration(milliseconds: 220),
                builder: (_, value, __) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                  backgroundColor: AppColors.grey200,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(iconData, key: ValueKey(iconData), size: 21.w),
          ),
        ],
      ),
    );
    final onTap = downloaded || state.phase == CourseDownloadPhase.pausing
        ? null
        : recoveredPaused
        ? () => _startDownload(context, ref)
        : () => _onTap(context, ref, state);

    if (compact) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Keep the primary action centered in its full action-column width.
          // The positioned cancel control must not size or shift this content.
          SizedBox(
            width: double.infinity,
            child: LessonActionButton(
              icon: icon,
              label: label,
              onTap: onTap,
              color: AppColors.primary,
              localizeFeedbackToIcon: true,
            ),
          ),
          if (state.running || recoveredPaused)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: IconButton(
                tooltip: 'Cancel download',
                visualDensity: VisualDensity.compact,
                iconSize: 16.w,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 30.w, height: 30.w),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.settingsCardBackground,
                  side: BorderSide(
                    color: AppColors.settingsCardBorder,
                    width: 1.w,
                  ),
                  shape: const CircleBorder(),
                ),
                onPressed: () => ref
                    .read(courseDownloadProvider(course.id).notifier)
                    .cancel(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(icon: icon, label: Text(label), onPressed: onTap),
        if (state.running) ...[
          SizedBox(height: 8.h),
          Text(
            paused
                ? '${state.saved} of ${videos.length} videos saved • Paused'
                : '${state.saved} of ${videos.length} videos saved',
            style: AppTextStyles.interRegular14.copyWith(
              color: AppColors.grey500,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(courseDownloadProvider(course.id).notifier).cancel(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel'),
            ),
          ),
        ],
      ],
    );
  }
}

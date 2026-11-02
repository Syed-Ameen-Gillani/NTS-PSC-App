import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/course_download_controller.dart';
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
      if (!context.mounted) return;
      final result = ref.read(courseDownloadProvider(course.id));
      CustomToast.showInfo(
        context,
        message: result.cancelled
            ? 'Download stopped. ${result.saved} lessons saved.'
            : result.failed > 0
            ? '${result.saved} saved, ${result.failed} failed. Tap to retry.'
            : result.unavailable > 0
            ? '${result.saved} saved, ${result.unavailable} unavailable offline'
            : 'Course lessons saved for offline viewing',
      );
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: 'Could not download course lessons',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseDownloadProvider(course.id));
    final resumable =
        ref
            .watch(courseDownloadPendingProvider(course.id))
            .value
            ?.remainingLessonIds
            .isNotEmpty ==
        true;
    if (compact) {
      return LessonActionButton(
        icon: state.running
            ? SizedBox.square(
                dimension: 19.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        label: state.running
            ? '${state.saved}/${state.total} saved'
            : resumable
            ? 'Resume'
            : 'Download',
        onTap: state.running ? null : () => _startDownload(context, ref),
        color: AppColors.primary,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: state.running
              ? SizedBox.square(
                  dimension: 18.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(
            state.running
                ? 'Saving lessons (${state.saved}/${state.total})'
                : resumable
                ? 'Resume download'
                : 'Download lessons',
          ),
          onPressed: state.running ? null : () => _startDownload(context, ref),
        ),
        if (state.running) ...[
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Waiting for network or saving a lesson',
                  style: AppTextStyles.interRegular14.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cancel download',
                icon: const Icon(Icons.close),
                onPressed: () => ref
                    .read(courseDownloadProvider(course.id).notifier)
                    .cancel(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

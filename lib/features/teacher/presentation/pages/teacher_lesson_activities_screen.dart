import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/curriculum/data/lesson_activity_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/lesson_activity_configuration_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherLessonActivitiesScreen extends ConsumerWidget {
  const TeacherLessonActivitiesScreen({super.key, required this.lessonId});
  final String lessonId;
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    List<ConfiguredActivity> items,
  ) async {
    try {
      await ref
          .read(lessonActivityConfigurationProvider(lessonId).notifier)
          .save(items);
    } catch (error) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: error is PostgrestException && error.code == '22023'
              ? error.message
              : 'Could not save activities. Try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    appBar: AppBar(title: const Text('Learning requirements')),
    body: ref
        .watch(lessonActivityConfigurationProvider(lessonId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ActivitiesNotice(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load requirements',
            message: 'Check your connection and try again.',
            actionLabel: 'Try again',
            actionIcon: Icons.refresh,
            onAction: () =>
                ref.invalidate(lessonActivityConfigurationProvider(lessonId)),
          ),
          data: (items) => items.isEmpty
              ? _ActivitiesNotice(
                  icon: Icons.playlist_add_outlined,
                  title: 'No activities yet',
                  message:
                      'Add a video, reading, handout, quiz, or assignment in Lesson Studio. You can then choose what students must complete.',
                  actionLabel: 'Back to Lesson Studio',
                  actionIcon: Icons.arrow_back,
                  onAction: context.pop,
                )
              : ListView(
                  padding: EdgeInsets.all(20.w),
                  children: [
                    Text(
                      'Learning requirements',
                      style: AppTextStyles.interSemiBold16,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Students complete required activities before the next lesson unlocks. Changes go live when you publish the course.',
                      style: AppTextStyles.interRegular14,
                    ),
                    SizedBox(height: 16.h),
                    for (var index = 0; index < items.length; index++)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Material(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. ${items[index].activity.title}',
                                        style: AppTextStyles.interMedium16,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Move up',
                                      onPressed: index == 0
                                          ? null
                                          : () {
                                              final reordered = [...items];
                                              final item = reordered.removeAt(
                                                index,
                                              );
                                              reordered.insert(index - 1, item);
                                              _save(context, ref, reordered);
                                            },
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      tooltip: 'Move down',
                                      onPressed: index + 1 == items.length
                                          ? null
                                          : () {
                                              final reordered = [...items];
                                              final item = reordered.removeAt(
                                                index,
                                              );
                                              reordered.insert(index + 1, item);
                                              _save(context, ref, reordered);
                                            },
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                  ],
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Required'),
                                  value: items[index].activity.isRequired,
                                  onChanged: (value) => _save(context, ref, [
                                    for (var i = 0; i < items.length; i++)
                                      i == index
                                          ? items[i].required(value)
                                          : items[i],
                                  ]),
                                ),
                                if (items[index].warning != null)
                                  Text(
                                    items[index].warning!,
                                    style: AppTextStyles.interRegular14,
                                  ),
                                if (items[index].canPrepare &&
                                    !items[index].readingReady)
                                  TextButton.icon(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(
                                              lessonActivityConfigurationProvider(
                                                lessonId,
                                              ).notifier,
                                            )
                                            .prepare(items[index].materialId!);
                                      } catch (_) {
                                        if (context.mounted) {
                                          CustomToast.showError(
                                            context,
                                            message:
                                                'Could not check this reading. Try another PDF or text file.',
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text('Check reading'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
  );
}

class _ActivitiesNotice extends StatelessWidget {
  const _ActivitiesNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 340.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 30.w, color: colors.primary),
              ),
              SizedBox(height: 18.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 18.sp,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 14.sp,
                  height: 1.45,
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 18.w),
                label: Text(actionLabel, textAlign: TextAlign.center),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

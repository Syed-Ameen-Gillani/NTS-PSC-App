import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/services/app_image_picker_service.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/data/course_cover_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _publishingProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, id) => false,
);

class CourseWorkspaceHeader extends ConsumerWidget {
  const CourseWorkspaceHeader({
    super.key,
    required this.course,
    required this.onPublish,
  });
  final CourseModel course;
  final Future<void> Function(bool) onPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publishing = ref.watch(_publishingProvider(course.id));
    final lessons = course.modules.fold<int>(
      0,
      (sum, module) => sum + module.lessons.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Cover Banner with Edit Pencil Button
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DashboardCourseCover(
                  imagePath: course.imagePath,
                  coverUrl: course.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (AppConfig.isSupabaseEnabled)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final repository = ref.read(
                          courseCoverRepositoryProvider,
                        );
                        try {
                          final image = await ref
                              .read(appImagePickerServiceProvider)
                              .pickAndCrop(
                                context: context,
                                preset: AppImageCropPreset.courseCover,
                              );
                          if (image == null) return;
                          final coverUrl = await repository.upload(
                            course.id,
                            image.bytes,
                          );
                          if (!context.mounted) return;
                          ref
                              .read(teacherControllerProvider.notifier)
                              .updateCourseCover(course.id, coverUrl);
                          CustomToast.showSuccess(
                            context,
                            message: course.isPublished
                                ? 'Cover ready. Publish changes to make it live.'
                                : 'Course cover updated.',
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          CustomToast.showError(
                            context,
                            message: error is ArgumentError
                                ? error.message.toString()
                                : error is PostgrestException
                                ? error.message
                                : 'Could not upload the cover.',
                          );
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 18.w,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Course Title & Publish Button in One Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 20.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: course.isPublished
                              ? const Color(0xFFE8F5E9)
                              : AppColors.grey200,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          course.isPublished ? 'Published' : 'Draft',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 11.sp,
                            color: course.isPublished
                                ? const Color(0xFF2E7D32)
                                : AppColors.grey600,
                          ),
                        ),
                      ),
                      Text(
                        '${course.category}  |  ${course.price}',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.grey500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            FilledButton(
              style: FilledButton.styleFrom(
                textStyle: AppTextStyles.interMedium16.copyWith(
                  fontSize: 13.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              ),
              onPressed: publishing
                  ? null
                  : () async {
                      if (ref.read(_publishingProvider(course.id))) return;
                      ref.read(_publishingProvider(course.id).notifier).state =
                          true;
                      try {
                        await onPublish(!course.isPublished);
                      } finally {
                        if (context.mounted) {
                          ref
                                  .read(_publishingProvider(course.id).notifier)
                                  .state =
                              false;
                        }
                      }
                    },
              child: publishing
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      course.isPublished ? 'Publish changes' : 'Publish course',
                    ),
            ),
          ],
        ),
        if (course.description.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            course.description,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: AppColors.grey700,
              height: 1.4,
            ),
          ),
        ],

        Divider(height: 24.h, color: AppColors.grey200),
        Row(
          children: [
            _stat('${course.enrolledCount}', 'Learners'),
            _stat('${course.modules.length}', 'Modules'),
            _stat('$lessons', 'Lessons'),
          ],
        ),
        if (course.rating > 0) ...[
          SizedBox(height: 12.h),
          Text(
            '${course.rating} course rating',
            style: AppTextStyles.interRegular14.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.interSemiBold16.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 12.sp,
            color: AppColors.grey500,
          ),
        ),
      ],
    ),
  );
}

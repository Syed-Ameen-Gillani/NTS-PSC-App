import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class LessonMetaRow extends StatelessWidget {
  const LessonMetaRow({
    super.key,
    required this.course,
    required this.lesson,
    required this.lessonNumber,
    required this.lessonCount,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    this.isItemNavigation = false,
  });

  final CourseModel course;
  final LessonModel lesson;
  final int lessonNumber;
  final int lessonCount;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isItemNavigation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  course.category.toUpperCase(),
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                '${isItemNavigation ? 'Item' : 'Lesson'} $lessonNumber of $lessonCount',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.grey500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14.w,
                    color: AppColors.grey500,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${lesson.durationMinutes} min',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        _LessonNavigationButton(
          tooltip: isItemNavigation ? 'Previous item' : 'Previous lesson',
          icon: Icons.skip_previous_rounded,
          onPressed: hasPrevious ? onPrevious : null,
        ),
        SizedBox(width: 4.w),
        _LessonNavigationButton(
          tooltip: isItemNavigation ? 'Next item' : 'Next lesson',
          icon: Icons.skip_next_rounded,
          onPressed: hasNext ? onNext : null,
        ),
      ],
    );
  }
}

class _LessonNavigationButton extends StatelessWidget {
  const _LessonNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 36.w,
    child: IconButton.outlined(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      iconSize: 19.w,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.onBackground,
        disabledForegroundColor: AppColors.grey400,
        side: const BorderSide(color: AppColors.grey300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    ),
  );
}

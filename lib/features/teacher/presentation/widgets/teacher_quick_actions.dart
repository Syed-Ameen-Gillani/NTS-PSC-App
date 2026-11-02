import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class TeacherQuickActions extends StatelessWidget {
  const TeacherQuickActions({
    super.key,
    required this.onCreateCourse,
    required this.onCreateQuiz,
    required this.onCreateAssignment,
  });

  final VoidCallback onCreateCourse;
  final VoidCallback onCreateQuiz;
  final VoidCallback onCreateAssignment;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.r),
    );
    final labelStyle = AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: onCreateCourse,
              icon: Icon(Icons.add, size: 19.w),
              label: Text('Create course', style: labelStyle),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: Size(0, 50.h),
                shape: shape,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreateQuiz,
                    icon: Icon(Icons.quiz_outlined, size: 18.w),
                    label: Text('Quiz', style: labelStyle),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onBackground,
                      side: BorderSide(color: AppColors.grey300, width: 1.w),
                      minimumSize: Size(0, 48.h),
                      shape: shape,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreateAssignment,
                    icon: Icon(Icons.assignment_outlined, size: 18.w),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Assignment', style: labelStyle),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onBackground,
                      side: BorderSide(color: AppColors.grey300, width: 1.w),
                      minimumSize: Size(0, 48.h),
                      shape: shape,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

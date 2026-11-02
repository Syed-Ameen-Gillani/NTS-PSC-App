import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';

class AssignmentStatusBadge extends StatelessWidget {
  final AssignmentReviewStatus? status;

  const AssignmentStatusBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AssignmentReviewStatus.pending => ('Pending review', AppColors.primary),
      AssignmentReviewStatus.approved => ('Approved', AppColors.success),
      AssignmentReviewStatus.disapproved => ('Rejected', AppColors.error),
      null => ('Not submitted', AppColors.grey500),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.interSemiBold16.copyWith(
          fontSize: 11.sp,
          color: color,
        ),
      ),
    );
  }
}

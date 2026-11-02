import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AssessmentFeedbackBanner extends StatelessWidget {
  const AssessmentFeedbackBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Ink(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(colors.primary, colors.secondary, 0.2)!,
              colors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.onPrimary, size: 24.w),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 14.sp,
                      color: colors.onPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: colors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.onPrimary.withValues(alpha: 0.7),
                size: 14.w,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

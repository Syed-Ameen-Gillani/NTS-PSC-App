import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

/// Shared geometry and typography for lessons and their learning activities.
class LessonCurriculumTile extends StatelessWidget {
  const LessonCurriculumTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
    this.complete = false,
    this.loading = false,
    this.indent = 0,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool complete;
  final bool loading;
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.background,
    child: ListTile(
      minTileHeight: 62.h,
      contentPadding: EdgeInsets.fromLTRB(14.w + indent, 2.h, 14.w, 2.h),
      leading: Icon(
        complete ? Icons.check_circle_outline_rounded : icon,
        size: 22.w,
        color: complete
            ? AppColors.success
            : selected
            ? AppColors.primary
            : AppColors.grey500,
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.interMedium16.copyWith(
          fontSize: 12.sp,
          color: selected ? AppColors.primary : AppColors.onBackground,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.interRegular14.copyWith(
          fontSize: 10.sp,
          color: AppColors.grey500,
        ),
      ),
      trailing: loading
          ? SizedBox.square(
              dimension: 19.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: loading ? null : onTap,
    ),
  );
}

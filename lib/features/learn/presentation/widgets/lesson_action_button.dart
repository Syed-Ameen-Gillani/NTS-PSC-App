import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class LessonActionButton extends StatelessWidget {
  const LessonActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.onBackground,
    this.disabledColor = AppColors.grey400,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null ? disabledColor : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 68.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: effectiveColor, size: 21.w),
                child: icon,
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

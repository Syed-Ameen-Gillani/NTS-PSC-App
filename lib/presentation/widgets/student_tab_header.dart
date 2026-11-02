import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

/// Discover's title/search geometry shared by the student browsing tabs.
class StudentTabHeader extends StatelessWidget {
  const StudentTabHeader({
    super.key,
    required this.title,
    this.search,
    this.action,
  });
  final String title;
  final Widget? search;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 24.h),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(right: action == null ? 0 : 48.w),
                child: Text(
                  title,
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 24.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              if (action != null) Positioned(right: 0, child: action!),
            ],
          ),
        ),
      ),
      if (search != null) ...[
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: search!,
        ),
      ],
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.only(left: 12.w, right: 12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: const Color(0xFF5F6368), size: 24.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Search courses, exams...',
                style: AppTextStyles.interRegular16.copyWith(
                  color: const Color(0xFF5F6368),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/onboarding/presentation/widgets/page_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/colors.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 4.h,
          width: index == currentPage ? 50.w : 20.w,
          decoration: BoxDecoration(
            color: index == currentPage ? kPrimaryBlue : kPrimaryBlue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      ),
    );
  }
}
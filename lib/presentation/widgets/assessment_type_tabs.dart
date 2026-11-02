import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AssessmentTypeTabs extends StatelessWidget {
  const AssessmentTypeTabs({super.key, this.controller});

  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.grey300, width: 1.h),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 3.h,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.interMedium16.copyWith(fontSize: 14.sp),
        unselectedLabelStyle: AppTextStyles.interRegular14.copyWith(
          fontSize: 14.sp,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grey600,
        tabs: const [
          Tab(text: 'Quizzes'),
          Tab(text: 'Assignments'),
        ],
      ),
    );
  }
}

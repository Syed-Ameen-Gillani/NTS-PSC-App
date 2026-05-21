import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: AppTextStyles.interRegular16.copyWith(
                  color: AppColors.grey500,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Ahmed Ali',
                style: AppTextStyles.interBold24.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 24.sp,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 24.r,
            backgroundImage: const NetworkImage(
              'https://randomuser.me/api/portraits/men/32.jpg', // Placeholder for screenshot
            ),
          ),
        ],
      ),
    );
  }
}

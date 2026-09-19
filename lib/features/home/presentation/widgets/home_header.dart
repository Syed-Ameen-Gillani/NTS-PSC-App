import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).value;
    final userName = authState?.user?.name ?? 'Ahmed Ali';
    final userImage = authState?.user?.imagePath ?? AppAssets.teacher1;

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
                userName,
                style: AppTextStyles.interBold24.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 22.sp,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.primary,
            backgroundImage: AssetImage(userImage),
            child: userImage.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName[0] : 'S',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

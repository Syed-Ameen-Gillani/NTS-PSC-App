import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.interBold30.copyWith(
                fontSize: 28.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24.w),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: AppTextStyles.interMedium16.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStateAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileStateAsync.when(
          data: (user) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Text(
                    'Profile',
                    style: AppTextStyles.interBold30.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // User Info Header
                  Row(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(user.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 20.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              user.email,
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.grey500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            if (user.isPremium)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(100.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium, color: const Color(0xFF1976D2), size: 12.w),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Premium Member',
                                      style: AppTextStyles.interSemiBold16.copyWith(
                                        fontSize: 10.sp,
                                        color: const Color(0xFF1976D2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_outlined, color: AppColors.onBackground, size: 20.w),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Divider(color: const Color(0xFFE2E8F0), height: 1.h, thickness: 1.h),
                  SizedBox(height: 24.h),
                  
                  // Stats Row
                  Row(
                    children: [
                      _buildStatBox('${user.courses}', 'Courses'),
                      SizedBox(width: 12.w),
                      _buildStatBox('${user.quizzes}', 'Quizzes'),
                      SizedBox(width: 12.w),
                      _buildStatBox('${user.avgScore}%', 'Avg Score'),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  
                  // Settings Section
                  Text(
                    'SETTINGS',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuButton(
                    Icons.person_outline,
                    'Account Settings',
                    onTap: () => context.pushNamed(AppRoute.accountSettings.name),
                  ),
                  _buildMenuButton(Icons.credit_card_outlined, 'Payment Methods'),
                  _buildMenuButton(Icons.notifications_outlined, 'Notifications'),
                  
                  SizedBox(height: 24.h),
                  
                  // Support Section
                  Text(
                    'SUPPORT',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildMenuButton(Icons.help_outline, 'Help Center'),
                  _buildMenuButton(Icons.info_outline, 'About Us'),
                  
                  SizedBox(height: 32.h),
                  
                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        context.goNamed(AppRoute.welcome.name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF0F0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: const Color(0xFFE53935), size: 24.w),
                          SizedBox(width: 12.w),
                          Text(
                            'Log Out',
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 16.sp,
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 48.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Error loading profile')),
        ),
      ),
    );
  }
}

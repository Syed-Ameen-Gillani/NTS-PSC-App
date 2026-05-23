import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'About Us',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 48.h),
              
              // App Logo
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2), // Standard blue matching screenshot
                  borderRadius: BorderRadius.circular(24.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.import_contacts_outlined, color: Colors.white, size: 48.w),
              ),
              SizedBox(height: 24.h),
              
              // App Name
              Text(
                'LMS App',
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 28.sp,
                  color: AppColors.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              
              // Version
              Text(
                'Version 2.4.1',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 48.h),
              
              // Links Container
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                  ),
                  child: Column(
                    children: [
                      _buildLinkItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => context.pushNamed(AppRoute.termsOfService.name),
                      ),
                      _buildDivider(),
                      _buildLinkItem(
                        icon: Icons.security_outlined,
                        title: 'Privacy Policy',
                        onTap: () => context.pushNamed(AppRoute.privacyPolicy.name),
                      ),
                      _buildDivider(),
                      _buildLinkItem(
                        icon: Icons.star_border_outlined,
                        title: 'Rate the App',
                        onTap: () => context.pushNamed(AppRoute.rateApp.name),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 48.h),
              
              // Socials
              Text(
                'FOLLOW US',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.grey500,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(child: Text('𝕏', style: TextStyle(fontSize: 20.sp, color: AppColors.onBackground, fontWeight: FontWeight.bold))),
                  SizedBox(width: 16.w),
                  _buildSocialIcon(child: Icon(Icons.camera_alt_outlined, size: 22.w, color: AppColors.onBackground)),
                  SizedBox(width: 16.w),
                  _buildSocialIcon(child: Icon(Icons.facebook, size: 24.w, color: AppColors.onBackground)),
                  SizedBox(width: 16.w),
                  _buildSocialIcon(child: Icon(Icons.play_circle_outline, size: 24.w, color: AppColors.onBackground)),
                ],
              ),
              
              SizedBox(height: 80.h),
              
              // Footer
              Text(
                '© 2024 LMS App. All rights reserved.',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Made with ',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  Icon(Icons.favorite, color: const Color(0xFFF44336), size: 12.sp),
                  Text(
                    ' for learners everywhere.',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.grey500, size: 24.w),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.interMedium16.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.grey500, size: 16.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1.h,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSocialIcon({required Widget child}) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

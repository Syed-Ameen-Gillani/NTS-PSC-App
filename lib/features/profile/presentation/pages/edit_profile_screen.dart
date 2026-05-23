import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.grey900, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.grey900,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: AppColors.grey300,
            height: 1.h,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey300,
                        border: Border.all(
                          color: AppColors.grey100,
                          width: 4.w,
                        ),
                      ),
                      child: ClipOval(
                        child: Icon(
                          Icons.person,
                          size: 60.r,
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2.w,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 16.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              _buildLabel('Full Name'),
              SizedBox(height: 8.h),
              const CustomTextFormField(
                hintText: 'Ahmed Ali',
              ),
              SizedBox(height: 24.h),
              _buildLabel('Email Address'),
              SizedBox(height: 8.h),
              const CustomTextFormField(
                hintText: 'ahmed.ali@example.com',
                suffixIcon: Icon(Icons.email_outlined),
              ),
              SizedBox(height: 24.h),
              _buildLabel('Phone Number'),
              SizedBox(height: 8.h),
              const CustomTextFormField(
                hintText: '+92 300 1234567',
                suffixIcon: Icon(Icons.phone_outlined),
              ),
              SizedBox(height: 24.h),
              _buildLabel('Location'),
              SizedBox(height: 8.h),
              const CustomTextFormField(
                hintText: 'Islamabad, Pakistan',
                suffixIcon: Icon(Icons.location_on_outlined),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.grey300,
              width: 1.h,
            ),
          ),
        ),
        child: CustomButton(
          text: 'Save Changes',
          color: AppColors.primary,
          onPressed: () {
            CustomToast.showSuccess(context, message: 'Profile updated successfully');
            context.pop();
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.interSemiBold16.copyWith(
        color: AppColors.grey900,
      ),
    );
  }
}

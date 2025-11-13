import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/auth/presentation/widgets/auth_title_subtitle.dart';
import 'package:nts_psc_app/presentation/widgets/home_indicator.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

class SignupDetailsScreen extends StatelessWidget {
  const SignupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color screenBackground = Theme.of(context).colorScheme.surfaceVariant;

    // using a custom AppBar to achieve the back arrow/spacing
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // back to the previous screen
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        bottom:
            false, // Allow indicator to extend to the bottom edge
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 18.h),
              // Title and Subtitle
              AuthTitleSubtitle(
                title: 'Enter your details',
                topPadding: 0, // AppBar provides top spacing
              ),

              SizedBox(height: 51.h),
              //User Name Field
              const CustomTextFormField(
                hintText: 'User name',
                fillColor: AppColors.background,
                borderColor: Colors.transparent,
              ),
              SizedBox(height: 23.h),

              //Email Address Field (with invalid error)
              const CustomTextFormField(
                hintText: 'Email address',
                fillColor: AppColors.background,
                borderColor: Colors.transparent,
              ),

              SizedBox(height: 13.h),
              _buildValidationError(context, 'please enter valid email'),

              SizedBox(height: 14.h),
              
              const CustomTextFormField(
                hintText: 'password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                fillColor: AppColors.background,
              ),

              SizedBox(height: 13.h),
              _buildValidationError(
                context,
                'Must contain 8 character',
              ), 

              SizedBox(height: 14.h),
              // Confirm Password Field (with required validation)
              const CustomTextFormField(
                hintText: 'confirm password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                fillColor: AppColors.background,
              ),
              SizedBox(height: 13.h),
              _buildValidationError(context, 'Must match both password'),

              SizedBox(height: 76.h),

              // Sign Up Button
              CustomButton(
                text: 'Sign Up',
                onPressed: () {
                  // Navigate to success screen on success.
                },
                height: 60.h,
              ),

              SizedBox(height: 76.h), // Bottom buffer
            ],
          ),
        ),
      ),

      // Home Indicator at the bottom
      bottomNavigationBar: HomeIndicator(
        color: AppColors.primary, 
        backgroundColor: screenBackground, 
        containerHeight: 34.h, // Responsive height using ScreenUtil
        height: 5.h, // Responsive indicator bar height
        bottomPadding: 8.h, // Responsive bottom padding
      ),
    );
  }
}

//Function to build validation error messages
Widget _buildValidationError(BuildContext context, String message) {
  return Padding(
    padding: EdgeInsets.only(left: 16.w, top: 4.h, bottom: 8.h),
    child: Text(
      message,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: const Color(0xFFF04438), // error red
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

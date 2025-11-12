// lib/features/authentication/presentation/screens/forgot_password_email_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/presentation/widgets/botton_indicator.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

class ForgotPasswordEmailScreen extends StatelessWidget {
  const ForgotPasswordEmailScreen({super.key});

  // Helper for inline red error text
  Widget _buildValidationError(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 4.h, bottom: 8.h),
      child: Text(
        message,
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Color(0xFFF04438), // error red
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper for building the field label
  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 10.h, bottom: 4.h),
      child: Text(
        label,
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.onBackground,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackground = AppColors.surfaceVariant;

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {}, // Go back
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48.h), // Spacing below the AppBar

              Text(
                'Enter your email',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 24.88.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 10.h),

              const CustomTextFormField(
                hintText: 'email address',
                fillColor: AppColors.background,
                borderColor: Colors.transparent,
              ),

              SizedBox(height: 6.h),

              _buildValidationError(
                context,
                'The email address you provided is not associated with your account',
              ),

              SizedBox(height: 51.h),

              CustomButton(
                text: 'Continue',
                onPressed: () {
                  // continue action
                },
                height: 60.h,
              ),

              SizedBox(height: 396.h),
            ],
          ),
        ),
      ),
    );
  }
}

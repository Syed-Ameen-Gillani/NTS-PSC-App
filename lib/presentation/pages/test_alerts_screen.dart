import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TestAlertsScreen extends StatelessWidget {
  const TestAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Test Alerts',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Custom Toasts',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16.h),
              CustomButton(
                text: 'Show Success Toast',
                color: AppColors.primary,
                onPressed: () {
                  CustomToast.showSuccess(
                    context,
                    message: 'Action completed successfully!',
                  );
                },
              ),
              SizedBox(height: 12.h),
              CustomButton(
                text: 'Show Error Toast',
                color: AppColors.error,
                onPressed: () {
                  CustomToast.showError(
                    context,
                    message: 'Oops! Something went wrong.',
                  );
                },
              ),
              SizedBox(height: 12.h),
              CustomButton(
                text: 'Show Info Toast',
                color: AppColors.primary,
                onPressed: () {
                  CustomToast.showInfo(
                    context,
                    message: 'Here is some helpful information.',
                  );
                },
              ),
              SizedBox(height: 12.h),
              CustomButton(
                text: 'Show Standard Toast',
                color: AppColors.grey700,
                onPressed: () {
                  CustomToast.show(
                    context,
                    message: 'This is a standard toast notification.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

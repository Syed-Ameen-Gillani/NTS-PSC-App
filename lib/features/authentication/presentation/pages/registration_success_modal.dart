import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart'; 

class RegistrationSuccessModal extends StatelessWidget {
  final VoidCallback onDonePressed;

  const RegistrationSuccessModal({
    super.key,
    required this.onDonePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Access theme colors semantically
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    // We use the theme's default scaffold background for the screen (light gray-blue)
    final Color screenBgColor = Theme.of(context).colorScheme.surface;  
    // We use the theme's surface color for the inner card (white/off-white)
    final Color cardSurfaceColor = Theme.of(context).scaffoldBackgroundColor;
    final Color textColor = AppColors.onBackground;

    return Scaffold(
      // 1. SCREEN BACKGROUND: Use the theme's default background color (light gray-blue)
      backgroundColor: screenBgColor, 
      body: Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            // 2. CARD BACKGROUND: Use the theme's surface color (white/off-white)
            color: cardSurfaceColor, 
            borderRadius: BorderRadius.circular(50.r),

          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3. Icon
              CircleAvatar(
                radius: 30.r,
                backgroundColor: primaryColor,
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),

              SizedBox(height: 16.h),

              // 4. Title Text
              Text(
                'Success',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans500med24.copyWith(
                  color: textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 8.h),

              // 5. Subtitle Text
              Text(
                'Congratulations, you have completed your registration!',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans500med12.copyWith(
                  color: AppColors.grey500,
                  fontSize: 14.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // 6. Done Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: onDonePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: AppTextStyles.dmSans500med12.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
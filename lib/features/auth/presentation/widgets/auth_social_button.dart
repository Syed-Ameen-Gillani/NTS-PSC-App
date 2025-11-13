import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AuthSocialButton extends StatelessWidget {
  final String text;
  final String iconAsset;
  final VoidCallback onPressed;

  const AuthSocialButton({
    super.key,
    required this.text,
    required this.iconAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Define styles based on the Login screen design (White background, light border)
    final Color textColor = AppColors.onBackground;
    final Color borderColor = AppColors.grey300;

    return SizedBox(
       width: double.infinity,
      height: 60.h, // Fixed height from Login screen implementation

      child: OutlinedButton(
        // Use OutlinedButton for structure, customize appearance
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          // Ensure button matches the white background and gray border of the design
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.r), // Pill shape
          ),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use SvgPicture if your assets are SVGs (as inferred from your login page code)
            SvgPicture.asset(iconAsset, height: 24.h),
            SizedBox(width: 8.w),
            Text(
              text,
              style: AppTextStyles.dmSans500med12.copyWith(
                // Using dmSans500med17 as a base
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 17.28.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/authentication/presentation/widgets/auth_title_subtitle.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AuthTitleSubtitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double topPadding; // Allows caller to set specific top spacing

  const AuthTitleSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    this.topPadding = 40.0, // Default padding for spacing screens down
  });

  @override
  Widget build(BuildContext context) {
    // Access primary text color from the new theme structure
    final Color titleColor = AppColors.onBackground; 

    return Padding(
      // Top padding for the entire block
      padding: EdgeInsets.only(top: topPadding.h, bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          // 1. Main Title
          Text(
            title,
            textAlign: TextAlign.left,
            // Use dmSans500med24 (24.88pt/32pt equivalent) for the main heading
            style: AppTextStyles.dmSans500med24.copyWith(
              fontSize: 24.88.sp, // Using a slightly larger responsive size for impact
              fontWeight: FontWeight.w500, // Ensuring boldness for main titles
              color: titleColor,
            ),
          ),

          // 2. Subtitle/Description (Optional)
          if (subtitle != null) ...[
            SizedBox(height: 12.h),
            Text(
              subtitle!,
              textAlign: TextAlign.left,
              // Use dmSans500med17 (or similar body style) for descriptive text
              style: AppTextStyles.dmSans500med12.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500, // Use a semantic gray color for secondary text
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AuthTermsCheckbox extends StatefulWidget {
  const AuthTermsCheckbox({super.key});

  @override
  State<AuthTermsCheckbox> createState() => _AuthTermsCheckboxState();
}

class _AuthTermsCheckboxState extends State<AuthTermsCheckbox> {
  bool _isChecked = true; // Default state

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.primary;
    final Color bodyTextColor = AppColors.onBackground;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: _isChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isChecked = value ?? false;
                });
              },
              activeColor: primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              side: const BorderSide(color: Colors.transparent),
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return primaryColor;
                  }
                  return Colors.white;
                },
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.dmSans500med12.copyWith(
                  color: bodyTextColor.withOpacity(0.8),
                  fontSize: 12.sp,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),

                  // Terms and Conditions link
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Navigate to Terms and Conditions page
                        debugPrint('Terms and Conditions tapped');
                      },
                  ),

                  const TextSpan(text: ' and '),

                  // Privacy Policy link
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Navigate to Privacy Policy page
                        debugPrint('Privacy Policy tapped');
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

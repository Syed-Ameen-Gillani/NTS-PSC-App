import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
// import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromRGBO(228, 241, 248, 1),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),
              Text(
                textAlign: TextAlign.center,
                'Welcome!\nSign up to continue!',
                style: AppTextStyles.dmSans500med24.copyWith(
                  // color: Colors.blue,
                  // fontSize: 30.sp,
                ),
              ),
              SizedBox(height: 60.h),
              CustomTextFormField(hintText: 'Email', prefixIcon: Icons.email),
              SizedBox(height: 20.h),
              CustomTextFormField(
                hintText: 'Password',
                isPassword: true,
                prefixIcon: Icons.lock,
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(50.r),
                  overlayColor: WidgetStateProperty.all(AppColors.primaryLight.withOpacity(0.1)),
                  child: Padding(
                    padding: const EdgeInsets.all( 8.0),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.dmSans500med17.copyWith(
                        color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: true, // or false based on your state
                        onChanged: (bool? value) {},
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        fillColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors
                                .primary; // Fill color when checked (true)
                          }
                          return Colors
                              .white; // Fill color when unchecked (false)
                        }),
                        side: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.dmSans500med17.copyWith(
                            color: AppColors.onBackground,
                            fontSize: 14.sp,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Handle Terms and Conditions tap
                                },
                              text: 'Terms and Conditions',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' and Privacy Policy'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle login action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: AppTextStyles.dmSans500med17.copyWith(
                          color: Colors.white,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't have an account? ",
                      style: AppTextStyles.dmSans500med17.copyWith(
                        color: AppColors.grey500,
                        fontSize: 14.sp,
                      ),
                    ),
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Navigate to Sign Up page
                        },
                      text: "Sign Up",
                      style: AppTextStyles.dmSans500med17.copyWith(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                "OR",
                style: AppTextStyles.dmSans500med17.copyWith(
                  color: AppColors.grey500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                height: 60.h,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(AppAssets.google),
                      Expanded(flex: 1, child: SizedBox()),
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Continue with Google',
                         style: AppTextStyles.dmSans500med12.copyWith(
                          color: AppColors.onBackground,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h), // social media sign ins using elevated
              SizedBox(
                height: 60.h,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(AppAssets.facebook),
                      Expanded(flex: 1, child: SizedBox()),
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Continue with Facebook',
                          style: AppTextStyles.dmSans500med17.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 17.sp,
                            // fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ), // social media sign ins using elevated
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/utils/form_validators.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/auth/presentation/utils/auth_error_messages.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/auth/presentation/widgets/social_sign_in_action.dart';

class SignupCreateAccountScreen extends ConsumerStatefulWidget {
  const SignupCreateAccountScreen({super.key});

  @override
  ConsumerState<SignupCreateAccountScreen> createState() =>
      _SignupCreateAccountScreenState();
}

class _SignupCreateAccountScreenState
    extends ConsumerState<SignupCreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: AppTextStyles.interSemiBold16.copyWith(
          color: AppColors.onBackground,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String text, required String iconAsset}) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        onPressed: () => startSocialSignIn(
          context,
          ref,
          iconAsset == AppAssets.google
              ? OAuthProvider.google
              : OAuthProvider.apple,
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.grey300, width: 1.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconAsset.endsWith('.svg')
                ? SvgPicture.asset(iconAsset, width: 24.w, height: 24.w)
                : Image.asset(iconAsset, width: 24.w, height: 24.w),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interSemiBold16.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.goNamed(AppRoute.login.name);
      },
      child: AppScaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Create Account',
                    style: AppTextStyles.interBold30.copyWith(
                      color: AppColors.onBackground,
                      fontSize: 32.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Subtitle
                  Text(
                    'Join us to start your learning journey today.',
                    style: AppTextStyles.interRegular16.copyWith(
                      color: AppColors.grey500,
                      fontSize: 16.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Full Name Field
                  _buildFieldLabel('Full Name'),
                  CustomTextFormField(
                    controller: _nameController,
                    hintText: 'e.g. Ahmed Ali',
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.validateName,
                  ),
                  SizedBox(height: 24.h),

                  // Email Address Field
                  _buildFieldLabel('Email Address'),
                  CustomTextFormField(
                    controller: _emailController,
                    hintText: 'e.g. ahmed@example.com',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.validateEmail,
                  ),
                  SizedBox(height: 24.h),

                  // Password Field
                  _buildFieldLabel('Password'),
                  CustomTextFormField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: FormValidators.validatePassword,
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.interMedium16.copyWith(
                            color: AppColors.grey500,
                            fontSize: 14.sp,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.goNamed(AppRoute.login.name);
                          },
                          child: Text(
                            'Log In',
                            style: AppTextStyles.interBold24.copyWith(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Sign Up Button
                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authControllerProvider);
                      return CustomButton(
                        text: authState.isLoading ? 'Signing up...' : 'Sign Up',
                        onPressed: authState.isLoading
                            ? () {}
                            : () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  final success = await ref
                                      .read(authControllerProvider.notifier)
                                      .signup(
                                        name: _nameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                        role: UserRole.student,
                                      );

                                  if (!context.mounted) return;
                                  if (success) {
                                    CustomToast.showSuccess(
                                      context,
                                      message:
                                          'Account created. Please sign in.',
                                    );
                                    context.goNamed(AppRoute.login.name);
                                  } else {
                                    CustomToast.showError(
                                      context,
                                      message: signupErrorMessage(
                                        ref.read(authControllerProvider).error,
                                      ),
                                    );
                                  }
                                }
                              },
                        color: AppColors.primary,
                      );
                    },
                  ),
                  SizedBox(height: 32.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.grey300,
                          thickness: 1.h,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: AppTextStyles.interMedium16.copyWith(
                            color: AppColors.grey500,
                            fontSize: 12.sp,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.grey300,
                          thickness: 1.h,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Social Buttons
                  _buildSocialButton(
                    text: 'Continue with Google',
                    iconAsset: AppAssets.google,
                  ),
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    SizedBox(height: 16.h),
                    _buildSocialButton(
                      text: 'Continue with Apple',
                      iconAsset: AppAssets.appleSvg,
                    ),
                  ],
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

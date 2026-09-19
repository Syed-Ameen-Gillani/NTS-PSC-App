import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/form_validators.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    // Default to the role chosen in previous screens, or student
    _selectedRole = ref.read(authControllerProvider).value?.selectedRole ?? UserRole.student;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildRoleSelector() {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRole = UserRole.student);
                ref.read(authControllerProvider.notifier).selectRole(UserRole.student);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedRole == UserRole.student ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Student',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 14.sp,
                    color: _selectedRole == UserRole.student ? Colors.white : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRole = UserRole.teacher);
                ref.read(authControllerProvider.notifier).selectRole(UserRole.teacher);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedRole == UserRole.teacher ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Teacher',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 14.sp,
                    color: _selectedRole == UserRole.teacher ? Colors.white : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        onPressed: () {},
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
            Text(
              text,
              style: AppTextStyles.interSemiBold16.copyWith(
                color: AppColors.onBackground,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32.h),

                // Role selector pill
                _buildRoleSelector(),
                SizedBox(height: 28.h),

                // Title
                Text(
                  _selectedRole == UserRole.teacher ? 'Teacher Portal' : 'Welcome Back',
                  style: AppTextStyles.interBold30.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 30.sp,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  _selectedRole == UserRole.teacher
                      ? 'Log in to manage your courses, quizzes, and students.'
                      : 'Log in to your account to continue your exam preparation.',
                  style: AppTextStyles.interRegular16.copyWith(
                    color: AppColors.grey500,
                    fontSize: 15.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),

                // Email Address Field
                _buildFieldLabel('Email Address'),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'e.g. ahmed@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.validateEmail,
                ),
                SizedBox(height: 24.h),

                // Password Field & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel('Password'),
                    GestureDetector(
                      onTap: () {
                        context.pushNamed(AppRoute.forgotPassword.name);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.interMedium16.copyWith(
                            color: AppColors.primary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                CustomTextFormField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: FormValidators.validatePassword,
                ),
                SizedBox(height: 36.h),

                // Log In Button
                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authControllerProvider);
                    final isLoading = authState.isLoading;

                    return CustomButton(
                      text: isLoading ? 'Logging in...' : 'Log In',
                      onPressed: isLoading
                          ? () {}
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .login(_emailController.text.trim(), _passwordController.text, _selectedRole);

                                if (success && context.mounted) {
                                  if (_selectedRole == UserRole.teacher) {
                                    CustomToast.showSuccess(context, message: 'Welcome to Educora Teacher Studio!');
                                    context.goNamed(AppRoute.teacherMain.name);
                                  } else {
                                    CustomToast.showSuccess(context, message: 'Welcome back!');
                                    context.goNamed(AppRoute.main.name);
                                  }
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
                    Expanded(child: Divider(color: AppColors.grey300, thickness: 1.h)),
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
                    Expanded(child: Divider(color: AppColors.grey300, thickness: 1.h)),
                  ],
                ),
                SizedBox(height: 24.h),

                // Social Buttons
                _buildSocialButton(text: 'Continue with Google', iconAsset: AppAssets.google),
                SizedBox(height: 16.h),
                _buildSocialButton(text: 'Continue with Apple', iconAsset: AppAssets.appleSvg),
                SizedBox(height: 32.h),

                // Footer Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.interMedium16.copyWith(
                        color: AppColors.grey500,
                        fontSize: 14.sp,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (_selectedRole == UserRole.teacher) {
                          context.pushReplacementNamed(AppRoute.teacherSignup.name);
                        } else {
                          context.pushReplacementNamed(AppRoute.signup.name);
                        }
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.interBold24.copyWith(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

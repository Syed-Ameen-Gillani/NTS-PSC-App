import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/form_validators.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // Title
              Text(
                'Forgot Password',
                style: AppTextStyles.interBold30.copyWith(
                  color: AppColors.onBackground,
                  fontSize: 32.sp,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Enter your email address and we will send you a password reset link.',
                style: AppTextStyles.interRegular16.copyWith(
                  color: AppColors.grey500,
                  fontSize: 16.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 48.h),

              // Email Address Field
              _buildFieldLabel('Email Address'),
              CustomTextFormField(
                controller: _emailController,
                hintText: 'e.g. ahmed@example.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.validateEmail,
              ),
              
              SizedBox(height: 40.h),

              // Send Reset Link Button
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authControllerProvider);
                  return CustomButton(
                    text: authState.isLoading ? 'Sending...' : 'Send Reset Link',
                    onPressed: authState.isLoading
                        ? () {}
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final success = await ref
                                  .read(authControllerProvider.notifier)
                                  .sendPasswordReset(_emailController.text.trim());
                                  
                              if (success && context.mounted) {
                                CustomToast.showSuccess(
                                  context,
                                  message: 'Password reset link sent to your email',
                                );
                                context.pop();
                              }
                            }
                          },
                    color: AppColors.primary,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

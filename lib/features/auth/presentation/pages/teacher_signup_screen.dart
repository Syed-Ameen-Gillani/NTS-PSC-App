import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/form_validators.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherSignupScreen extends ConsumerStatefulWidget {
  const TeacherSignupScreen({super.key});

  @override
  ConsumerState<TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends ConsumerState<TeacherSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSubject = 'Pakistan Affairs';
  final List<String> _subjects = [
    'Pakistan Affairs',
    'Current Affairs & GK',
    'Everyday & General Science',
    'English Grammar & Précis',
    'Islamic Studies',
    'Customs & Tax Laws',
    'Kashmir Studies (AJK PSC)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _qualificationController.dispose();
    _bioController.dispose();
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
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Instructor Registration',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Join the Faculty',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 24.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Create instructor profile to start publishing courses and quizzes for competitive exams.',
                  style: AppTextStyles.interRegular14.copyWith(
                    color: AppColors.grey500,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 24.h),

                // Full Name
                _buildFieldLabel('Full Name & Title'),
                CustomTextFormField(
                  controller: _nameController,
                  hintText: 'e.g. Sir Tariq Mahmood / Dr. Usman',
                  prefixIcon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                ),
                SizedBox(height: 16.h),

                // Email
                _buildFieldLabel('Official / Academic Email'),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Enter email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.validateEmail,
                ),
                SizedBox(height: 16.h),

                // Password
                _buildFieldLabel('Password'),
                CustomTextFormField(
                  controller: _passwordController,
                  hintText: 'Create a secure password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: FormValidators.validatePassword,
                ),
                SizedBox(height: 16.h),

                // Primary Teaching Subject
                _buildFieldLabel('Primary Subject / Specialization'),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey500),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(
                            subject,
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSubject = val);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Qualification
                _buildFieldLabel('Highest Academic Qualification'),
                CustomTextFormField(
                  controller: _qualificationController,
                  hintText: 'e.g. M.Phil Political Science / Former CSP',
                  prefixIcon: Icons.workspace_premium_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your qualification' : null,
                ),
                SizedBox(height: 16.h),

                // Bio
                _buildFieldLabel('Instructor Bio & Experience'),
                CustomTextFormField(
                  controller: _bioController,
                  hintText: 'Briefly describe your teaching background and competitive exam experience...',
                  maxLines: 3,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please provide a brief bio' : null,
                ),
                SizedBox(height: 32.h),

                // Submit Button
                CustomButton(
                  text: authState.isLoading ? 'Signing up...' : 'Sign Up',
                  color: AppColors.primary,
                  onPressed: authState.isLoading
                      ? () {}
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            final success = await ref.read(authControllerProvider.notifier).signup(
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  role: UserRole.teacher,
                                  subject: _selectedSubject,
                                  qualification: _qualificationController.text.trim(),
                                  bio: _bioController.text.trim(),
                                );

                            if (success && context.mounted) {
                              CustomToast.showSuccess(
                                context,
                                message: 'Instructor account registered! Welcome to Educora Studio.',
                              );
                              context.goNamed(AppRoute.teacherMain.name);
                            }
                          }
                        },
                ),
                SizedBox(height: 24.h),

                // Footer Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered as an instructor? ',
                      style: AppTextStyles.interMedium16.copyWith(
                        color: AppColors.grey500,
                        fontSize: 13.sp,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.pushReplacementNamed(AppRoute.teacherLogin.name),
                      child: Text(
                        'Log In',
                        style: AppTextStyles.interBold24.copyWith(
                          color: AppColors.primary,
                          fontSize: 13.sp,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_confirmation_dialog.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final deleteConfirmationProvider = StateProvider<String>((ref) => '');

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmText = ref.watch(deleteConfirmationProvider);
    final isConfirmed = confirmText == 'DELETE';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Delete',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.h),
              // Container(
              //   width: 96.w,
              //   height: 96.w,
              //   decoration: const BoxDecoration(
              //     color: Color(0xFFFCE4EC),
              //     shape: BoxShape.circle,
              //   ),
              // ),
              // SizedBox(height: 24.h),
              Text(
                'Are you sure?',
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 28.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Deleting your account is permanent. This action cannot be undone and you will lose access to all your data.',
                textAlign: TextAlign.center,
                style: AppTextStyles.interRegular16.copyWith(
                  color: AppColors.grey500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you will lose:',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 16.sp,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildBulletPoint(
                      'All your enrolled courses and learning progress.',
                    ),
                    SizedBox(height: 12.h),
                    _buildBulletPoint(
                      'All earned certificates and achievements.',
                    ),
                    SizedBox(height: 12.h),
                    _buildBulletPoint(
                      'Your profile information and account settings.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'To confirm, type "DELETE" below',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              CustomTextFormField(
                hintText: 'Type DELETE',
                onChanged: (val) =>
                    ref.read(deleteConfirmationProvider.notifier).state = val,
              ),
              SizedBox(height: 48.h),

              SizedBox(
                width: double.infinity,
                height: 68.h,
                child: ElevatedButton(
                  onPressed: isConfirmed
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => CustomConfirmationDialog(
                              title: 'Final Confirmation',
                              content:
                                  'Are you absolutely sure you want to permanently delete your account? This action cannot be undone.',
                              confirmText: 'Confirm',
                              cancelText: 'Cancel',
                              isDestructive: true,
                              onConfirm: () {
                                CustomToast.show(context, message: 'Account deleted successfully');
                                context.goNamed(AppRoute.welcome.name);
                              },
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Delete My Account',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      color: isConfirmed ? Colors.white : AppColors.grey500,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6.h, right: 8.w),
          child: CircleAvatar(
            radius: 3.r,
            backgroundColor: const Color(0xFFD32F2F),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 14.sp,
              color: const Color(0xFFD32F2F),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

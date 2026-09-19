import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_confirmation_dialog.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  Widget _buildGroupedSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h, top: 16.h),
          child: Text(
            title,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFFFEBEE) : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primary,
              size: 20.w,
            ),
          ),
          title: Text(
            title,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 14.sp,
              color: isDestructive ? AppColors.error : AppColors.onBackground,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                )
              : null,
          trailing: Icon(Icons.arrow_forward_ios, size: 14.w, color: AppColors.grey400),
          onTap: onTap,
        ),
      ),
      if (showDivider)
        Divider(height: 1.h, color: AppColors.grey300, indent: 56.w),
    ],
  );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Faculty Profile',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Instructor Profile Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundImage: const AssetImage('assets/images/teacher1.png'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.verified, color: Colors.white, size: 16.w),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Sir Tariq Mahmood',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Pakistan Affairs & GK Specialist',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'M.Phil Political Science / Former Civil Servant',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Payout Settings
              _buildGroupedSection(
                title: 'ROYALTIES & PAYOUTS',
                items: [
                  _buildSettingTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payout Accounts & Balances',
                    subtitle: 'Manage Easypaisa, JazzCash & Bank transfers',
                    onTap: () {
                      context.pushNamed(AppRoute.teacherPayouts.name);
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Payout History & Ledger',
                    subtitle: 'View disbursement records and receipts',
                    showDivider: false,
                    onTap: () {
                      context.pushNamed(AppRoute.teacherPayouts.name);
                    },
                  ),
                ],
              ),

              // Studio & Teaching Settings
              _buildGroupedSection(
                title: 'STUDIO PREFERENCES',
                items: [
                  _buildSettingTile(
                    icon: Icons.videocam_outlined,
                    title: 'Live Masterclass Studio',
                    subtitle: 'Schedule webinars and live workshops',
                    onTap: () {
                      context.pushNamed(AppRoute.teacherLiveClasses.name);
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.question_answer_outlined,
                    title: 'Student Q&A & Doubts',
                    subtitle: 'Resolve questions from enrolled students',
                    onTap: () {
                      context.pushNamed(AppRoute.teacherDoubts.name);
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Switch to Student Learning Mode',
                    subtitle: 'Browse courses & take tests as a student',
                    showDivider: false,
                    onTap: () {
                      ref.read(authControllerProvider.notifier).selectRole(UserRole.student);
                      CustomToast.showSuccess(context, message: 'Switched to Student Mode.');
                      context.goNamed(AppRoute.main.name);
                    },
                  ),
                ],
              ),

              // Account / Logout
              _buildGroupedSection(
                title: 'ACCOUNT',
                items: [
                  _buildSettingTile(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    isDestructive: true,
                    showDivider: false,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => CustomConfirmationDialog(
                          title: 'Log Out from Studio?',
                          content: 'Are you sure you want to log out from the Educora instructor portal?',
                          confirmText: 'Log Out',
                          cancelText: 'Cancel',
                          isDestructive: true,
                          icon: Icons.logout_rounded,
                          onConfirm: () async {
                            await ref.read(authControllerProvider.notifier).logout();
                            if (context.mounted) {
                              context.goNamed(AppRoute.welcomeRole.name);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.settingsCardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.settingsCardBorder, width: 1.w),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.interBold30.copyWith(
                fontSize: 28.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection({
    required String title,
    required List<Widget> items,
  }) {
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
            color: AppColors.settingsCardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.settingsCardBorder, width: 1.w),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 4.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFFFEBEE)
                    : AppColors.surface,
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
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14.w,
              color: AppColors.grey400,
            ),
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
    final profileStateAsync = ref.watch(profileControllerProvider);

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileStateAsync.when(
          data: (user) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Text(
                    'Profile',
                    style: AppTextStyles.interBold30.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // User Info Header
                  Row(
                    children: [
                      AppAvatar(
                        size: 80.w,
                        imagePath: user.imagePath,
                        name: user.name,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 20.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              user.email,
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.grey500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            if (user.isPremium)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(100.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: const Color(0xFF1976D2),
                                      size: 12.w,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Premium Member',
                                      style: AppTextStyles.interSemiBold16
                                          .copyWith(
                                            fontSize: 10.sp,
                                            color: const Color(0xFF1976D2),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Edit profile',
                        child: Material(
                          color: const Color(0xFFF8F9FA),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                context.pushNamed(AppRoute.editProfile.name),
                            child: SizedBox.square(
                              dimension: 40.w,
                              child: Icon(
                                Icons.edit_outlined,
                                color: AppColors.onBackground,
                                size: 20.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Divider(
                    color: const Color(0xFFE2E8F0),
                    height: 1.h,
                    thickness: 1.h,
                  ),
                  SizedBox(height: 24.h),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatBox('${user.courses}', 'Courses'),
                      SizedBox(width: 12.w),
                      _buildStatBox('${user.quizzes}', 'Quizzes'),
                      SizedBox(width: 12.w),
                      _buildStatBox('${user.avgScore}%', 'Avg Score'),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  _buildGroupedSection(
                    title: 'SETTINGS',
                    items: [
                      _buildSettingTile(
                        icon: Icons.language_outlined,
                        title: 'App Language',
                        onTap: () =>
                            context.pushNamed(AppRoute.appLanguage.name),
                      ),
                      _buildSettingTile(
                        icon: Icons.credit_card_outlined,
                        title: 'Payment Methods',
                        onTap: () =>
                            context.pushNamed(AppRoute.paymentMethods.name),
                      ),
                      _buildSettingTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        showDivider: false,
                        onTap: () =>
                            context.pushNamed(AppRoute.notifications.name),
                      ),
                    ],
                  ),
                  _buildGroupedSection(
                    title: 'SUPPORT',
                    items: [
                      _buildSettingTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                      ),
                      _buildSettingTile(
                        icon: Icons.info_outline,
                        title: 'About Us',
                        onTap: () => context.pushNamed(AppRoute.aboutUs.name),
                      ),
                      _buildSettingTile(
                        icon: Icons.school_outlined,
                        title: 'Teacher & Instructor Studio',
                        showDivider: false,
                        onTap: () {
                          ref
                              .read(authControllerProvider.notifier)
                              .selectRole(UserRole.teacher);
                          CustomToast.showSuccess(
                            context,
                            message: 'Switched to Teacher Studio.',
                          );
                          context.goNamed(AppRoute.teacherMain.name);
                        },
                      ),
                    ],
                  ),
                  _buildGroupedSection(
                    title: 'ACCOUNT',
                    items: [
                      _buildSettingTile(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        isDestructive: true,
                        onTap: () =>
                            context.pushNamed(AppRoute.deleteAccount.name),
                      ),
                      _buildSettingTile(
                        icon: Icons.logout_rounded,
                        title: 'Log Out',
                        isDestructive: true,
                        showDivider: false,
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Log out?'),
                              content: const Text(
                                'You will need to sign in again to continue.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Log out'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted) {
                            CustomToast.showInfo(
                              context,
                              message: 'Logged out successfully.',
                            );
                            context.goNamed(AppRoute.welcomeRole.name);
                          }
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 48.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            final signedIn =
                ref.watch(authControllerProvider).value?.user != null;
            return Center(
              child: TextButton.icon(
                onPressed: signedIn
                    ? () => ref.invalidate(profileControllerProvider)
                    : () => context.goNamed(AppRoute.welcomeRole.name),
                icon: Icon(signedIn ? Icons.refresh : Icons.login),
                label: Text(
                  signedIn
                      ? 'Retry loading profile'
                      : 'Sign in to view your profile',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

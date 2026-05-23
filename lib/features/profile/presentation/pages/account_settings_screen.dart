import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _twoFactorEnabled = false;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, bottom: 8.h, top: 24.h),
      child: Text(
        title,
        style: AppTextStyles.interSemiBold16.copyWith(
          fontSize: 12.sp,
          color: AppColors.grey500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGroupedContainer({required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isDestructive = false,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    final iconColor = isDestructive
        ? const Color(0xFFD32F2F)
        : const Color(0xFF1976D2);
    final iconBgColor = isDestructive
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE3F2FD);
    final titleColor = isDestructive
        ? const Color(0xFFD32F2F)
        : AppColors.onBackground;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 16.sp,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  Icon(
                    Icons.chevron_right,
                    color: isDestructive
                        ? const Color(0xFFD32F2F)
                        : AppColors.grey500,
                    size: 20.w,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 68.w),
            child: Divider(
              color: const Color(0xFFDADCE0),
              height: 1.h,
              thickness: 1.h,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Account Settings',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 48.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildSectionHeader('SECURITY'),
              // _buildGroupedContainer(
              //   children: [
              //     _buildSettingItem(
              //       icon: Icons.lock_outline,
              //       title: 'Change Password',
              //       subtitle: 'Update your login password',
              //     ),
              //     _buildSettingItem(
              //       icon: Icons.verified_user_outlined,
              //       title: 'Two-Factor Authentication',
              //       subtitle: 'Adds an extra layer of security',
              //       trailing: Switch(
              //         value: _twoFactorEnabled,
              //         onChanged: (value) {
              //           setState(() {
              //             _twoFactorEnabled = value;
              //           });
              //         },
              //         activeColor: Colors.white,
              //         activeTrackColor: AppColors.primary,
              //         inactiveThumbColor: Colors.white,
              //         inactiveTrackColor: AppColors.grey300,
              //       ),
              //     ),
              //     _buildSettingItem(
              //       icon: Icons.smartphone_outlined,
              //       title: 'Active Devices',
              //       subtitle: 'Manage devices logged into your account',
              //       showDivider: false,
              //     ),
              //   ],
              // ),

              _buildSectionHeader('PREFERENCES'),
              _buildGroupedContainer(
                children: [
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'App Language',
                    showDivider: false,
                    onTap: () => context.pushNamed(AppRoute.appLanguage.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'English (US)',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.grey500,
                          size: 20.w,
                        ),
                      ],
                    ),
                  ),
                  // _buildSettingItem(
                  //   icon: Icons.dark_mode_outlined,
                  //   title: 'Theme',
                  //   showDivider: false,
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Text(
                  //         'System Default',
                  //         style: AppTextStyles.interRegular14.copyWith(
                  //           fontSize: 14.sp,
                  //           color: AppColors.grey500,
                  //         ),
                  //       ),
                  //       SizedBox(width: 8.w),
                  //       Icon(
                  //         Icons.chevron_right,
                  //         color: AppColors.grey500,
                  //         size: 20.w,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),

              _buildSectionHeader('PRIVACY & DATA'),
              _buildGroupedContainer(
                children: [
                  // _buildSettingItem(
                  //   icon: Icons.file_download_outlined,
                  //   title: 'Download My Data',
                  // ),
                  _buildSettingItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    isDestructive: true,
                    showDivider: false,
                    onTap: () => context.pushNamed(AppRoute.deleteAccount.name),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

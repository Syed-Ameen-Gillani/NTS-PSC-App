import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

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
          'Notifications',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('DELIVERY METHODS'),
              SizedBox(height: 16.h),
              _buildSectionContainer(
                children: [
                  _buildToggleItem(
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts on your device',
                    value: state.pushNotifications,
                    onChanged: notifier.togglePushNotifications,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Email Notifications',
                    subtitle: 'Receive daily and weekly summaries',
                    value: state.emailNotifications,
                    onChanged: notifier.toggleEmailNotifications,
                  ),
                  // _buildDivider(),
                  // _buildToggleItem(
                  //   title: 'SMS Notifications',
                  //   subtitle: 'Receive critical alerts via text',
                  //   value: state.smsNotifications,
                  //   onChanged: notifier.toggleSmsNotifications,
                  // ),
                ],
              ),
              SizedBox(height: 32.h),
              _buildSectionTitle('NOTIFICATION TYPES'),
              SizedBox(height: 16.h),
              _buildSectionContainer(
                children: [
                  _buildToggleItem(
                    title: 'Course Updates',
                    subtitle: 'New lessons and materials',
                    value: state.courseUpdates,
                    onChanged: notifier.toggleCourseUpdates,
                    icon: Icons.menu_book_outlined,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Messages & Discussions',
                    subtitle: 'Replies and direct messages',
                    value: state.messagesDiscussions,
                    onChanged: notifier.toggleMessagesDiscussions,
                    icon: Icons.chat_bubble_outline,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Exam Results',
                    subtitle: 'Scores and evaluations',
                    value: state.examResults,
                    onChanged: notifier.toggleExamResults,
                    icon: Icons.badge_outlined,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    title: 'Promotions',
                    subtitle: 'Special offers and discounts',
                    value: state.promotions,
                    onChanged: notifier.togglePromotions,
                    icon: Icons.star_border,
                  ),
                ],
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.interBold24.copyWith(
        fontSize: 14.sp,
        color: AppColors.grey500,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        color: const Color(0xFFE2E8F0),
        height: 1.h,
        thickness: 1.h,
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1976D2),
                size: 20.w,
              ),
            ),
            SizedBox(width: 16.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interMedium16.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1976D2),
            trackColor: const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }
}

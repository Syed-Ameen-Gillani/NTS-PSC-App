import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_wallet_screen.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class AddPaymentMethodScreen extends ConsumerWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Add Payment Method',
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
              _buildSectionHeader('SELECT METHOD TYPE'),
              SizedBox(height: 16.h),
              _buildMethodTypeItem(
                icon: _buildIcon(Icons.credit_card, AppColors.primary),
                title: 'Credit or Debit Card',
                subtitle: 'Visa, Mastercard',
                onTap: () => context.pushNamed(AppRoute.addCard.name),
              ),
              SizedBox(height: 12.h),
              _buildMethodTypeItem(
                icon: _buildIcon(Icons.phone_android, const Color(0xFF10B981)),
                title: 'Easypaisa Account',
                subtitle: 'Link your mobile wallet',
                onTap: () => context.pushNamed(AppRoute.addWallet.name, extra: WalletType.easypaisa),
              ),
              SizedBox(height: 12.h),
              _buildMethodTypeItem(
                icon: _buildIcon(Icons.phone_android, const Color(0xFFF59E0B)),
                title: 'JazzCash Account',
                subtitle: 'Link your mobile wallet',
                onTap: () => context.pushNamed(AppRoute.addWallet.name, extra: WalletType.jazzcash),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.interBold24.copyWith(
        fontSize: 14.sp,
        color: AppColors.grey500,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMethodTypeItem({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
              ),
              alignment: Alignment.center,
              child: icon,
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
            Icon(Icons.chevron_right, color: AppColors.grey500, size: 20.w),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData iconData, Color color) {
    return Icon(iconData, color: color, size: 16.w);
  }
}

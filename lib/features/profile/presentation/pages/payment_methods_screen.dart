import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_confirmation_dialog.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_wallet_screen.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

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
          'Payment Methods',
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
              _buildSectionHeader('SAVED CARDS'),
              SizedBox(height: 16.h),
              _buildPaymentItem(
                context,
                icon: _buildMastercardIcon(),
                title: 'Mastercard **** 1234',
                subtitle: 'Expires 12/25',
                onEdit: () => context.pushNamed(AppRoute.addCard.name),
                onDelete: () {
                  CustomToast.show(context, message: 'Payment method removed');
                },
              ),
              SizedBox(height: 12.h),
              _buildPaymentItem(
                context,
                icon: _buildVisaIcon(),
                title: 'Visa **** 5678',
                subtitle: 'Expires 08/24',
                onEdit: () => context.pushNamed(AppRoute.addCard.name),
                onDelete: () {
                  CustomToast.show(context, message: 'Payment method removed');
                },
              ),
              SizedBox(height: 32.h),
              _buildSectionHeader('MOBILE WALLETS'),
              SizedBox(height: 16.h),
              _buildPaymentItem(
                context,
                icon: _buildWalletIcon(const Color(0xFF10B981)), 
                title: 'Easypaisa',
                subtitle: '+92 *** *** 1234',
                onEdit: () => context.pushNamed(AppRoute.addWallet.name, extra: WalletType.easypaisa),
                onDelete: () {
                  CustomToast.show(context, message: 'Payment method removed');
                },
              ),
              SizedBox(height: 12.h),
              _buildPaymentItem(
                context,
                icon: _buildWalletIcon(const Color(0xFFF59E0B)), 
                title: 'JazzCash',
                subtitle: '+92 *** *** 5678',
                onEdit: () => context.pushNamed(AppRoute.addWallet.name, extra: WalletType.jazzcash),
                onDelete: () {
                  CustomToast.show(context, message: 'Payment method removed');
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        child: GestureDetector(
          onTap: () => context.pushNamed(AppRoute.addPaymentMethod.name), 
          child: Container(
            height: 56.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary, size: 20.w),
                SizedBox(width: 8.w),
                Text(
                  'Add New Payment Method',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
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

  Widget _buildPaymentItem(BuildContext context, {required Widget icon, required String title, required String subtitle, required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Container(
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
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, color: AppColors.grey500, size: 20.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              color: Colors.white,
              elevation: 4,
              offset: Offset(0, 40.h),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (context) => CustomConfirmationDialog(
                      title: 'Payment Method',
                      content: 'Are you sure you want to remove this payment method?',
                      confirmText: 'Remove',
                      cancelText: 'Cancel',
                      isDestructive: true,
                      icon: Icons.delete_outline,
                      onConfirm: onDelete,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: AppColors.grey500, size: 20.w),
                      SizedBox(width: 12.w),
                      Text(
                        'Edit',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 20.w),
                      SizedBox(width: 12.w),
                      Text(
                        'Delete',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 14.sp,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMastercardIcon() {
    return SizedBox(
      width: 24.w,
      height: 16.h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(width: 16.w, height: 16.w, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 0,
            child: Container(width: 16.w, height: 16.w, decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.8), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaIcon() {
    return Text(
      'VISA',
      style: TextStyle(
        color: const Color(0xFF1A1F71),
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 10.sp,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildWalletIcon(Color color) {
    return Icon(Icons.phone_android, color: color, size: 16.w);
  }
}

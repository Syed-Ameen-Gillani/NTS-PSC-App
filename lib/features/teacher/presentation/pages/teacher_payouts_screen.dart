import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherPayoutsScreen extends ConsumerStatefulWidget {
  const TeacherPayoutsScreen({super.key});

  @override
  ConsumerState<TeacherPayoutsScreen> createState() => _TeacherPayoutsScreenState();
}

class _TeacherPayoutsScreenState extends ConsumerState<TeacherPayoutsScreen> {
  void _showRequestPayoutModal(BuildContext context) {
    final amountController = TextEditingController(text: '34500');
    final accountController = TextEditingController(text: '0345-9871234');
    String selectedMethod = 'Easypaisa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Request Payout Withdrawal', style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                SizedBox(height: 16.h),
                Text('Available Balance for Withdrawal', style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.grey500)),
                SizedBox(height: 4.h),
                Text('Rs 34,500', style: AppTextStyles.interBold30.copyWith(fontSize: 24.sp, color: AppColors.primary)),
                SizedBox(height: 16.h),
                Text('Withdrawal Method', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                SizedBox(height: 8.h),
                Row(
                  children: ['Easypaisa', 'JazzCash', 'Bank Transfer'].map((m) {
                    final isSel = selectedMethod == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedMethod = m),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.surface : AppColors.grey100,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.grey300),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m,
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 11.sp,
                              color: isSel ? AppColors.primary : AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                Text('Withdrawal Amount (Rs)', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                SizedBox(height: 6.h),
                CustomTextFormField(controller: amountController, hintText: '34500', keyboardType: TextInputType.number),
                SizedBox(height: 12.h),
                Text('Account Number / IBAN', style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                SizedBox(height: 6.h),
                CustomTextFormField(controller: accountController, hintText: '03XX-XXXXXXX'),
                SizedBox(height: 20.h),
                CustomButton(
                  text: 'Confirm & Transfer Funds',
                  onPressed: () {
                    final amountVal = amountController.text.trim();
                    if (amountVal.isNotEmpty) {
                      ref.read(teacherControllerProvider.notifier).requestPayout(
                            amount: 'Rs $amountVal',
                            method: selectedMethod,
                            accountNumber: accountController.text.trim(),
                          );
                      Navigator.pop(ctx);
                      CustomToast.showSuccess(context, message: 'Payout of Rs $amountVal initiated via $selectedMethod!');
                    }
                  },
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500)),
              Icon(icon, color: color, size: 16.w),
            ],
          ),
          SizedBox(height: 8.h),
          Text(amount, style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);

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
          'Financial & Payouts',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp, color: AppColors.onBackground),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            final payouts = state.payouts;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E75F1), Color(0xFF0F4DB8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance for Payout',
                            style: AppTextStyles.interMedium16.copyWith(fontSize: 13.sp, color: Colors.white70)),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rs 34,500',
                                style: AppTextStyles.interBold30.copyWith(fontSize: 28.sp, color: Colors.white)),
                            ElevatedButton(
                              onPressed: () => _showRequestPayoutModal(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              ),
                              child: Text('Withdraw Funds',
                                  style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text('Automatic payouts are processed every 1st and 15th of the month.',
                            style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: Colors.white70)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 2x2 Breakdown Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Gross Sales',
                          'Rs 105,625',
                          AppColors.onBackground,
                          Icons.trending_up,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildSummaryCard(
                          'Net Earnings (80%)',
                          'Rs 84,500',
                          const Color(0xFF10B981),
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Withdrawn',
                          'Rs 50,000',
                          const Color(0xFF8B5CF6),
                          Icons.check_circle_outline,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildSummaryCard(
                          'Platform Fee (20%)',
                          'Rs 21,125',
                          AppColors.grey500,
                          Icons.pie_chart_outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  // Transaction History Header
                  Text('Payout History (${payouts.length})',
                      style: AppTextStyles.interBold24.copyWith(fontSize: 17.sp, color: AppColors.onBackground)),
                  SizedBox(height: 14.h),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payouts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final payout = payouts[index];
                      final isCompleted = payout.status == 'Completed';

                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.grey300, width: 1.w),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.hourglass_top,
                                color: isCompleted ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                size: 16.w,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${payout.method} • ${payout.accountNumber}',
                                      style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp)),
                                  SizedBox(height: 2.h),
                                  Text('${payout.transactionId} • ${payout.date}',
                                      style: AppTextStyles.interRegular14
                                          .copyWith(fontSize: 11.sp, color: AppColors.grey500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(payout.amount,
                                    style: AppTextStyles.interBold24.copyWith(fontSize: 14.sp, color: AppColors.onBackground)),
                                SizedBox(height: 2.h),
                                Text(payout.status,
                                    style: AppTextStyles.interSemiBold16.copyWith(
                                      fontSize: 11.sp,
                                      color: isCompleted ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading payouts')),
        ),
      ),
    );
  }
}

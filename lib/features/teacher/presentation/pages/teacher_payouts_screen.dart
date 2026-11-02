import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';

class TeacherPayoutsScreen extends ConsumerWidget {
  const TeacherPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financial = ref.watch(teacherFinancialOverviewProvider);
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20.w,
          ),
          onPressed: context.pop,
        ),
        title: Text(
          'Financial & Payouts',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: financial.when(
          data: (overview) => _PayoutContent(overview: overview),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load financial data.',
                    style: AppTextStyles.interMedium16.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(teacherFinancialOverviewProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PayoutContent extends StatelessWidget {
  const _PayoutContent({required this.overview});

  final TeacherFinancialOverview overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
      children: [
        _BalancePanel(overview: overview),
        SizedBox(height: 24.h),
        Text(
          'Earnings overview',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 17.sp,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: 12.h),
        _FinancialSummary(overview: overview),
        SizedBox(height: 28.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Payout history',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 17.sp,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            Text(
              '${overview.payouts.length} records',
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (overview.payouts.isEmpty)
          const _EmptyPayoutHistory()
        else
          ...overview.payouts.map(
            (payout) => _PayoutRow(overview: overview, payout: payout),
          ),
      ],
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.overview});

  final TeacherFinancialOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 11.sp,
              color: AppColors.onPrimary.withValues(alpha: 0.76),
            ),
          ),
          SizedBox(height: 8.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              overview.formatMinor(overview.availableBalanceMinor),
              style: AppTextStyles.interBold30.copyWith(
                fontSize: 32.sp,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${overview.formatMinor(overview.pendingBalanceMinor)} pending clearance',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              color: AppColors.onPrimary.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.onPrimary.withValues(
                  alpha: 0.12,
                ),
                side: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.48),
                ),
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Withdrawals available after PayFast setup',
                textAlign: TextAlign.center,
                style: AppTextStyles.interSemiBold16.copyWith(fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.overview});

  final TeacherFinancialOverview overview;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Gross sales', overview.grossSalesMinor),
      ('Net earnings', overview.netEarningsMinor),
      ('Platform fees', overview.platformFeeMinor),
      ('Withdrawn', overview.totalWithdrawnMinor),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8.w) / 2;
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.grey300, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            overview.formatMinor(item.$2),
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 17.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EmptyPayoutHistory extends StatelessWidget {
  const _EmptyPayoutHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Column(
        children: [
          Text(
            'No payouts yet',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 14.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Completed and processing payouts will be listed here once the payment provider is connected.',
            textAlign: TextAlign.center,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              height: 1.4,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.overview, required this.payout});

  final TeacherFinancialOverview overview;
  final TeacherPayoutModel payout;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (payout.status) {
      'completed' => AppColors.success,
      'failed' || 'cancelled' => AppColors.error,
      _ => AppColors.primary,
    };
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_methodLabel(payout.method)} · ${payout.accountMask}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _dateLabel(payout.requestedAt),
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                overview.formatMinor(payout.amountMinor),
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                _statusLabel(payout.status),
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _methodLabel(String value) => switch (value) {
    'easypaisa' => 'Easypaisa',
    'jazzcash' => 'JazzCash',
    _ => 'Bank transfer',
  };

  static String _statusLabel(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';

  static String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

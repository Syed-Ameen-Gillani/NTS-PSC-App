import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

final selectedOptionProvider = StateProvider<int?>((ref) => 1);

class ActiveQuizScreen extends ConsumerWidget {
  const ActiveQuizScreen({super.key});

  final List<String> options = const [
    'United Arab Emirates',
    'Switzerland',
    'Singapore',
    'Brazil',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(selectedOptionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.grey900, size: 24.w),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Question 1 of 15',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 16.sp,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.grey900, size: 20.w),
              SizedBox(width: 4.w),
              Text(
                '09:59',
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.grey900,
                ),
              ),
              SizedBox(width: 24.w),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(color: AppColors.primary, height: 4.h),
              ),
              Expanded(
                flex: 14,
                child: Container(color: AppColors.grey300, height: 4.h),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CURRENT AFFAIRS',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Medium',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'Which country is set to host the upcoming 2024 Global Economic Summit?',
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 24.sp,
                  color: AppColors.grey900,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 32.h),
              ...List.generate(options.length, (index) {
                final isSelected = selectedOption == index;
                final letter = String.fromCharCode(65 + index); // A, B, C, D

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedOptionProvider.notifier).state = index;
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey300,
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : const Color(0xFFF8F9FA),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 14.sp,
                              color: isSelected ? Colors.white : AppColors.grey700,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            options[index],
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 16.sp,
                              color: isSelected ? AppColors.grey900 : AppColors.grey900,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_outline, color: AppColors.primary, size: 24.w)
                        else
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.grey300, width: 2.w),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        child: CustomButton(
          text: 'Next Question',
          onPressed: () => context.pushNamed(AppRoute.quizCompleted.name), 
          trailingIcon: Icon(Icons.arrow_forward, color: Colors.white, size: 20.w),
        ),
      ),
    );
  }
}

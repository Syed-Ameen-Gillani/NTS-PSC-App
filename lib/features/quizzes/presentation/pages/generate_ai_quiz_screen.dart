import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

final quizDifficultyProvider = StateProvider<String>((ref) => 'Medium');
final quizQuestionsProvider = StateProvider<int>((ref) => 15);

class GenerateAiQuizScreen extends ConsumerWidget {
  const GenerateAiQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(quizDifficultyProvider);
    final numQuestions = ref.watch(quizQuestionsProvider);

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
          'Generate AI Quiz',
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
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 20.w),
                  SizedBox(width: 8.w),
                  Text(
                    'Custom AI Quiz Builder',
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Select your preferences and let our AI create a personalized quiz for you.',
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              
              _buildLabel('Topic or Subject'),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.grey300, width: 1.w),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Affairs',
                      style: AppTextStyles.interRegular16.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: AppColors.grey500),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              _buildLabel('Specific Focus (Optional)'),
              SizedBox(height: 8.h),
              const CustomTextFormField(
                hintText: 'e.g. International relations, Pakistan economy...',
                maxLines: 3,
              ),
              
              SizedBox(height: 24.h),
              _buildLabel('Difficulty Level'),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildDifficultyOption(context, ref, 'Easy', difficulty),
                  SizedBox(width: 12.w),
                  _buildDifficultyOption(context, ref, 'Medium', difficulty),
                  SizedBox(width: 12.w),
                  _buildDifficultyOption(context, ref, 'Hard', difficulty),
                ],
              ),
              
              SizedBox(height: 24.h),
              _buildLabel('Number of Questions'),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.grey300, width: 1.w),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.grey500),
                      onPressed: () {
                        if (numQuestions > 5) {
                          ref.read(quizQuestionsProvider.notifier).state = numQuestions - 5;
                        }
                      },
                    ),
                    Text(
                      '$numQuestions',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed: () {
                        if (numQuestions < 50) {
                          ref.read(quizQuestionsProvider.notifier).state = numQuestions + 5;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        child: CustomButton(
          text: 'Generate Quiz Now',
          onPressed: () => context.pushNamed(AppRoute.quizReady.name),
          trailingIcon: Icon(Icons.auto_awesome, color: Colors.white, size: 20.w),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.interSemiBold16.copyWith(
        fontSize: 14.sp,
        color: AppColors.onBackground,
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, WidgetRef ref, String title, String currentSelection) {
    final isSelected = title == currentSelection;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(quizDifficultyProvider.notifier).state = title,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
              width: 1.w,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 14.sp,
              color: isSelected ? AppColors.primary : AppColors.grey500,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class InVideoQuizDialog extends ConsumerWidget {
  const InVideoQuizDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InVideoQuizDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(inVideoQuizControllerProvider);
    final activeQuiz = quizState.activeQuiz;

    if (activeQuiz == null) {
      return const SizedBox.shrink();
    }

    final selectedIdx = quizState.selectedOptionIndex;
    final result = quizState.lastResult;
    final isCorrect = result?.isCorrect ?? false;
    final hasSubmitted = result != null;

    return Container(
      margin: EdgeInsets.only(top: 80.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle & close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Coursera Knowledge Check badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Amber light
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 14.w,
                          color: const Color(0xFFE65100),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'KNOWLEDGE CHECK • ${activeQuiz.timestampDisplay}',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 11.sp,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.grey500),
                    onPressed: () {
                      ref
                          .read(inVideoQuizControllerProvider.notifier)
                          .dismissQuiz();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Topic caption
              Text(
                activeQuiz.topic.toUpperCase(),
                style: AppTextStyles.interSemiBold16.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 6.h),

              // Question text
              Text(
                activeQuiz.question,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 15.sp,
                  height: 1.4,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: 16.h),

              // MCQ Options list
              ...List.generate(activeQuiz.options.length, (index) {
                final optionText = activeQuiz.options[index];
                final isSelected = selectedIdx == index;
                final letter = String.fromCharCode(65 + index); // A, B, C, D

                Color borderColor = AppColors.grey300;
                Color bgColor = Colors.white;

                if (hasSubmitted) {
                  if (index == activeQuiz.correctOptionIndex) {
                    borderColor = Colors.green.shade600;
                    bgColor = const Color(0xFFE8F5E9);
                  } else if (isSelected && !isCorrect) {
                    borderColor = Colors.red.shade400;
                    bgColor = const Color(0xFFFFEBEE);
                  }
                } else if (isSelected) {
                  borderColor = AppColors.primary;
                  bgColor = const Color(0xFFEFF6FF);
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: InkWell(
                    onTap: hasSubmitted && isCorrect
                        ? null
                        : () => ref
                              .read(inVideoQuizControllerProvider.notifier)
                              .selectOption(index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12.r,
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.grey200,
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.grey700,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Result Banner (Explanation or Hint)
              if (hasSubmitted) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade400
                          : Colors.orange.shade400,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.info_outline,
                            color: isCorrect
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            size: 18.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            isCorrect
                                ? 'Correct! Well done.'
                                : 'Not quite right',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 13.sp,
                              color: isCorrect
                                  ? Colors.green.shade800
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        isCorrect ? result.explanation : result.hint,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          height: 1.4,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 18.h),

              // Action Buttons
              if (!hasSubmitted) ...[
                CustomButton(
                  text: 'Check Answer',
                  onPressed: () {
                    if (selectedIdx != null) {
                      ref
                          .read(inVideoQuizControllerProvider.notifier)
                          .submitAnswer();
                    }
                  },
                  color: selectedIdx != null
                      ? AppColors.primary
                      : AppColors.grey400,
                ),
              ] else if (isCorrect) ...[
                CustomButton(
                  text: 'Continue Video ▶',
                  onPressed: () {
                    ref
                        .read(inVideoQuizControllerProvider.notifier)
                        .resumeVideo();
                    Navigator.of(context).pop();
                  },
                  color: Colors.green.shade600,
                ),
              ] else ...[
                // Incorrect case: Pedagogical Coursera actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay_10, size: 16),
                        label: Text(
                          'Rewind 15s',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        onPressed: () {
                          ref
                              .read(inVideoQuizControllerProvider.notifier)
                              .rewindAndRewatch();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedIdx != null
                            ? () => ref
                                  .read(inVideoQuizControllerProvider.notifier)
                                  .submitAnswer()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

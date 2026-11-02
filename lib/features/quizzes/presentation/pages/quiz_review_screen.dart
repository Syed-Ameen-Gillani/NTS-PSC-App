import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class QuizReviewScreen extends ConsumerWidget {
  final QuizSubmissionResultModel? result;
  final String? attemptId;

  const QuizReviewScreen({super.key, this.result, this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled) {
      final id = attemptId ?? result?.attemptId;
      if (id == null) return const AppScaffold(body: Center(child: Text('Review unavailable')));
      return ref.watch(quizAttemptResultProvider(id)).when(
        data: (saved) => saved == null
            ? const AppScaffold(body: Center(child: Text('Review unavailable')))
            : _buildReview(context, saved),
        loading: () => const AppScaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const AppScaffold(body: Center(child: Text('Could not load review'))),
      );
    }
    return _buildReview(context, result);
  }

  Widget _buildReview(BuildContext context, QuizSubmissionResultModel? result) {
    final submission = result ??
        QuizSubmissionResultModel(
          quizId: 'q1',
          quizTitle: 'Current Affairs Weekly Challenge 2024',
          score: 3,
          totalQuestions: 4,
          userAnswers: {0: 0, 1: 1, 2: 0, 3: 1},
          questions: [
            QuizQuestionModel(
              id: '1',
              questionText: 'Which country recently joined the SCO as a full member in 2024?',
              options: ['Belarus', 'Armenia', 'Azerbaijan', 'Mongolia'],
              correctOptionIndex: 0,
              explanation: 'Belarus officially became the 10th full member state during the Astana Summit in July 2024.',
            ),
            QuizQuestionModel(
              id: '2',
              questionText: 'What is the primary objective of Pakistan Special Investment Facilitation Council (SIFC)?',
              options: ['Tax collection enforcement', 'Single-window foreign direct investment in key sectors', 'Border security regulation', 'Higher education scholarship distribution'],
              correctOptionIndex: 1,
              explanation: 'SIFC was established to fast-track foreign direct investment in Agriculture, IT, Mines & Minerals, and Energy.',
            ),
            QuizQuestionModel(
              id: '3',
              questionText: 'The Karakoram Highway (N-35) connects Pakistan with which region of China?',
              options: ['Tibet Autonomous Region', 'Xinjiang Uyghur Autonomous Region', 'Sichuan Province', 'Yunnan Province'],
              correctOptionIndex: 1,
              explanation: 'The Karakoram Highway crosses the Khunjerab Pass into the Xinjiang Uyghur Autonomous Region of China.',
            ),
            QuizQuestionModel(
              id: '4',
              questionText: 'Under the 1973 Constitution of Pakistan, which amendment restored parliamentary supremacy from a semi-presidential system?',
              options: ['17th Amendment', '18th Amendment', '19th Amendment', '21st Amendment'],
              correctOptionIndex: 1,
              explanation: 'The 18th Constitutional Amendment in April 2010 eliminated presidential powers under Article 58(2)(b) and devolved powers to provinces.',
            ),
          ],
        );

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Answer Key & Explanations',
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
        child: ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: submission.questions.length,
          separatorBuilder: (context, index) => SizedBox(height: 20.h),
          itemBuilder: (context, qIndex) {
            final question = submission.questions[qIndex];
            final selected = submission.userAnswers[qIndex];
            final isCorrect = selected == question.correctOptionIndex;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isCorrect ? AppColors.success.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.5),
                  width: 1.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(
                        'Question ${qIndex + 1} of ${submission.questions.length}',
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey500,
                        ),
                      )),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isCorrect ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: isCorrect ? AppColors.success : AppColors.error,
                              size: 14.w,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isCorrect ? 'Correct (+1)' : 'Incorrect (0)',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 11.sp,
                                color: isCorrect ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Question prompt
                  Text(
                    question.questionText,
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.onBackground,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Options
                  ...List.generate(question.options.length, (optIndex) {
                    final isUserPick = selected == optIndex;
                    final isAnswer = question.correctOptionIndex == optIndex;

                    Color optBg = Colors.white;
                    Color optBorder = AppColors.grey300;
                    Color textColor = AppColors.onBackground;

                    if (isAnswer) {
                      optBg = AppColors.success.withValues(alpha: 0.12);
                      optBorder = AppColors.success;
                      textColor = const Color(0xFF065F46);
                    } else if (isUserPick && !isCorrect) {
                      optBg = AppColors.error.withValues(alpha: 0.1);
                      optBorder = AppColors.error;
                      textColor = AppColors.error;
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: optBorder, width: 1.w),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + optIndex)}.',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 13.sp,
                              color: textColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              question.options[optIndex],
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 13.sp,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isAnswer)
                            Icon(Icons.check_circle, color: AppColors.success, size: 18.w)
                          else if (isUserPick)
                            Icon(Icons.cancel, color: AppColors.error, size: 18.w),
                        ],
                      ),
                    );
                  }),

                  // Detailed Explanation
                  if (question.explanation.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.w),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 16.w),
                              SizedBox(width: 6.w),
                              Expanded(child: Text(
                                'Exam Preparation Rationale:',
                                style: AppTextStyles.interSemiBold16.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.primary,
                                ),
                              )),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            question.explanation,
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

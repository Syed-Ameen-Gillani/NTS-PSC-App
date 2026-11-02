import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final quizTopicProvider = StateProvider.autoDispose<String>(
  (ref) => 'Current Affairs',
);
final quizDifficultyProvider = StateProvider.autoDispose<String>(
  (ref) => 'Medium',
);
final quizQuestionsProvider = StateProvider.autoDispose<int>((ref) => 4);
final quizDurationProvider = StateProvider.autoDispose<int>((ref) => 10);
final quizGeneratingProvider = StateProvider.autoDispose<bool>((ref) => false);

class TeacherGenerateAiQuizScreen extends ConsumerWidget {
  const TeacherGenerateAiQuizScreen({super.key});

  static const _topics = [
    'Current Affairs',
    'Pakistan Affairs',
    'English Grammar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher =
        ref.watch(authControllerProvider).value?.selectedRole ==
        UserRole.teacher;
    final topic = ref.watch(quizTopicProvider);
    final difficulty = ref.watch(quizDifficultyProvider);
    final questionCount = ref.watch(quizQuestionsProvider);
    final generating = ref.watch(quizGeneratingProvider);
    final duration = ref.watch(quizDurationProvider);
    const maxQuestions = 10;

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(
                isTeacher ? AppRoute.teacherMain.name : AppRoute.main.name,
              );
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          'Generate AI Quiz',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: isTeacher
          ? SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Topic or Subject'),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 1.w,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: topic,
                          isExpanded: true,
                          dropdownColor: AppColors.background,
                          focusColor: AppColors.surface,
                          iconEnabledColor: AppColors.grey600,
                          items: [
                            for (final option in _topics)
                              DropdownMenuItem(
                                value: option,
                                child: Text(
                                  option,
                                  style: AppTextStyles.interRegular16.copyWith(
                                    fontSize: 16.sp,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            ref.read(quizTopicProvider.notifier).state = value;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _label('Difficulty Level'),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        for (final option in const [
                          'Easy',
                          'Medium',
                          'Hard',
                        ]) ...[
                          if (option != 'Easy') SizedBox(width: 12.w),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  ref
                                          .read(quizDifficultyProvider.notifier)
                                          .state =
                                      option,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: option == difficulty
                                    ? AppColors.surface
                                    : AppColors.background,
                                side: BorderSide(
                                  color: option == difficulty
                                      ? AppColors.primary
                                      : AppColors.grey300,
                                  width: 1.w,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: Text(
                                option,
                                style: AppTextStyles.interMedium16.copyWith(
                                  fontSize: 14.sp,
                                  color: option == difficulty
                                      ? AppColors.primary
                                      : AppColors.grey500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _label('Quiz Timer'),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 1.w,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: duration,
                          isExpanded: true,
                          dropdownColor: AppColors.background,
                          focusColor: AppColors.surface,
                          iconEnabledColor: AppColors.grey600,
                          items: [5, 10, 15, 20, 30]
                              .map(
                                (minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text('$minutes minutes'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(quizDurationProvider.notifier).state =
                                  value;
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _label('Number of Questions'),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Fewer questions',
                            icon: const Icon(Icons.remove),
                            onPressed: questionCount > 1
                                ? () => ref
                                      .read(quizQuestionsProvider.notifier)
                                      .state--
                                : null,
                          ),
                          Text(
                            '$questionCount',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 18.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                          IconButton(
                            tooltip: 'More questions',
                            icon: const Icon(Icons.add),
                            onPressed: questionCount < maxQuestions
                                ? () => ref
                                      .read(quizQuestionsProvider.notifier)
                                      .state++
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Text(
                'Teacher access only',
                style: AppTextStyles.interMedium16.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ),
      bottomNavigationBar: isTeacher
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
                child: CustomButton(
                  text: generating ? 'Generating...' : 'Generate Quiz',
                  color: AppColors.primary,
                  height: 56.h,
                  borderRadius: 16.r,
                  onPressed: generating ? () {} : () => _generate(context, ref),
                  trailingIcon: Icon(
                    Icons.auto_awesome,
                    color: AppColors.onPrimary,
                    size: 18.w,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _label(String label) {
    return Text(
      label,
      style: AppTextStyles.interSemiBold16.copyWith(
        fontSize: 14.sp,
        color: AppColors.onBackground,
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    ref.read(quizGeneratingProvider.notifier).state = true;
    try {
      final quiz = await ref
          .read(teacherControllerProvider.notifier)
          .generateAiQuiz(
            topic: ref.read(quizTopicProvider),
            difficulty: ref.read(quizDifficultyProvider),
            questionCount: ref.read(quizQuestionsProvider),
            durationMinutes: ref.read(quizDurationProvider),
          );
      if (!context.mounted) return;
      CustomToast.showSuccess(
        context,
        message: '${quiz.title} added to Assessment Studio',
      );
      context.pop();
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(context, message: 'Could not generate quiz');
      }
    } finally {
      if (context.mounted) {
        ref.read(quizGeneratingProvider.notifier).state = false;
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quiz_session_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quiz_lifecycle.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class ActiveQuizScreen extends ConsumerWidget {
  const ActiveQuizScreen({super.key, this.quiz});
  final QuizModel? quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = this.quiz;
    if (quiz == null || quiz.questions.isEmpty) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Quiz unavailable')),
      );
    }
    final provider = quizSessionProvider(quiz);
    ref.watch(quizLifecycleProvider(quiz));
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider, (previous, next) {
      final result = next.result;
      if (result == null || previous?.result != null) return;
      ref.invalidate(quizzesControllerProvider);
      ref.invalidate(myLearningControllerProvider);
      ref.invalidate(homeControllerProvider);
      ref.invalidate(publishedCatalogProvider);
      ref.invalidate(featuredCatalogProvider);
      context.pushReplacementNamed(
        AppRoute.quizCompleted.name,
        queryParameters: result.attemptId == null
            ? const {}
            : {'attemptId': result.attemptId!},
        extra: result,
      );
    });
    final questions = controller.questions;
    final question = questions[state.index];
    final minutes = (state.seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.seconds % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: state.exitAllowed,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !controller.beginExit()) return;
        final leave =
            await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                title: const Text('Leave this quiz?'),
                content: const Text(
                  'You can resume your saved answers. The timer will keep running.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialog).pop(false),
                    child: const Text('Keep working'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialog).pop(true),
                    child: const Text('Leave quiz'),
                  ),
                ],
              ),
            ) ??
            false;
        await controller.finishExit(leave);
        await WidgetsBinding.instance.endOfFrame;
        if (!context.mounted || !leave) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoute.main.name);
        }
      },
      child: AppScaffold(
        appBar: AppBar(
          title: Text('Question ${state.index + 1} of ${questions.length}'),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Text(
                  '$minutes:$seconds',
                  style: AppTextStyles.interMedium16.copyWith(
                    color: state.seconds < 60 ? AppColors.error : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : AbsorbPointer(
                absorbing: state.busy,
                child: ListView(
                  padding: EdgeInsets.all(24.w),
                  children: [
                    if (state.error != null) ...[
                      Text(
                        state.error!,
                        style: AppTextStyles.interRegular14.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      TextButton(
                        onPressed: controller.load,
                        child: const Text('Reload saved attempt'),
                      ),
                      SizedBox(height: 12.h),
                    ],
                    Text(
                      quiz.category,
                      style: AppTextStyles.interMedium16.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      question.questionText,
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ...List.generate(question.options.length, (index) {
                      final selected = state.answers[state.index] == index;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: .08)
                              : Theme.of(context).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 6.h,
                            ),
                            onTap: state.seconds > 0
                                ? () => controller.select(index)
                                : null,
                            leading: Text(
                              String.fromCharCode(65 + index),
                              style: AppTextStyles.interSemiBold16,
                            ),
                            title: Text(
                              question.options[index],
                              style: AppTextStyles.interRegular14,
                            ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey500,
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 16.h),
                    Text(
                      'Pass score: ${quiz.passingScore}%. You can retry; your best passing result counts.',
                      style: AppTextStyles.interRegular14,
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: state.busy
                ? const Center(
                    heightFactor: 1,
                    child: CircularProgressIndicator(),
                  )
                : Row(
                    children: [
                      if (state.index > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.loading
                                ? null
                                : () => controller.move(state.index - 1),
                            child: const Text('Previous'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: state.loading
                              ? null
                              : (state.index == questions.length - 1 ||
                                    state.seconds == 0)
                              ? controller.submit
                              : () => controller.move(state.index + 1),
                          child: Text(
                            state.index == questions.length - 1 ||
                                    state.seconds == 0
                                ? 'Submit quiz'
                                : 'Next question',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

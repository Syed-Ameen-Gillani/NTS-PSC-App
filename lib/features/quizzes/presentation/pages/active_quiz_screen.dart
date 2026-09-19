import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class ActiveQuizScreen extends ConsumerStatefulWidget {
  final QuizModel? quiz;

  const ActiveQuizScreen({super.key, this.quiz});

  @override
  ConsumerState<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends ConsumerState<ActiveQuizScreen> {
  late QuizModel _quiz;
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  int _secondsRemaining = 600; // 10 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz ??
        QuizModel(
          id: 'q1',
          title: 'Current Affairs Weekly Challenge 2024',
          category: 'Current Affairs',
          totalQuestions: 4,
          durationMinutes: 10,
          questions: [
            QuizQuestionModel(
              id: 'q1_1',
              questionText: 'Which country recently joined the SCO (Shanghai Cooperation Organisation) as a full member in 2024?',
              options: ['Belarus', 'Armenia', 'Azerbaijan', 'Mongolia'],
              correctOptionIndex: 0,
              explanation: 'Belarus officially became the 10th full member state during the Astana Summit in July 2024.',
            ),
            QuizQuestionModel(
              id: 'q1_2',
              questionText: 'What is the primary objective of Pakistan Special Investment Facilitation Council (SIFC)?',
              options: ['Tax collection enforcement', 'Single-window foreign direct investment in key sectors', 'Border security regulation', 'Higher education scholarship distribution'],
              correctOptionIndex: 1,
              explanation: 'SIFC was established to fast-track foreign direct investment in Agriculture, IT, Mines & Minerals, and Energy.',
            ),
            QuizQuestionModel(
              id: 'q1_3',
              questionText: 'The Karakoram Highway (N-35) connects Pakistan with which region of China?',
              options: ['Tibet Autonomous Region', 'Xinjiang Uyghur Autonomous Region', 'Sichuan Province', 'Yunnan Province'],
              correctOptionIndex: 1,
              explanation: 'The Karakoram Highway crosses the Khunjerab Pass into the Xinjiang Uyghur Autonomous Region of China.',
            ),
            QuizQuestionModel(
              id: 'q1_4',
              questionText: 'Under the 1973 Constitution of Pakistan, which amendment restored parliamentary supremacy from a semi-presidential system?',
              options: ['17th Amendment', '18th Amendment', '19th Amendment', '21st Amendment'],
              correctOptionIndex: 1,
              explanation: 'The 18th Constitutional Amendment removed presidential power under Article 58(2)(b) and devolved powers to provinces.',
            ),
          ],
        );

    _secondsRemaining = _quiz.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    final repo = ref.read(quizRepositoryProvider);
    final result = await repo.submitQuiz(
      quizId: _quiz.id,
      userAnswers: _userAnswers,
    );

    if (mounted) {
      context.pushReplacementNamed(
        AppRoute.quizCompleted.name,
        extra: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _quiz.questions;
    final hasQuestions = questions.isNotEmpty;
    final currentQ = hasQuestions ? questions[_currentQuestionIndex] : null;
    final totalQ = questions.length;
    final isLastQuestion = _currentQuestionIndex == totalQ - 1;
    final selectedOption = _userAnswers[_currentQuestionIndex];

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
          'Question ${_currentQuestionIndex + 1} of $totalQ',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 16.sp,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(Icons.access_time, color: _secondsRemaining < 60 ? AppColors.error : AppColors.grey900, size: 18.w),
              SizedBox(width: 4.w),
              Text(
                _formatTime(_secondsRemaining),
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 13.sp,
                  color: _secondsRemaining < 60 ? AppColors.error : AppColors.grey900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 20.w),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.h),
          child: Row(
            children: [
              Expanded(
                flex: _currentQuestionIndex + 1,
                child: Container(color: AppColors.primary, height: 4.h),
              ),
              Expanded(
                flex: totalQ - (_currentQuestionIndex + 1),
                child: Container(color: AppColors.grey300, height: 4.h),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: currentQ == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _quiz.category.toUpperCase(),
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: AppColors.grey300, width: 1.w),
                          ),
                          child: Text(
                            'Timed Exam',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      currentQ.questionText,
                      style: AppTextStyles.interBold30.copyWith(
                        fontSize: 20.sp,
                        color: AppColors.grey900,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    ...List.generate(currentQ.options.length, (index) {
                      final isSelected = selectedOption == index;
                      final letter = String.fromCharCode(65 + index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userAnswers[_currentQuestionIndex] = index;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 14.h),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                              width: isSelected ? 1.5.w : 1.w,
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
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  currentQ.options[index],
                                  style: AppTextStyles.interMedium16.copyWith(
                                    fontSize: 14.sp,
                                    color: AppColors.grey900,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: AppColors.primary, size: 22.w)
                              else
                                Container(
                                  width: 22.w,
                                  height: 22.w,
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
        padding: EdgeInsets.all(20.w).copyWith(
          bottom: 16.h + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            if (_currentQuestionIndex > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentQuestionIndex--);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.grey300, width: 1.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    'Previous',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.grey700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              flex: 2,
              child: CustomButton(
                text: isLastQuestion ? 'Submit Exam' : 'Next Question',
                color: AppColors.primary,
                trailingIcon: Icon(
                  isLastQuestion ? Icons.check : Icons.arrow_forward,
                  color: Colors.white,
                  size: 18.w,
                ),
                onPressed: () {
                  if (isLastQuestion) {
                    _submitQuiz();
                  } else {
                    setState(() => _currentQuestionIndex++);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

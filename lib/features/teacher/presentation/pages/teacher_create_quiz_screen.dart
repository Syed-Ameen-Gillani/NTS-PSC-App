import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherCreateQuizScreen extends ConsumerStatefulWidget {
  const TeacherCreateQuizScreen({super.key});

  @override
  ConsumerState<TeacherCreateQuizScreen> createState() => _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends ConsumerState<TeacherCreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '15');
  final _questionPromptController = TextEditingController();
  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  final _explanationController = TextEditingController();

  String _selectedCategory = 'Pakistan Affairs';
  final List<String> _categories = [
    'Pakistan Affairs',
    'Current Affairs',
    'Everyday Science',
    'English Grammar',
    'Islamic Studies',
    'Customs & Tax Laws',
  ];

  int _correctOptionIndex = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _questionPromptController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 12.h),
      child: Text(
        text,
        style: AppTextStyles.interSemiBold16.copyWith(
          color: AppColors.onBackground,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Create Mock Quiz',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Parameters',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Define the title, subject category, and time duration for candidate test-takers.',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),

                _buildFieldLabel('Quiz / Test Title'),
                CustomTextFormField(
                  controller: _titleController,
                  hintText: 'e.g. Constitutional Law & Reforms Weekly Mock',
                  prefixIcon: Icons.quiz_outlined,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                ),

                _buildFieldLabel('Category / Exam Subject'),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),

                _buildFieldLabel('Test Duration (Minutes)'),
                CustomTextFormField(
                  controller: _durationController,
                  hintText: 'e.g. 15',
                  prefixIcon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter duration' : null,
                ),

                SizedBox(height: 24.h),
                Divider(color: AppColors.grey300, thickness: 1.h),
                SizedBox(height: 16.h),

                // Question Editor
                Text(
                  'Question 1 (MCQ Builder)',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Enter the question prompt, 4 choices, select the correct answer, and provide rationale.',
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),

                _buildFieldLabel('Question Prompt'),
                CustomTextFormField(
                  controller: _questionPromptController,
                  hintText: 'e.g. What year was the Indus Waters Treaty signed?',
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter question text' : null,
                ),

                _buildFieldLabel('Option A'),
                Row(
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _correctOptionIndex,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _correctOptionIndex = val ?? 0),
                    ),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _optAController,
                        hintText: 'e.g. 1958',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter option A' : null,
                      ),
                    ),
                  ],
                ),

                _buildFieldLabel('Option B'),
                Row(
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _correctOptionIndex,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _correctOptionIndex = val ?? 1),
                    ),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _optBController,
                        hintText: 'e.g. 1960',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter option B' : null,
                      ),
                    ),
                  ],
                ),

                _buildFieldLabel('Option C'),
                Row(
                  children: [
                    Radio<int>(
                      value: 2,
                      groupValue: _correctOptionIndex,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _correctOptionIndex = val ?? 2),
                    ),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _optCController,
                        hintText: 'e.g. 1965',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter option C' : null,
                      ),
                    ),
                  ],
                ),

                _buildFieldLabel('Option D'),
                Row(
                  children: [
                    Radio<int>(
                      value: 3,
                      groupValue: _correctOptionIndex,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _correctOptionIndex = val ?? 3),
                    ),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _optDController,
                        hintText: 'e.g. 1971',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter option D' : null,
                      ),
                    ),
                  ],
                ),

                _buildFieldLabel('Exam Preparation Explanation'),
                CustomTextFormField(
                  controller: _explanationController,
                  hintText: 'Explain why the marked answer is correct so candidates learn from their test review...',
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an explanation' : null,
                ),

                SizedBox(height: 36.h),

                CustomButton(
                  text: _isSaving ? 'Creating Quiz...' : 'Publish Mock Quiz',
                  color: AppColors.primary,
                  onPressed: _isSaving
                      ? () {}
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _isSaving = true);
                            final duration = int.tryParse(_durationController.text.trim()) ?? 15;

                            final newQuiz = QuizModel(
                              id: 'q_${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text.trim(),
                              category: _selectedCategory,
                              totalQuestions: 1,
                              durationMinutes: duration,
                              passingScore: 60,
                              questions: [
                                QuizQuestionModel(
                                  id: 'q1',
                                  questionText: _questionPromptController.text.trim(),
                                  options: [
                                    _optAController.text.trim(),
                                    _optBController.text.trim(),
                                    _optCController.text.trim(),
                                    _optDController.text.trim(),
                                  ],
                                  correctOptionIndex: _correctOptionIndex,
                                  explanation: _explanationController.text.trim(),
                                ),
                              ],
                            );

                            await ref.read(teacherControllerProvider.notifier).addQuiz(newQuiz);
                            setState(() => _isSaving = false);

                            if (context.mounted) {
                              CustomToast.showSuccess(
                                context,
                                message: 'Quiz "${newQuiz.title}" created successfully!',
                              );
                              context.pop();
                            }
                          }
                        },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

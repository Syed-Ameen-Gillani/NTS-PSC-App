import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/quiz_draft_editor_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_question_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherCreateQuizScreen extends ConsumerStatefulWidget {
  const TeacherCreateQuizScreen({super.key, this.quiz, this.creationRequest});

  final QuizModel? quiz;
  final AssessmentCreationRequest? creationRequest;

  @override
  ConsumerState<TeacherCreateQuizScreen> createState() =>
      _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState
    extends ConsumerState<TeacherCreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '15');
  static const _categories = [
    'Pakistan Affairs',
    'Current Affairs',
    'Everyday Science',
    'English Grammar',
    'Islamic Studies',
    'Customs & Tax Laws',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.quiz case final quiz?) {
      _title.text = quiz.title;
      _duration.text = '${quiz.durationMinutes}';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _openQuestion({int? index}) async {
    final questions = ref.read(quizDraftEditorProvider(widget.quiz)).questions;
    final result = await context.pushNamed<QuizQuestionEditorResult>(
      AppRoute.teacherQuizQuestion.name,
      extra: QuizQuestionEditorArgs(
        number: (index ?? questions.length) + 1,
        question: index == null ? null : questions[index],
      ),
    );
    if (result != null && mounted) {
      ref
          .read(quizDraftEditorProvider(widget.quiz).notifier)
          .saveQuestion(result.question, index: index);
      if (result.addNext) await _openQuestion();
    }
  }

  Future<void> _deleteQuestion(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This question will be removed from the draft.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref
          .read(quizDraftEditorProvider(widget.quiz).notifier)
          .removeQuestion(index);
    }
  }

  Future<void> _save() async {
    final editor = ref.read(quizDraftEditorProvider(widget.quiz));
    if (editor.isSaving || !_formKey.currentState!.validate()) return;
    if (editor.questions.isEmpty) {
      CustomToast.showError(context, message: 'Add at least one question.');
      return;
    }
    ref.read(quizDraftEditorProvider(widget.quiz).notifier).setSaving(true);
    final quiz = QuizModel(
      id: widget.quiz?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      category: editor.category,
      totalQuestions: editor.questions.length,
      durationMinutes: int.parse(_duration.text.trim()),
      passingScore: widget.quiz?.passingScore ?? 60,
      difficulty: widget.quiz?.difficulty ?? 'Medium',
      isAiGenerated: widget.quiz?.isAiGenerated ?? false,
      isPublished: false,
      questions: editor.questions,
    );
    try {
      if (widget.quiz == null) {
        await ref.read(teacherControllerProvider.notifier).addQuiz(quiz);
        final targetScope = widget.creationRequest?.targetScope;
        if (targetScope != null) {
          await ref
              .read(curriculumActionsProvider(targetScope).notifier)
              .link(
                CurriculumAssessment(
                  id: quiz.id,
                  assessmentId: quiz.id,
                  title: quiz.title,
                  kind: 'quiz',
                  status: 'draft',
                ),
              );
        }
      } else {
        await ref
            .read(teacherControllerProvider.notifier)
            .updateDraftQuiz(quiz);
      }
      if (mounted) {
        CustomToast.showSuccess(
          context,
          message: widget.creationRequest == null
              ? 'Quiz draft saved.'
              : 'Quiz published and linked to ${widget.creationRequest!.targetScope.targetLabel.toLowerCase()}.',
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        if (error is StateError &&
            error.message.toString().startsWith('Quiz saved,')) {
          ref.invalidate(teacherControllerProvider);
          CustomToast.showSuccess(
            context,
            message: 'Quiz saved. Refresh to view it.',
          );
          context.pop();
        } else {
          CustomToast.showError(context, message: 'Could not save quiz.');
        }
      }
    } finally {
      if (mounted) {
        ref
            .read(quizDraftEditorProvider(widget.quiz).notifier)
            .setSaving(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz?.isPublished ?? false) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Published Quiz')),
        body: const Center(child: Text('Published quizzes cannot be edited')),
      );
    }
    final editor = ref.watch(quizDraftEditorProvider(widget.quiz));
    final colors = Theme.of(context).colorScheme;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final categoryBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16.r),
      borderSide: BorderSide(color: AppColors.grey300, width: 1.w),
    );
    final categories = [
      ..._categories,
      if (!_categories.contains(editor.category)) editor.category,
    ];
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: editor.questions.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: 'Add next question',
              onPressed: editor.isSaving ? null : _openQuestion,
              child: Icon(Icons.add, size: 24.w),
            ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_ios_new, size: 20.w),
          onPressed: editor.isSaving ? null : () => context.pop(),
        ),
        title: Text(
          widget.quiz == null
              ? widget.creationRequest == null
                    ? 'Create Quiz'
                    : 'Create & Link Quiz'
              : 'Edit Draft Quiz',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
        ),
        actions: [
          if (editor.questions.isNotEmpty)
            TextButton(
              onPressed: editor.isSaving ? null : _save,
              child: Text(editor.isSaving ? 'Saving...' : 'Save'),
            ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: editor.isSaving,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                22.h,
                20.w,
                editor.questions.isEmpty ? 28.h : 96.h,
              ),
              children: [
                _label(context, 'Title'),
                CustomTextFormField(
                  controller: _title,
                  hintText: 'e.g. Constitutional Law Weekly Mock',
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a quiz title'
                      : null,
                ),
                SizedBox(height: 16.h),
                _label(context, 'Category'),
                DropdownButtonFormField<String>(
                  initialValue: editor.category,
                  isExpanded: true,
                  dropdownColor: scaffoldColor,
                  borderRadius: BorderRadius.circular(12.r),
                  menuMaxHeight: 320.h,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.grey600,
                    size: 22.w,
                  ),
                  style: AppTextStyles.interRegular16.copyWith(
                    fontSize: 16.sp,
                    color: colors.onSurface,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scaffoldColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    enabledBorder: categoryBorder,
                    border: categoryBorder,
                    focusedBorder: categoryBorder.copyWith(
                      borderSide: BorderSide(color: colors.primary, width: 1.w),
                    ),
                    errorBorder: categoryBorder.copyWith(
                      borderSide: BorderSide(color: colors.error, width: 1.w),
                    ),
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.interRegular16.copyWith(
                                  fontSize: 16.sp,
                                  color: category == editor.category
                                      ? colors.primary
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                            if (category == editor.category)
                              Icon(
                                Icons.check,
                                size: 18.w,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ),
                  ],
                  selectedItemBuilder: (context) => [
                    for (final category in categories)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(quizDraftEditorProvider(widget.quiz).notifier)
                          .setCategory(value);
                    }
                  },
                ),
                SizedBox(height: 16.h),
                _label(context, 'Duration (minutes)'),
                CustomTextFormField(
                  controller: _duration,
                  hintText: '15',
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    return minutes == null || minutes < 1 || minutes > 180
                        ? 'Enter 1 to 180 minutes'
                        : null;
                  },
                ),
                SizedBox(height: 30.h),
                if (editor.questions.isEmpty)
                  CustomButton(
                    text: 'Add questions',
                    color: AppColors.primary,
                    onPressed: _openQuestion,
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text('Questions', style: _heading(context)),
                      ),
                      Text(
                        '${editor.questions.length}',
                        style: AppTextStyles.interMedium16.copyWith(
                          fontSize: 13.sp,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  for (
                    var index = 0;
                    index < editor.questions.length;
                    index++
                  ) ...[
                    if (index > 0) SizedBox(height: 8.h),
                    _QuestionRow(
                      number: index + 1,
                      question: editor.questions[index],
                      onEdit: () => _openQuestion(index: index),
                      onDelete: () => _deleteQuestion(index),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String value) => Padding(
    padding: EdgeInsets.only(bottom: 7.h),
    child: Text(
      value,
      style: AppTextStyles.interSemiBold16.copyWith(
        fontSize: 13.sp,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

  TextStyle _heading(BuildContext context) =>
      AppTextStyles.interSemiBold16.copyWith(
        fontSize: 18.sp,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.number,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final int number;
  final QuizQuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? DarkAppColors.surfaceVariant
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ExpansionTile(
        key: ValueKey(question.id),
        tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
        childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Text(
              '$number.',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 13.sp,
                color: colors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                question.questionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 13.sp,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        children: [
          Divider(height: 1.h, color: colors.outlineVariant),
          SizedBox(height: 8.h),
          for (var index = 0; index < question.options.length; index++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 28.w,
                    child: Text(
                      '${String.fromCharCode(65 + index)}.',
                      style: AppTextStyles.interMedium16.copyWith(
                        fontSize: 13.sp,
                        color: index == question.correctOptionIndex
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: AppTextStyles.interRegular14.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (index == question.correctOptionIndex)
                    Icon(Icons.check, size: 18.w, color: colors.primary),
                ],
              ),
            ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 18.w),
                label: const Text('Edit'),
              ),
              IconButton(
                tooltip: 'Delete question $number',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 20.w),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

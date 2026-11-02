import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class QuizQuestionEditorArgs {
  const QuizQuestionEditorArgs({required this.number, this.question});

  final int number;
  final QuizQuestionModel? question;
}

class QuizQuestionEditorResult {
  const QuizQuestionEditorResult(this.question, {this.addNext = false});

  final QuizQuestionModel question;
  final bool addNext;
}

class TeacherQuizQuestionScreen extends StatefulWidget {
  const TeacherQuizQuestionScreen({super.key, required this.args});

  final QuizQuestionEditorArgs args;

  @override
  State<TeacherQuizQuestionScreen> createState() =>
      _TeacherQuizQuestionScreenState();
}

class _TeacherQuizQuestionScreenState extends State<TeacherQuizQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prompt = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());
  final _optionFocus = List.generate(4, (_) => FocusNode());
  final _explanationFocus = FocusNode();
  final _explanation = TextEditingController();
  final _correct = ValueNotifier<int?>(null);
  final _canPop = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final question = widget.args.question;
    if (question == null) return;
    _prompt.text = question.questionText;
    for (var i = 0; i < _options.length; i++) {
      _options[i].text = question.options.elementAtOrNull(i) ?? '';
    }
    _explanation.text = question.explanation;
    _correct.value = question.correctOptionIndex;
  }

  @override
  void dispose() {
    _prompt.dispose();
    for (final option in _options) {
      option.dispose();
    }
    for (final focus in _optionFocus) {
      focus.dispose();
    }
    _explanation.dispose();
    _explanationFocus.dispose();
    _correct.dispose();
    _canPop.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final previous = widget.args.question;
    return _prompt.text != (previous?.questionText ?? '') ||
        _explanation.text != (previous?.explanation ?? '') ||
        _correct.value != previous?.correctOptionIndex ||
        [
          for (var i = 0; i < _options.length; i++)
            _options[i].text != (previous?.options.elementAtOrNull(i) ?? ''),
        ].contains(true);
  }

  bool get _ready =>
      _prompt.text.trim().isNotEmpty &&
      _options.every((option) => option.text.trim().isNotEmpty) &&
      _correct.value != null &&
      _explanation.text.trim().isNotEmpty;

  void _pop([QuizQuestionEditorResult? result]) {
    _canPop.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop(result);
    });
  }

  Future<void> _leave() async {
    if (!_hasChanges) {
      _pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard question changes?'),
        content: const Text(
          'Your unsaved edits to this question will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _pop();
  }

  void _save({bool addNext = false}) {
    if (_canPop.value) return;
    if (!_formKey.currentState!.validate()) return;
    final correct = _correct.value;
    if (correct == null) {
      CustomToast.showError(context, message: 'Select the correct answer.');
      return;
    }
    _pop(
      QuizQuestionEditorResult(
        QuizQuestionModel(
          id:
              widget.args.question?.id ??
              'q_${DateTime.now().microsecondsSinceEpoch}',
          questionText: _prompt.text.trim(),
          options: [for (final option in _options) option.text.trim()],
          correctOptionIndex: correct,
          explanation: _explanation.text.trim(),
        ),
        addNext: addNext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: _canPop,
      builder: (context, canPop, _) => PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: AppScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              tooltip: 'Back',
              icon: Icon(Icons.arrow_back_ios_new, size: 20.w),
              onPressed: _leave,
            ),
            title: Text(
              widget.args.question == null ? 'Add Question' : 'Edit Question',
              style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
            ),
            actions: [
              TextButton(onPressed: () => _save(), child: const Text('Done')),
              SizedBox(width: 8.w),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1.h),
              child: Container(color: AppColors.grey300, height: 1.h),
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                children: [
                  Text(
                    'Question ${widget.args.number}',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 18.sp,
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  CustomTextFormField(
                    controller: _prompt,
                    hintText: 'Write the question',
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a question'
                        : null,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Answer options',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 16.sp,
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Select the correct answer.',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  ValueListenableBuilder<int?>(
                    valueListenable: _correct,
                    builder: (context, selected, _) => RadioGroup<int>(
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) _correct.value = value;
                      },
                      child: Column(
                        children: [
                          for (var i = 0; i < _options.length; i++) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Radio<int>(
                                  value: i,
                                  fillColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.selected)
                                        ? AppColors.success
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: _options[i],
                                    focusNode: _optionFocus[i],
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        (i < _optionFocus.length - 1
                                                ? _optionFocus[i + 1]
                                                : _explanationFocus)
                                            .requestFocus(),
                                    fillColor: selected == i
                                        ? AppColors.success.withValues(
                                            alpha: 0.12,
                                          )
                                        : null,
                                    borderColor: selected == i
                                        ? AppColors.success
                                        : null,
                                    focusedBorderColor: selected == i
                                        ? AppColors.success
                                        : null,
                                    hintText:
                                        'Option ${String.fromCharCode(65 + i)}',
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter option ${String.fromCharCode(65 + i)}'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _label(context, 'Explanation'),
                  CustomTextFormField(
                    controller: _explanation,
                    focusNode: _explanationFocus,
                    hintText: 'Explain why this answer is correct',
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an explanation'
                        : null,
                  ),
                  SizedBox(height: 24.h),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _prompt,
                      ..._options,
                      _correct,
                      _explanation,
                    ]),
                    builder: (context, _) => FilledButton(
                      onPressed: _ready ? () => _save(addNext: true) : null,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(52.h),
                      ),
                      child: const Text('Next question'),
                    ),
                  ),
                ],
              ),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/lesson_authoring_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TeacherCreateLessonScreen extends ConsumerStatefulWidget {
  const TeacherCreateLessonScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  final String courseId;
  final String moduleId;

  @override
  ConsumerState<TeacherCreateLessonScreen> createState() =>
      _TeacherCreateLessonScreenState();
}

class _TeacherCreateLessonScreenState
    extends ConsumerState<TeacherCreateLessonScreen> {
  static final _durationFormat = RegExp(
    r'^(?:(\d+)\s*h(?:\s+(\d+)\s*m?)?|(\d+)\s*m?)$',
    caseSensitive: false,
  );

  final _id = const Uuid().v4();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _duration = TextEditingController(text: '20m');
  final _url = TextEditingController();

  LessonAuthoringKey get _draft =>
      (draftId: _id, courseId: widget.courseId, moduleId: widget.moduleId);

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      final lesson = await ref
          .read(lessonAuthoringProvider(_draft).notifier)
          .save(
            LessonModel(
              id: _id,
              title: _title.text.trim(),
              durationMinutes: _durationInMinutes(_duration.text)!,
              videoUrl: _url.text.trim(),
            ),
            null,
          );
      if (!mounted) return;
      CustomToast.showSuccess(context, message: 'Lesson created successfully.');
      context.pop(lesson);
    } catch (error) {
      if (!mounted) return;
      final message =
          error is StateError &&
              error.message.toString().contains('up to 10 lessons')
          ? error.message.toString()
          : error is PostgrestException &&
                error.message.contains('up to 10 lessons')
          ? 'A module can have up to 10 lessons.'
          : error is PostgrestException &&
                error.message.contains('Teacher access required')
          ? 'Your session expired. Sign in again.'
          : 'Could not save lesson. Please retry.';
      CustomToast.showError(context, message: message);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonAuthoringProvider(_draft));
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !state.busy,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: AbsorbPointer(
            absorbing: state.busy,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20.w,
                4.h,
                20.w,
                MediaQuery.viewInsetsOf(context).bottom + 20.h,
              ),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 40.h,
                      child: Center(
                        child: Text(
                          'Create lesson',
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 20.sp,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    _fieldLabel('Lesson title', required: true),
                    CustomTextFormField(
                      controller: _title,
                      readOnly: state.busy,
                      hintText: 'e.g. Introduction to Pakistan Affairs',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a lesson title'
                          : null,
                    ),
                    SizedBox(height: 18.h),
                    _fieldLabel('Estimated duration', required: true),
                    CustomTextFormField(
                      controller: _duration,
                      readOnly: state.busy,
                      hintText: 'e.g. 45m, 1h, or 1h 30m',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final duration = _durationInMinutes(value ?? '');
                        if (duration == null) {
                          return 'Use 45m, 1h, or 1h 30m';
                        }
                        if (duration > 600) {
                          return 'Enter a duration under 10 hours';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 18.h),
                    _fieldLabel('Streaming URL (optional)'),
                    CustomTextFormField(
                      controller: _url,
                      readOnly: state.busy,
                      hintText: 'https://...',
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final uri = Uri.tryParse(value.trim());
                        return uri == null ||
                                uri.scheme != 'https' ||
                                uri.host.isEmpty
                            ? 'Enter a valid HTTPS video URL'
                            : null;
                      },
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Upload video, handouts, and assessments in Lesson Studio.',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    FilledButton(
                      onPressed: state.busy ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: state.busy
                          ? SizedBox.square(
                              dimension: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create lesson',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _durationInMinutes(String value) {
    final match = _durationFormat.firstMatch(value.trim());
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? match.group(3) ?? '') ?? 0;
    final total = (hours * 60) + minutes;
    return total > 0 ? total : null;
  }

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: AppTextStyles.interMedium16.copyWith(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    ),
  );
}

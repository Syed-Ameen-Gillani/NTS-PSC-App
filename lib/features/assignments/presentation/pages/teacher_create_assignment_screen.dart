import 'package:file_picker/file_picker.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/domain/assignment_link.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherCreateAssignmentScreen extends ConsumerStatefulWidget {
  final CourseModel? course;
  final AssignmentModel? assignment;
  final AssessmentCreationRequest? creationRequest;

  const TeacherCreateAssignmentScreen({
    super.key,
    this.course,
    this.assignment,
    this.creationRequest,
  });

  @override
  ConsumerState<TeacherCreateAssignmentScreen> createState() =>
      _TeacherCreateAssignmentScreenState();
}

class _TeacherCreateAssignmentScreenState
    extends ConsumerState<TeacherCreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  final _externalUrl = TextEditingController();
  final _dueDateText = TextEditingController();
  final _attachments = ValueNotifier<List<AssignmentAttachmentModel>>([]);
  DateTime? _dueAt;
  String? _selectedCourseId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    if (assignment != null) {
      _title.text = assignment.title;
      _instructions.text = assignment.instructions;
      _externalUrl.text = assignment.externalUrl ?? '';
      _dueAt = assignment.dueAt;
      _attachments.value = assignment.attachments;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dueAt != null && _dueDateText.text.isEmpty) {
      _dueDateText.text = MaterialLocalizations.of(
        context,
      ).formatMediumDate(_dueAt!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    _externalUrl.dispose();
    _dueDateText.dispose();
    _attachments.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (selected == null || !mounted) return;
    _dueAt = DateTime(selected.year, selected.month, selected.day, 23, 59);
    _dueDateText.text = MaterialLocalizations.of(
      context,
    ).formatMediumDate(selected);
  }

  Future<void> _pickDocs() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'mp4',
          'mov',
        ],
      );
      if (files.isEmpty || !mounted) return;
      final updated = [..._attachments.value];
      for (final file in files) {
        if (updated.length >= 5) {
          CustomToast.showError(context, message: 'Add up to five files.');
          break;
        }
        final size = file.lengthSync() ?? await file.length() ?? 0;
        if (!mounted) return;
        if (size < 1 || size > 25 * 1024 * 1024) {
          CustomToast.showError(
            context,
            message: 'Choose files up to 25 MB each.',
          );
          continue;
        }
        final bytes = AppConfig.isSupabaseEnabled
            ? await file.readAsBytes()
            : null;
        if (!mounted) return;
        updated.add(
          AssignmentAttachmentModel(
            name: file.name,
            sizeBytes: size,
            path: file.path,
            bytes: bytes,
          ),
        );
      }
      _attachments.value = updated;
    } catch (_) {
      if (mounted) {
        CustomToast.showError(
          context,
          message: 'Could not attach files. Try again.',
        );
      }
    }
  }

  Future<void> _create() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final courses = ref.read(teacherControllerProvider).value?.courses ?? [];
    final selectedCourseId =
        _selectedCourseId ??
        widget.course?.id ??
        widget.creationRequest?.targetScope.courseId;
    final course =
        widget.course ??
        courses.where((item) => item.id == selectedCourseId).firstOrNull;
    final assignment = widget.assignment;
    if ((course == null && assignment == null) || _dueAt == null) {
      if (course == null && mounted) {
        CustomToast.showError(context, message: 'Choose a course first.');
      }
      return;
    }
    setState(() => _saving = true);
    try {
      if (assignment == null) {
        final created = await ref
            .read(assignmentsControllerProvider.notifier)
            .createAssignment(
              courseId: course!.id,
              courseTitle: course.title,
              title: _title.text.trim(),
              instructions: _instructions.text.trim(),
              externalUrl: _externalUrl.text.trim(),
              dueAt: _dueAt!,
              attachments: _attachments.value,
            );
        final targetScope = widget.creationRequest?.targetScope;
        if (targetScope != null) {
          await ref
              .read(curriculumActionsProvider(targetScope).notifier)
              .link(
                CurriculumAssessment(
                  id: created.id,
                  assessmentId: created.id,
                  title: created.title,
                  kind: 'assignment',
                  status: 'draft',
                ),
              );
        }
      } else {
        await ref
            .read(assignmentsControllerProvider.notifier)
            .updateAssignment(
              assignmentId: assignment.id,
              title: _title.text.trim(),
              instructions: _instructions.text.trim(),
              externalUrl: _externalUrl.text.trim(),
              dueAt: _dueAt!,
              attachments: _attachments.value,
            );
      }
      if (!mounted) return;
      CustomToast.showSuccess(
        context,
        message: assignment != null
            ? 'Draft updated'
            : AppConfig.isSupabaseEnabled
            ? widget.creationRequest == null
                  ? 'Assignment draft created'
                  : 'Assignment published and linked to ${widget.creationRequest!.targetScope.targetLabel.toLowerCase()}.'
            : 'Assignment added to course',
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        ref.invalidate(assignmentsControllerProvider);
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : error is StateError &&
                    error.message.toString().contains('database update')
              ? error.message.toString()
              : error is StateError &&
                    error.message.toString().startsWith('Draft saved')
              ? error.message.toString()
              : 'Could not save assignment. Try again.',
        );
        if (error is StateError &&
            error.message.toString().startsWith('Draft saved')) {
          context.pop();
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.interSemiBold16.copyWith(
      fontSize: 14.sp,
      color: AppColors.onBackground,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isTeacher =
        ref.watch(authControllerProvider).value?.selectedRole ==
        UserRole.teacher;
    return PopScope(
      canPop: !_saving,
      child: AppScaffold(
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
            onPressed: _saving ? null : () => context.pop(),
          ),
          titleSpacing: 0,
          title: Text(
            widget.assignment == null
                ? widget.creationRequest == null
                      ? 'Add Assignment'
                      : 'Create & Link Assignment'
                : 'Edit Draft',
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
        body: !isTeacher
            ? const Center(child: Text('Teacher access only'))
            : AbsorbPointer(
                absorbing: _saving,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.course != null ||
                              widget.assignment != null)
                            Text(
                              widget.course?.title ??
                                  widget.assignment!.courseTitle,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 13.sp,
                                color: AppColors.primary,
                              ),
                            )
                          else ...[
                            _label('Course'),
                            SizedBox(height: 8.h),
                            ref
                                .watch(teacherControllerProvider)
                                .when(
                                  data: (state) {
                                    final scaffoldColor = Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor;
                                    final border = OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: AppColors.grey300,
                                        width: 1.w,
                                      ),
                                    );
                                    return DropdownButtonFormField<String>(
                                      initialValue: _selectedCourseId,
                                      isExpanded: true,
                                      dropdownColor: scaffoldColor,
                                      borderRadius: BorderRadius.circular(12.r),
                                      menuMaxHeight: 320.h,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.grey600,
                                        size: 22.w,
                                      ),
                                      style: AppTextStyles.interRegular16
                                          .copyWith(
                                            fontSize: 16.sp,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                      hint: Text(
                                        'Select a course',
                                        style: AppTextStyles.interRegular16
                                            .copyWith(
                                              fontSize: 16.sp,
                                              color: AppColors.grey500,
                                            ),
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: scaffoldColor,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 16.h,
                                        ),
                                        enabledBorder: border,
                                        border: border,
                                        focusedBorder: border.copyWith(
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 1.w,
                                          ),
                                        ),
                                        errorBorder: border.copyWith(
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            width: 1.w,
                                          ),
                                        ),
                                      ),
                                      items: state.courses.map((course) {
                                        final selected =
                                            course.id == _selectedCourseId;
                                        return DropdownMenuItem(
                                          value: course.id,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  course.title,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles
                                                      .interRegular16
                                                      .copyWith(
                                                        fontSize: 16.sp,
                                                        color: selected
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                      ),
                                                ),
                                              ),
                                              if (selected)
                                                Icon(
                                                  Icons.check,
                                                  size: 18.w,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      selectedItemBuilder: (context) => state
                                          .courses
                                          .map(
                                            (course) => Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                course.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (id) => setState(
                                        () => _selectedCourseId = id,
                                      ),
                                      validator: (id) =>
                                          id == null ? 'Choose a course' : null,
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (_, __) =>
                                      const Text('Could not load courses.'),
                                ),
                          ],
                          SizedBox(height: 28.h),
                          _label('Assignment Title'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _title,
                            hintText: 'e.g. Customs Act case study',
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter an assignment title'
                                : null,
                          ),
                          SizedBox(height: 24.h),
                          _label('Instructions'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _instructions,
                            hintText: 'Describe the task and expected answer',
                            maxLines: 6,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter instructions'
                                : null,
                          ),
                          SizedBox(height: 24.h),
                          _label('External Link (Optional)'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _externalUrl,
                            hintText: 'https://example.com',
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            validator: assignmentLinkError,
                          ),
                          SizedBox(height: 24.h),
                          _label('Due Date'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _dueDateText,
                            hintText: 'Select a due date',
                            readOnly: true,
                            onTap: _pickDueDate,
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.grey500,
                              size: 20.w,
                            ),
                            validator: (_) =>
                                _dueAt == null ? 'Select a due date' : null,
                          ),
                          SizedBox(height: 24.h),
                          ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _label('Files (Optional)'),
                                ValueListenableBuilder<
                                  List<AssignmentAttachmentModel>
                                >(
                                  valueListenable: _attachments,
                                  builder: (context, docs, _) =>
                                      docs.isEmpty || docs.length >= 5
                                      ? const SizedBox.shrink()
                                      : TextButton.icon(
                                          onPressed: _pickDocs,
                                          icon: Icon(
                                            Icons.upload_file,
                                            size: 16.w,
                                          ),
                                          label: const Text('Add File'),
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            ValueListenableBuilder<
                              List<AssignmentAttachmentModel>
                            >(
                              valueListenable: _attachments,
                              builder: (context, docs, _) {
                                if (docs.isEmpty) {
                                  return InkWell(
                                    onTap: _pickDocs,
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 18.h,
                                        horizontal: 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.grey300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 22.w,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(
                                              'Attach documents, images, or video',
                                              textAlign: TextAlign.center,
                                              style: AppTextStyles.interMedium16
                                                  .copyWith(
                                                    fontSize: 13.sp,
                                                    color: AppColors.grey600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Column(
                                  children: docs.map((doc) {
                                    final mb = (doc.sizeBytes / (1024 * 1024))
                                        .toStringAsFixed(1);
                                    final name = doc.name.toLowerCase();
                                    final isPdf = name.endsWith('.pdf');
                                    final isVideo =
                                        name.endsWith('.mp4') ||
                                        name.endsWith('.mov');
                                    final isImage =
                                        name.endsWith('.jpg') ||
                                        name.endsWith('.jpeg') ||
                                        name.endsWith('.png');
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.grey200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isPdf
                                                ? Icons.picture_as_pdf
                                                : isVideo
                                                ? Icons.play_circle_outline
                                                : isImage
                                                ? Icons.image_outlined
                                                : Icons
                                                      .insert_drive_file_outlined,
                                            color: isPdf
                                                ? const Color(0xFFC62828)
                                                : AppColors.primary,
                                            size: 22.w,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc.name,
                                                  style: AppTextStyles
                                                      .interMedium16
                                                      .copyWith(
                                                        fontSize: 13.sp,
                                                        color: AppColors
                                                            .onBackground,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  '$mb MB',
                                                  style: AppTextStyles
                                                      .interRegular14
                                                      .copyWith(
                                                        fontSize: 11.sp,
                                                        color:
                                                            AppColors.grey500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Remove document',
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: AppColors.grey500,
                                            ),
                                            onPressed: () {
                                              _attachments.value = _attachments
                                                  .value
                                                  .where((item) => item != doc)
                                                  .toList();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                          SizedBox(height: 32.h),
                          CustomButton(
                            text: _saving
                                ? 'Saving...'
                                : widget.assignment == null
                                ? widget.creationRequest == null
                                      ? 'Add Assignment'
                                      : 'Create & Link Assignment'
                                : 'Save Draft',
                            color: AppColors.primary,
                            height: 56.h,
                            borderRadius: 16.r,
                            onPressed: _create,
                            trailingIcon: _saving
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : null,
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
}

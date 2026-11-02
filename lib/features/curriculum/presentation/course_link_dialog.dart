import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkScopeSelection {
  const LinkScopeSelection({required this.scope, required this.targetLabel});

  final CurriculumScope scope;
  final String targetLabel;
}

Future<void> showCourseLinkDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String kind,
  required String assessmentId,
  required String title,
  required String status,
}) async {
  List<CourseModel> availableCourses;
  try {
    availableCourses = (await ref.read(
      teacherControllerProvider.future,
    )).courses;
  } catch (_) {
    if (context.mounted) {
      CustomToast.showError(context, message: 'Could not load courses.');
    }
    return;
  }
  final courses = availableCourses;
  if (!context.mounted) return;
  if (courses.isEmpty) {
    CustomToast.showError(context, message: 'No courses available to link to.');
    return;
  }

  final selection = await showModalBottomSheet<LinkScopeSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) =>
        HierarchicalCourseLinkSheet(courses: courses, title: title, kind: kind),
  );

  if (selection != null && context.mounted) {
    final confirmed = await confirmAssessmentLinkChange(
      context: context,
      title: title,
      target: selection.targetLabel,
      unlink: false,
      publish: status == 'draft',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(curriculumActionsProvider(selection.scope).notifier)
          .link(
            CurriculumAssessment(
              id: assessmentId,
              assessmentId: assessmentId,
              title: title,
              kind: kind,
              status: status,
            ),
          );
      ref.invalidate(teacherControllerProvider);
      ref.invalidate(assignmentsControllerProvider);
      if (context.mounted) {
        CustomToast.showSuccess(
          context,
          message: status == 'draft'
              ? '$title linked and published in ${selection.targetLabel}.'
              : '$title linked to ${selection.targetLabel}.',
        );
      }
    } on PostgrestException catch (error) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: error.message.toLowerCase().contains('due date')
              ? 'This assignment’s due date has passed.'
              : 'Could not link to curriculum.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: 'Could not link to curriculum.',
        );
      }
    }
  }
}

class HierarchicalCourseLinkSheet extends ConsumerStatefulWidget {
  const HierarchicalCourseLinkSheet({
    super.key,
    required this.courses,
    required this.title,
    required this.kind,
  });

  final List<CourseModel> courses;
  final String title;
  final String kind;

  @override
  ConsumerState<HierarchicalCourseLinkSheet> createState() =>
      _HierarchicalCourseLinkSheetState();
}

class _HierarchicalCourseLinkSheetState
    extends ConsumerState<HierarchicalCourseLinkSheet> {
  CourseModel? _selectedCourse;
  CourseModuleModel? _selectedModule;
  bool _loadingDetails = false;

  Future<void> _selectCourse(CourseModel course) async {
    setState(() {
      _selectedCourse = course;
      _selectedModule = null;
    });

    if (course.modules.isEmpty) {
      setState(() => _loadingDetails = true);
      try {
        final fullCourse = await ref
            .read(courseRepositoryProvider)
            .getCourseById(course.id);
        if (mounted && fullCourse != null && fullCourse.modules.isNotEmpty) {
          setState(() {
            _selectedCourse = fullCourse;
          });
        }
      } catch (_) {
        // Fall back to original course
      } finally {
        if (mounted) setState(() => _loadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _loadingDetails
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : _selectedModule != null
                      ? _buildLessonsView()
                      : _selectedCourse != null
                      ? _buildModulesView()
                      : _buildCoursesView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String currentTitle =
        'Link ${widget.kind == 'quiz' ? 'Quiz' : 'Assignment'}';
    String breadcrumb = 'Select course';

    if (_selectedModule != null) {
      currentTitle = _selectedModule!.title;
      breadcrumb = '${_selectedCourse!.title} › ${_selectedModule!.title}';
    } else if (_selectedCourse != null) {
      currentTitle = _selectedCourse!.title;
      breadcrumb = 'Courses › ${_selectedCourse!.title}';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_selectedCourse != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      if (_selectedModule != null) {
                        _selectedModule = null;
                      } else {
                        _selectedCourse = null;
                      }
                    });
                  },
                ),
              if (_selectedCourse != null) SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  currentTitle,
                  style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.grey500),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            breadcrumb,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 11.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Link "${widget.title}" to target scope:',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 12.sp,
              color: AppColors.grey600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesView() {
    return ListView.separated(
      key: const ValueKey('courses_list'),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: widget.courses.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final course = widget.courses[index];
        final moduleCount = course.modules.length;

        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: AppColors.grey200, width: 1.w),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 4.h,
            ),
            leading: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              course.title,
              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
            ),
            subtitle: Text(
              '${course.category} • ${moduleCount > 0 ? "$moduleCount modules" : "Course curriculum"}',
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 11.sp,
                color: AppColors.grey500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
            onTap: () => _selectCourse(course),
          ),
        );
      },
    );
  }

  Widget _buildModulesView() {
    final course = _selectedCourse!;
    final modules = course.modules;

    return ListView(
      key: const ValueKey('modules_list'),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        // Level 1 Action: Link to entire course
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(
                  Icons.all_inclusive,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link to Entire Course',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Available globally across all lessons in ${course.title}',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    LinkScopeSelection(
                      scope: CurriculumScope(courseId: course.id),
                      targetLabel: course.title,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                ),
                child: const Text('Attach'),
              ),
            ],
          ),
        ),

        if (modules.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 20.h, 4.w, 10.h),
            child: Text(
              'OR SELECT SPECIFIC MODULE',
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 11.sp,
                color: AppColors.grey500,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...modules.map((module) {
            final lessonCount = module.lessons.length;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: AppColors.grey200, width: 1.w),
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.grey700,
                    ),
                  ),
                  title: Text(
                    module.title,
                    style: AppTextStyles.interMedium16.copyWith(
                      fontSize: 13.sp,
                    ),
                  ),
                  subtitle: Text(
                    '$lessonCount ${lessonCount == 1 ? "lesson" : "lessons"}',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            LinkScopeSelection(
                              scope: CurriculumScope(
                                courseId: course.id,
                                moduleId: module.id,
                              ),
                              targetLabel: module.title,
                            ),
                          );
                        },
                        child: const Text('Link Module'),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.grey400),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedModule = module);
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLessonsView() {
    final course = _selectedCourse!;
    final module = _selectedModule!;
    final lessons = module.lessons;

    return ListView(
      key: const ValueKey('lessons_list'),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        // Level 2 Action: Link to entire module
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const Icon(Icons.folder, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link to Entire Module',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      module.title,
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 11.sp,
                        color: AppColors.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    LinkScopeSelection(
                      scope: CurriculumScope(
                        courseId: course.id,
                        moduleId: module.id,
                      ),
                      targetLabel: module.title,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                ),
                child: const Text('Attach'),
              ),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 20.h, 4.w, 10.h),
          child: Text(
            'OR SELECT SPECIFIC LESSON',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 11.sp,
              color: AppColors.grey500,
              letterSpacing: 0.6,
            ),
          ),
        ),

        if (lessons.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Text(
                'No lessons in this module.',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
            ),
          )
        else
          ...lessons.map((lesson) {
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: AppColors.grey200, width: 1.w),
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: AppTextStyles.interMedium16.copyWith(
                      fontSize: 13.sp,
                    ),
                  ),
                  subtitle: Text(
                    '${lesson.durationMinutes} min',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop(
                        LinkScopeSelection(
                          scope: CurriculumScope(
                            courseId: course.id,
                            moduleId: module.id,
                            lessonId: lesson.id,
                          ),
                          targetLabel: lesson.title,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                    ),
                    child: const Text('Link Lesson'),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

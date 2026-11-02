import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/teacher_assignments_section.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/presentation/course_link_dialog.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_type_tabs.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_status_section.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherQuizStudioScreen extends ConsumerStatefulWidget {
  const TeacherQuizStudioScreen({
    super.key,
    this.initialTab = 0,
    this.targetScope,
  });

  final int initialTab;
  final CurriculumScope? targetScope;

  @override
  ConsumerState<TeacherQuizStudioScreen> createState() =>
      _TeacherQuizStudioScreenState();
}

class _TeacherQuizStudioScreenState
    extends ConsumerState<TeacherQuizStudioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAssignmentTab = _tabController.index == 1;

    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.onBackground,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          widget.targetScope != null ? 'Link Assessments' : 'Assessment Studio',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.targetScope != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 20.w, color: AppColors.primary),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LINKING ASSESSMENTS TO ${widget.targetScope!.targetLabel.toUpperCase()}',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 10.sp,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Choose an assessment to link',
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
                  ],
                ),
              ),
            AssessmentTypeTabs(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TeacherQuizContent(targetScope: widget.targetScope),
                  TeacherAssignmentsSection(targetScope: widget.targetScope),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: isAssignmentTab
            ? FloatingActionButton(
                key: const ValueKey('assignment_fab'),
                heroTag: 'teacher_assignment_fab',
                tooltip: 'Create Assignment',
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                onPressed: () => context.pushNamed(
                  AppRoute.teacherCreateAssignment.name,
                  extra: widget.targetScope == null
                      ? null
                      : AssessmentCreationRequest(widget.targetScope!),
                ),
                child: const Icon(Icons.add),
              )
            : Column(
                key: const ValueKey('quiz_fabs'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'teacher_ai_quiz_fab',
                    tooltip: 'Generate AI quiz',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    onPressed: () =>
                        context.pushNamed(AppRoute.generateAiQuiz.name),
                    child: const Icon(Icons.auto_awesome),
                  ),
                  SizedBox(height: 12.h),
                  FloatingActionButton.extended(
                    heroTag: 'teacher_quiz_fab',
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    onPressed: () => context.pushNamed(
                      AppRoute.teacherCreateQuiz.name,
                      extra: widget.targetScope == null
                          ? null
                          : AssessmentCreationRequest(widget.targetScope!),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      widget.targetScope == null
                          ? 'Create Quiz'
                          : 'Create & Link Quiz',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TeacherQuizContent extends ConsumerWidget {
  const _TeacherQuizContent({this.targetScope});

  final CurriculumScope? targetScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);
    return ColoredBox(
      color: AppColors.background,
      child: teacherState.when(
        data: (state) {
          final published = state.quizzes
              .where((quiz) => quiz.courseId != null)
              .toList();
          final drafts = state.quizzes
              .where((quiz) => quiz.courseId == null)
              .toList();
          if (published.isEmpty && drafts.isEmpty) {
            return const _QuizEmptyState();
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 104.h),
            children: [
              AssessmentStatusSection(
                title: 'Published',
                count: published.length,
                onSeeAll: () => context.pushNamed(
                  AppRoute.teacherAssessmentList.name,
                  queryParameters: {'kind': 'quiz', 'status': 'published'},
                  extra: targetScope,
                ),
                children: [
                  for (final quiz in published.take(
                    AssessmentStatusSection.previewLimit,
                  ))
                    TeacherQuizListItem(quiz: quiz, targetScope: targetScope),
                ],
              ),
              if (published.isNotEmpty && drafts.isNotEmpty)
                SizedBox(height: 28.h),
              AssessmentStatusSection(
                title: 'Drafts',
                count: drafts.length,
                onSeeAll: () => context.pushNamed(
                  AppRoute.teacherAssessmentList.name,
                  queryParameters: {'kind': 'quiz', 'status': 'draft'},
                  extra: targetScope,
                ),
                children: [
                  for (final quiz in drafts.take(
                    AssessmentStatusSection.previewLimit,
                  ))
                    TeacherQuizListItem(quiz: quiz, targetScope: targetScope),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Could not load quizzes.',
            style: AppTextStyles.interMedium16.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherQuizListItem extends ConsumerWidget {
  const TeacherQuizListItem({super.key, required this.quiz, this.targetScope});

  final QuizModel quiz;
  final CurriculumScope? targetScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedAssessments = targetScope != null
        ? ref.watch(curriculumAssessmentsProvider(targetScope!)).value ?? []
        : const <CurriculumAssessment>[];
    final isLinked =
        targetScope != null &&
        linkedAssessments.any(
          (a) => a.kind == 'quiz' && a.assessmentId == quiz.id,
        );

    return InkWell(
      onTap: () => context.pushNamed(
        quiz.courseId == null
            ? AppRoute.teacherCreateQuiz.name
            : AppRoute.teacherQuizAnalysis.name,
        extra: quiz,
      ),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 12.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 5.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${quiz.totalQuestions} questions · ${quiz.durationMinutes} min · Pass ${quiz.passingScore}%',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                PopupMenuButton<String>(
                  tooltip: 'Quiz actions',
                  color: Theme.of(context).scaffoldBackgroundColor,
                  onSelected: (action) {
                    if (action == 'edit') {
                      context.pushNamed(
                        AppRoute.teacherCreateQuiz.name,
                        extra: quiz,
                      );
                    } else if (action == 'analysis' && quiz.courseId != null) {
                      context.pushNamed(
                        AppRoute.teacherQuizAnalysis.name,
                        extra: quiz,
                      );
                    } else if (action == 'link') {
                      showCourseLinkDialog(
                        context: context,
                        ref: ref,
                        kind: 'quiz',
                        assessmentId: quiz.id,
                        title: quiz.title,
                        status: quiz.isPublished ? 'published' : 'draft',
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (!quiz.isPublished)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit draft'),
                      ),
                    const PopupMenuItem(
                      value: 'link',
                      child: Text('Link to course'),
                    ),
                    if (quiz.courseId != null)
                      const PopupMenuItem(
                        value: 'analysis',
                        child: Text('View analysis'),
                      ),
                  ],
                ),
              ],
            ),
            if (targetScope != null) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isLinked)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Linked to ${targetScope!.targetLabel}',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 11.sp,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () async {
                        final confirmed = await confirmAssessmentLinkChange(
                          context: context,
                          title: quiz.title,
                          target: targetScope!.targetLabel.toLowerCase(),
                          unlink: false,
                          publish: !quiz.isPublished,
                        );
                        if (!confirmed || !context.mounted) return;
                        try {
                          await ref
                              .read(
                                curriculumActionsProvider(
                                  targetScope!,
                                ).notifier,
                              )
                              .link(
                                CurriculumAssessment(
                                  id: quiz.id,
                                  assessmentId: quiz.id,
                                  title: quiz.title,
                                  kind: 'quiz',
                                  status: quiz.isPublished
                                      ? 'published'
                                      : 'draft',
                                ),
                              );
                          ref.invalidate(teacherControllerProvider);
                          if (context.mounted) {
                            CustomToast.showSuccess(
                              context,
                              message: quiz.isPublished
                                  ? 'Quiz linked to ${targetScope!.targetLabel.toLowerCase()}.'
                                  : 'Quiz published in ${targetScope!.targetLabel.toLowerCase()}.',
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            CustomToast.showError(
                              context,
                              message: 'Could not link quiz to course.',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.link, size: 16),
                      label: Text('Link to ${targetScope!.targetLabel}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizEmptyState extends StatelessWidget {
  const _QuizEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 42.w, color: AppColors.grey400),
            SizedBox(height: 10.h),
            Text(
              'No quizzes yet',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 15.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Create a quiz or generate a draft with AI.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

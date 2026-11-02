import 'student_learning_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_lesson_media_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_video_preview.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

part 'curriculum_owner_helpers.dart';
part 'curriculum_owner_materials.dart';
part 'curriculum_owner_assessments.dart';

class CurriculumResourcesScreen extends ConsumerWidget {
  const CurriculumResourcesScreen({super.key, required this.scope});
  final CurriculumScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.onBackground,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Materials & Assessments',
        style: AppTextStyles.interBold24.copyWith(
          fontSize: 18.sp,
          color: AppColors.onBackground,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(color: AppColors.grey200, height: 1.h),
      ),
    ),
    body: ref
        .watch(curriculumContextProvider(scope))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load resources',
                  style: AppTextStyles.interRegular14.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.invalidate(curriculumContextProvider(scope)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (resolved) => resolved.canManage
              ? _Content(key: ValueKey(resolved.scope), details: resolved)
              : StudentLearningResources(details: resolved),
        ),
  );
}

class _Content extends ConsumerWidget {
  const _Content({super.key, required this.details});
  final CurriculumContext details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(curriculumActionsProvider(details.scope));
    final materialsAsync = ref.watch(
      curriculumMaterialsProvider(details.scope),
    );
    final assessmentsAsync = ref.watch(
      curriculumAssessmentsProvider(details.scope),
    );
    final mediaAsync = details.scope.lessonId != null
        ? ref.watch(teacherLessonMediaProvider(details.scope.lessonId!))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: details.canManage
          ? FloatingActionButton.extended(
              heroTag: 'curriculum_lesson_studio_fab',
              onPressed: () => _openLessonStudio(context, ref),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Lesson Studio',
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.primary,
              elevation: 4,
            )
          : null,
      body: PopScope(
        canPop: !busy,
        child: AbsorbPointer(
          absorbing: busy,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _run(context, () async {
                  ref.invalidate(curriculumMaterialsProvider(details.scope));
                  ref.invalidate(curriculumAssessmentsProvider(details.scope));
                  if (details.scope.lessonId != null) {
                    ref.invalidate(
                      teacherLessonMediaProvider(details.scope.lessonId!),
                    );
                  }
                  await ref.read(
                    curriculumMaterialsProvider(details.scope).future,
                  );
                  await ref.read(
                    curriculumAssessmentsProvider(details.scope).future,
                  );
                }),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 90.h),
                  children: [
                    // Scope Header Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.folder_special_outlined,
                              color: AppColors.primary,
                              size: 24.w,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.title,
                                  style: AppTextStyles.interBold24.copyWith(
                                    fontSize: 16.sp,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  details.canManage
                                      ? 'Curriculum Workspace & Attachments'
                                      : 'Student Learning Resources',
                                  style: AppTextStyles.interRegular14.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 1. ATTACHED VIDEO (If available for lesson scope)
                    if (mediaAsync != null)
                      mediaAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (items) {
                          if (items.isEmpty) return const SizedBox.shrink();
                          final activeVideo = items.firstWhere(
                            (m) => m.status == 'ready',
                            orElse: () => items.first,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                title: 'ATTACHED VIDEO',
                                icon: Icons.videocam_outlined,
                              ),
                              _buildAttachedVideoCard(
                                context,
                                ref,
                                activeVideo,
                              ),
                            ],
                          );
                        },
                      ),

                    // 2. ATTACHED MATERIALS & HANDOUTS
                    _buildOwnerMaterialSection(context, ref, materialsAsync),

                    // 3. ATTACHED ASSESSMENTS (ONLY SHOW WHEN ASSESSMENTS EXIST)
                    _buildOwnerAssessmentSection(
                      context,
                      ref,
                      assessmentsAsync,
                    ),

                    // 4. CLEAN COMBINED EMPTY STATE (Only when totally empty)
                    if ((materialsAsync.value?.isEmpty ?? false) &&
                        (assessmentsAsync.value?.isEmpty ?? false) &&
                        (mediaAsync?.value?.isEmpty ?? true))
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 40.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_open_outlined,
                                size: 40.w,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No Resources Attached Yet',
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                details.canManage
                                    ? 'Tap Lesson Studio (+) to add video, upload handouts, or link quizzes and assignments.'
                                    : 'No study materials or assessments have been published yet.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

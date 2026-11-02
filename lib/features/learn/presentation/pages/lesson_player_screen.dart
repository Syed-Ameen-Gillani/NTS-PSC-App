import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/in_video_quiz_dialog.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_discussion_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_notes_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_video_viewport.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_access_gate.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_subtopic.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  final CourseModel? course;
  final LessonModel? initialLesson;
  final LessonPlayerMode mode;

  const LessonPlayerScreen({
    super.key,
    this.course,
    this.initialLesson,
    this.mode = LessonPlayerMode.learning,
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseModel _course;
  late LessonModel _currentLesson;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initial course matching user screenshot
    _course =
        widget.course ??
        CourseModel(
          id: 'c_ajk_psc',
          title: 'AJK PSC General Recruitment Masterclass',
          author: 'Dr. Usman',
          rating: 4.9,
          price: 'Rs 3,500',
          imagePath: 'assets/images/course4.jpg',
        );

    // Initial lesson matching user screenshot
    _currentLesson =
        widget.initialLesson ??
        LessonModel(
          id: 'l_ajk_const_1974',
          title: 'AJK Interim Constitution Act 1974',
          durationMinutes: 25,
          notes:
              'Structure of AJK Legislative Assembly, Council, and High Court/Supreme Court.',
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSyllabusTab() {
    final modules = _course.modules;

    if (modules.isEmpty) {
      // Default curriculum for demonstration
      return ListView(
        padding: EdgeInsets.all(24.w),
        children: [
          _buildModuleCard(
            title: 'Module 1: Constitutional & Administrative Framework',
            lessons: [
              _currentLesson.copyWith(
                activities: const [
                  LessonActivity(
                    id: 'act_const_quiz',
                    kind: 'quiz',
                    title: 'Constitution Framework Quiz',
                    order: 1,
                    isRequired: true,
                  ),
                  LessonActivity(
                    id: 'act_const_doc',
                    kind: 'material',
                    title: 'Interim Constitution Act 1974 Handout',
                    order: 2,
                    isRequired: false,
                  ),
                ],
              ),
              LessonModel(
                id: 'l2',
                title: 'High Court & Supreme Court Jurisdiction under Act 1974',
                durationMinutes: 30,
                notes:
                    'Writ jurisdiction under Section 44 and appellate procedures.',
                activities: const [
                  LessonActivity(
                    id: 'act_hc_assignment',
                    kind: 'assignment',
                    title: 'Writ Petition Drafting Assignment',
                    order: 1,
                    isRequired: true,
                  ),
                  LessonActivity(
                    id: 'act_case_notes',
                    kind: 'material',
                    title: 'Landmark Judicial Precedents Handout',
                    order: 2,
                    isRequired: false,
                  ),
                ],
              ),
              LessonModel(
                id: 'l3',
                title: 'AJK Civil Servants Act & Efficiency Rules',
                durationMinutes: 20,
                notes: 'Disciplinary proceedings, inquiries, and appeals.',
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _buildModuleCard(
            title: 'Module 2: General Knowledge & Pakistan Affairs',
            lessons: [
              LessonModel(
                id: 'l4',
                title: 'Kashmir Dispute & UNCIP Resolutions Overview',
                durationMinutes: 35,
                notes: 'Chronological events from 1947 to present date.',
                activities: const [
                  LessonActivity(
                    id: 'act_uncip_quiz',
                    kind: 'quiz',
                    title: 'UNCIP Resolutions Assessment',
                    order: 1,
                    isRequired: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(24.w),
      itemCount: modules.length,
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (context, mIdx) {
        final module = modules[mIdx];
        return _buildModuleCard(title: module.title, lessons: module.lessons);
      },
    );
  }

  Widget _buildModuleCard({
    required String title,
    required List<LessonModel> lessons,
  }) {
    return Material(
      color: const Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.grey300),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          title,
          style: AppTextStyles.interBold24.copyWith(fontSize: 13.sp),
        ),
        subtitle: Text(
          '${lessons.length} Lectures',
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 11.sp,
            color: AppColors.grey500,
          ),
        ),
        children: lessons.map((lesson) {
          final isCurrent = lesson.id == _currentLesson.id;
          final subTopics = lesson.activities
              .map(LessonSubTopic.fromActivity)
              .whereType<LessonSubTopic>()
              .toList();

          return Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 12.r,
                    backgroundColor: isCurrent
                        ? AppColors.primary
                        : AppColors.grey300,
                    child: Icon(
                      isCurrent ? Icons.play_arrow : Icons.lock_outline,
                      size: 14.w,
                      color: isCurrent ? Colors.white : AppColors.grey500,
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 12.sp,
                      color: isCurrent ? AppColors.primary : AppColors.onBackground,
                    ),
                  ),
                  subtitle: Text(
                    '${lesson.durationMinutes} mins',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                  onTap: () {
                    setState(() => _currentLesson = lesson);
                    CustomToast.showInfo(
                      context,
                      message: 'Loaded: ${lesson.title}',
                    );
                  },
                ),
                if (subTopics.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: 48.w, right: 16.w, bottom: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final subTopic in subTopics)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Material(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6.r),
                                onTap: () {
                                  CustomToast.showInfo(
                                    context,
                                    message: 'Opening ${subTopic.kindLabel}: ${subTopic.title}',
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                                  child: Row(
                                    children: [
                                      Icon(
                                        subTopic.icon,
                                        size: 14.w,
                                        color: subTopic.kind == LessonSubTopicKind.handout
                                            ? AppColors.grey700
                                            : AppColors.primary,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          subTopic.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.interMedium16.copyWith(
                                            fontSize: 11.sp,
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: (subTopic.kind == LessonSubTopicKind.handout
                                                  ? AppColors.grey500
                                                  : AppColors.primary)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          subTopic.kindLabel,
                                          style: AppTextStyles.interSemiBold16.copyWith(
                                            fontSize: 9.sp,
                                            color: subTopic.kind == LessonSubTopicKind.handout
                                                ? AppColors.grey700
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isSupabaseEnabled) {
      if (widget.course == null) {
        return const AppScaffold(
          body: Center(child: Text('Lesson unavailable')),
        );
      }
      return LessonAccessGate(
        courseId: widget.course!.id,
        lessonId: widget.initialLesson?.id,
        mode: widget.mode,
      );
    }
    // Listen for surprise in-video quiz checkpoint trigger
    ref.listen<LessonPlaybackState>(lessonPlaybackControllerProvider, (
      previous,
      next,
    ) {
      if (next.activeQuizTriggerId != null &&
          previous?.activeQuizTriggerId != next.activeQuizTriggerId) {
        ref
            .read(inVideoQuizControllerProvider.notifier)
            .triggerQuizById(next.activeQuizTriggerId!);
        InVideoQuizDialog.show(context);
      }
    });

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactLandscape =
                constraints.maxWidth > constraints.maxHeight &&
                constraints.maxHeight < 500;
            return Flex(
              direction: isCompactLandscape ? Axis.horizontal : Axis.vertical,
              children: [
                // Video Viewport Component with Coursera Checkpoint Pip
                if (isCompactLandscape)
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: LessonVideoViewport(
                          course: _course,
                          lesson: _currentLesson,
                        ),
                      ),
                    ),
                  )
                else
                  LessonVideoViewport(course: _course, lesson: _currentLesson),

                Expanded(
                  child: Column(
                    children: [
                      // Lesson Header Details (exactly matching screenshot)
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _course.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _currentLesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Instructor: ${_course.author} • Lesson Duration: ${_currentLesson.durationMinutes} mins',
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 11.sp,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.grey300,
                              width: 1.w,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primary,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.grey500,
                          labelStyle: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 13.sp,
                          ),
                          unselectedLabelStyle: AppTextStyles.interMedium16
                              .copyWith(fontSize: 13.sp),
                          tabs: const [
                            Tab(text: 'Study Notes'),
                            Tab(text: 'Syllabus'),
                            Tab(text: 'Discussion'),
                          ],
                        ),
                      ),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            LessonNotesTab(
                              course: _course,
                              lesson: _currentLesson,
                            ),
                            _buildSyllabusTab(),
                            LessonDiscussionTab(
                              course: _course,
                              lesson: _currentLesson,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/in_video_quiz_dialog.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_discussion_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_notes_tab.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_video_viewport.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  final CourseModel? course;
  final LessonModel? initialLesson;

  const LessonPlayerScreen({
    super.key,
    this.course,
    this.initialLesson,
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseModel _course;
  late LessonModel _currentLesson;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initial course matching user screenshot
    _course = widget.course ??
        CourseModel(
          id: 'c_ajk_psc',
          title: 'AJK PSC General Recruitment Masterclass',
          author: 'Dr. Usman',
          rating: 4.9,
          price: 'Rs 3,500',
          imagePath: 'assets/images/course4.jpg',
        );

    // Initial lesson matching user screenshot
    _currentLesson = widget.initialLesson ??
        LessonModel(
          id: 'l_ajk_const_1974',
          title: 'AJK Interim Constitution Act 1974',
          durationMinutes: 25,
          notes: 'Structure of AJK Legislative Assembly, Council, and High Court/Supreme Court.',
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
              _currentLesson,
              LessonModel(
                id: 'l2',
                title: 'High Court & Supreme Court Jurisdiction under Act 1974',
                durationMinutes: 30,
                notes: 'Writ jurisdiction under Section 44 and appellate procedures.',
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
        return _buildModuleCard(
          title: module.title,
          lessons: module.lessons,
        );
      },
    );
  }

  Widget _buildModuleCard({required String title, required List<LessonModel> lessons}) {
    return Material(
      color: const Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: const BorderSide(color: AppColors.grey300),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(title, style: AppTextStyles.interBold24.copyWith(fontSize: 13.sp)),
        subtitle: Text('${lessons.length} Lectures',
            style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500)),
        children: lessons.map((lesson) {
          final isCurrent = lesson.id == _currentLesson.id;
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                radius: 12.r,
                backgroundColor: isCurrent ? AppColors.primary : AppColors.grey300,
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
              subtitle: Text('${lesson.durationMinutes} mins',
                  style: AppTextStyles.interRegular14.copyWith(fontSize: 10.sp, color: AppColors.grey500)),
              onTap: () {
                setState(() => _currentLesson = lesson);
                CustomToast.showInfo(context, message: 'Loaded: ${lesson.title}');
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for surprise in-video quiz checkpoint trigger
    ref.listen<LessonPlaybackState>(
      lessonPlaybackControllerProvider,
      (previous, next) {
        if (next.activeQuizTriggerId != null &&
            previous?.activeQuizTriggerId != next.activeQuizTriggerId) {
          ref.read(inVideoQuizControllerProvider.notifier).triggerQuizById(next.activeQuizTriggerId!);
          InVideoQuizDialog.show(context);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Video Viewport Component with Coursera Checkpoint Pip
            LessonVideoViewport(course: _course, lesson: _currentLesson),

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
                    style: AppTextStyles.interRegular14.copyWith(fontSize: 12.sp, color: AppColors.primary),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _currentLesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp, color: AppColors.onBackground),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Instructor: ${_course.author} • Lesson Duration: ${_currentLesson.durationMinutes} mins',
                    style: AppTextStyles.interRegular14.copyWith(fontSize: 11.sp, color: AppColors.grey500),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey300, width: 1.w),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey500,
                labelStyle: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp),
                unselectedLabelStyle: AppTextStyles.interMedium16.copyWith(fontSize: 13.sp),
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
                  LessonNotesTab(course: _course, lesson: _currentLesson),
                  _buildSyllabusTab(),
                  LessonDiscussionTab(course: _course, lesson: _currentLesson),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

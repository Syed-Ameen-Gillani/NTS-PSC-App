part of 'go_router.dart';

List<RouteBase> _teacherRoutes() => [
  // --- TEACHER SHELL & STUDIO FLOW ---
  GoRoute(
    path: AppRoute.teacherMain.path,
    name: AppRoute.teacherMain.name,
    builder: (context, state) => const TeacherMainScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherCreateCourse.path,
    name: AppRoute.teacherCreateCourse.name,
    builder: (context, state) => const TeacherCreateCourseScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherCreateQuiz.path,
    name: AppRoute.teacherCreateQuiz.name,
    builder: (context, state) {
      final extra = state.extra;
      return TeacherCreateQuizScreen(
        quiz: extra is QuizModel ? extra : null,
        creationRequest: extra is AssessmentCreationRequest ? extra : null,
      );
    },
  ),
  GoRoute(
    path: AppRoute.teacherQuizQuestion.path,
    name: AppRoute.teacherQuizQuestion.name,
    builder: (context, state) => state.extra is QuizQuestionEditorArgs
        ? TeacherQuizQuestionScreen(args: state.extra as QuizQuestionEditorArgs)
        : const FeatureUnavailableScreen(
            title: 'Question editor',
            message: 'Open a quiz draft to add a question.',
          ),
  ),
  GoRoute(
    path: AppRoute.teacherQuizStudio.path,
    name: AppRoute.teacherQuizStudio.name,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Map<String, dynamic>) {
        return TeacherQuizStudioScreen(
          initialTab: extra['initialTab'] as int? ?? 0,
          targetScope: extra['targetScope'] as CurriculumScope?,
        );
      }
      return const TeacherQuizStudioScreen();
    },
  ),
  GoRoute(
    path: AppRoute.teacherQuizAnalysis.path,
    name: AppRoute.teacherQuizAnalysis.name,
    builder: (context, state) => state.extra is QuizModel
        ? TeacherQuizAnalysisScreen(quiz: state.extra as QuizModel)
        : const FeatureUnavailableScreen(
            title: 'Quiz analysis',
            message: 'Select a quiz from Assessment Studio.',
          ),
  ),
  GoRoute(
    path: AppRoute.teacherAssessmentList.path,
    name: AppRoute.teacherAssessmentList.name,
    builder: (context, state) => TeacherAssessmentListScreen(
      kind: state.uri.queryParameters['kind'] == 'assignment'
          ? 'assignment'
          : 'quiz',
      published: state.uri.queryParameters['status'] == 'published',
      targetScope: state.extra is CurriculumScope
          ? state.extra as CurriculumScope
          : null,
    ),
  ),
  GoRoute(
    path: AppRoute.teacherAnalytics.path,
    name: AppRoute.teacherAnalytics.name,
    builder: (context, state) => const TeacherAnalyticsScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherManageCourse.path,
    name: AppRoute.teacherManageCourse.name,
    builder: (context, state) {
      final course = state.extra;
      if (course is! CourseModel) {
        return const FeatureUnavailableScreen(
          title: 'Manage course',
          message: 'Select a course from your course list.',
        );
      }
      return TeacherManageCourseScreen(course: course);
    },
  ),
  GoRoute(
    path: AppRoute.teacherCreateLesson.path,
    name: AppRoute.teacherCreateLesson.name,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is! Map<String, dynamic> ||
          extra['courseId'] == null ||
          extra['moduleId'] == null) {
        return const FeatureUnavailableScreen(
          title: 'New lesson',
          message: 'Select a course module first.',
        );
      }
      return TeacherCreateLessonScreen(
        courseId: extra['courseId'] as String,
        moduleId: extra['moduleId'] as String,
      );
    },
  ),
  GoRoute(
    path: AppRoute.teacherLessonActivities.path,
    name: AppRoute.teacherLessonActivities.name,
    builder: (context, state) => TeacherLessonActivitiesScreen(
      lessonId: state.uri.queryParameters['lessonId'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoute.teacherLessonMedia.path,
    name: AppRoute.teacherLessonMedia.name,
    builder: (context, state) => state.extra is LessonModel
        ? TeacherLessonMediaScreen(lesson: state.extra as LessonModel)
        : const FeatureUnavailableScreen(
            title: 'Lesson video',
            message: 'Select a lesson from your curriculum.',
          ),
  ),
  GoRoute(
    path: AppRoute.teacherCourseAssignments.path,
    name: AppRoute.teacherCourseAssignments.name,
    builder: (context, state) =>
        TeacherCourseAssignmentsScreen(course: state.extra as CourseModel?),
  ),
  GoRoute(
    path: AppRoute.teacherCreateAssignment.path,
    name: AppRoute.teacherCreateAssignment.name,
    builder: (context, state) => TeacherCreateAssignmentScreen(
      course: state.extra is CourseModel ? state.extra as CourseModel : null,
      assignment: state.extra is AssignmentModel
          ? state.extra as AssignmentModel
          : null,
      creationRequest: state.extra is AssessmentCreationRequest
          ? state.extra as AssessmentCreationRequest
          : null,
    ),
  ),
  GoRoute(
    path: AppRoute.teacherReviewAssignment.path,
    name: AppRoute.teacherReviewAssignment.name,
    builder: (context, state) {
      final assignment = state.extra as AssignmentModel?;
      if (assignment != null && !assignment.isPublished) {
        return TeacherCreateAssignmentScreen(assignment: assignment);
      }
      final assignmentId = state.uri.queryParameters['assignmentId'];
      if (assignment == null && assignmentId != null) {
        return NotificationAssignmentPage(
          assignmentId: assignmentId,
          teacherReview: true,
        );
      }
      return TeacherReviewAssignmentScreen(assignment: assignment);
    },
  ),
  GoRoute(
    path: AppRoute.teacherDoubts.path,
    name: AppRoute.teacherDoubts.name,
    builder: (context, state) => const TeacherDoubtsScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherLiveClasses.path,
    name: AppRoute.teacherLiveClasses.name,
    builder: (context, state) => AppConfig.isSupabaseEnabled
        ? const LiveMeetingsScreen(teacher: true)
        : const TeacherLiveClassesScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherStudents.path,
    name: AppRoute.teacherStudents.name,
    builder: (context, state) =>
        TeacherStudentsScreen(initialCourseTitle: state.extra as String?),
  ),
  GoRoute(
    path: AppRoute.teacherPayouts.path,
    name: AppRoute.teacherPayouts.name,
    builder: (context, state) => const TeacherPayoutsScreen(),
  ),
];

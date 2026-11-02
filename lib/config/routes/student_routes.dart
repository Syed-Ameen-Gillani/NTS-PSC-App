part of 'go_router.dart';

List<RouteBase> _studentRoutes() => [
  GoRoute(
    path: AppRoute.curriculumResources.path,
    name: AppRoute.curriculumResources.name,
    builder: (_, state) {
      final extra = state.extra;
      return extra is CurriculumScope
          ? CurriculumResourcesScreen(scope: extra)
          : const FeatureUnavailableScreen(
              title: 'Curriculum',
              message: 'Select a course or lesson.',
            );
    },
  ),
  GoRoute(
    path: AppRoute.videoFullscreen.path,
    name: AppRoute.videoFullscreen.name,
    pageBuilder: (context, state) => NoTransitionPage(
      child: state.extra is VideoPlayerSession
          ? VideoFullscreenScreen(session: state.extra as VideoPlayerSession)
          : const FeatureUnavailableScreen(
              title: 'Video',
              message: 'Open a lesson to play its video.',
            ),
    ),
  ),
  GoRoute(
    path: AppRoute.offlineDownloads.path,
    name: AppRoute.offlineDownloads.name,
    builder: (context, state) => const OfflineDownloadsScreen(),
  ),
  GoRoute(
    path: AppRoute.offlineLesson.path,
    name: AppRoute.offlineLesson.name,
    builder: (context, state) => state.extra is LessonModel
        ? OfflineLessonScreen(lesson: state.extra as LessonModel)
        : const OfflineDownloadsScreen(),
  ),
  GoRoute(
    path: AppRoute.resetPassword.path,
    name: AppRoute.resetPassword.name,
    builder: (context, state) => const ResetPasswordScreen(),
  ),
  GoRoute(
    path: AppRoute.splash.path,
    name: AppRoute.splash.name,
    builder: (context, state) => const SplashScreen(),
  ),

  // --- ONBOARDING FLOW ---
  GoRoute(
    path: AppRoute.onboarding1.path,
    name: AppRoute.onboarding1.name,
    builder: (context, state) => const OnboardingScreen1(),
  ),
  GoRoute(
    path: AppRoute.onboarding2.path,
    name: AppRoute.onboarding2.name,
    builder: (context, state) => const OnboardingScreen2(),
  ),
  GoRoute(
    path: AppRoute.onboarding3.path,
    name: AppRoute.onboarding3.name,
    builder: (context, state) => const OnboardingScreen3(),
  ),
  GoRoute(
    path: AppRoute.onboarding4.path,
    name: AppRoute.onboarding4.name,
    builder: (context, state) => const OnboardingScreen4(),
  ),
  GoRoute(
    path: AppRoute.onboarding5.path,
    name: AppRoute.onboarding5.name,
    builder: (context, state) => const OnboardingScreen5(),
  ),
  GoRoute(
    path: AppRoute.onboarding6.path,
    name: AppRoute.onboarding6.name,
    builder: (context, state) => const OnboardingScreen6(),
  ),

  // --- ROLE SELECTION & ONBOARDING ---
  GoRoute(
    path: AppRoute.welcomeRole.path,
    name: AppRoute.welcomeRole.name,
    builder: (context, state) => const WelcomeRoleScreen(),
  ),
  GoRoute(
    path: AppRoute.welcome.path,
    name: AppRoute.welcome.name,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherWelcome.path,
    name: AppRoute.teacherWelcome.name,
    builder: (context, state) => const TeacherWelcomeScreen(),
  ),

  // --- AUTHENTICATION ---
  GoRoute(
    path: AppRoute.login.path,
    name: AppRoute.login.name,
    builder: (context, state) => const LoginPage(initialRole: UserRole.student),
  ),
  GoRoute(
    path: AppRoute.teacherLogin.path,
    name: AppRoute.teacherLogin.name,
    builder: (context, state) => const LoginPage(initialRole: UserRole.teacher),
  ),
  GoRoute(
    path: AppRoute.signup.path,
    name: AppRoute.signup.name,
    builder: (context, state) => const SignupCreateAccountScreen(),
  ),
  GoRoute(
    path: AppRoute.teacherSignup.path,
    name: AppRoute.teacherSignup.name,
    builder: (context, state) => const TeacherSignupScreen(),
  ),
  GoRoute(
    path: AppRoute.forgotPassword.path,
    name: AppRoute.forgotPassword.name,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),

  // --- STUDENT SHELL & LEARNING FLOW ---
  GoRoute(
    path: AppRoute.main.path,
    name: AppRoute.main.name,
    builder: (context, state) => const MainScreen(),
  ),
  GoRoute(
    path: AppRoute.courseDetail.path,
    name: AppRoute.courseDetail.name,
    builder: (context, state) {
      final extra = state.extra;
      final course = extra is CourseModel
          ? extra
          : extra is Map<String, dynamic>
          ? extra['course'] as CourseModel?
          : null;
      final viewMode = extra is Map<String, dynamic>
          ? extra['viewMode'] as CourseViewMode? ?? CourseViewMode.automatic
          : CourseViewMode.automatic;
      final courseId = state.uri.queryParameters['courseId'];
      if (course == null && courseId != null) {
        return NotificationCoursePage(courseId: courseId);
      }
      return CourseDetailScreen(course: course, viewMode: viewMode);
    },
  ),
  GoRoute(
    path: AppRoute.categoryCourses.path,
    name: AppRoute.categoryCourses.name,
    builder: (context, state) =>
        CategoryCoursesScreen(category: state.extra as CategoryModel?),
  ),
  GoRoute(
    path: AppRoute.newCourses.path,
    name: AppRoute.newCourses.name,
    builder: (context, state) => NewCoursesScreen(
      section: state.uri.queryParameters['section'] ?? 'new',
      category: state.uri.queryParameters['category'],
    ),
  ),
  GoRoute(
    path: AppRoute.courseSearch.path,
    name: AppRoute.courseSearch.name,
    builder: (context, state) => const CourseSearchScreen(),
  ),
  GoRoute(
    path: AppRoute.lessonReading.path,
    name: AppRoute.lessonReading.name,
    builder: (context, state) => LessonReadingScreen(
      reading: (
        lessonId: state.uri.queryParameters['lessonId'] ?? '',
        materialId: state.uri.queryParameters['materialId'],
      ),
      title: state.uri.queryParameters['title'],
      offlineOnly: state.uri.queryParameters['offline'] == '1',
    ),
  ),
  GoRoute(
    path: AppRoute.lessonPlayer.path,
    name: AppRoute.lessonPlayer.name,
    builder: (context, state) {
      final map = state.extra as Map<String, dynamic>?;
      final course = map?['course'] as CourseModel?;
      final lesson = map?['lesson'] as LessonModel?;
      final mode =
          map?['mode'] as LessonPlayerMode? ?? LessonPlayerMode.learning;
      final courseId = state.uri.queryParameters['courseId'];
      final lessonId = state.uri.queryParameters['lessonId'];
      if (course == null &&
          lesson == null &&
          courseId != null &&
          lessonId != null) {
        return NotificationLessonPage(courseId: courseId, lessonId: lessonId);
      }
      return LessonPlayerScreen(
        course: course,
        initialLesson: lesson,
        mode: mode,
      );
    },
  ),
  GoRoute(
    path: AppRoute.publicTeacherProfile.path,
    name: AppRoute.publicTeacherProfile.name,
    builder: (context, state) {
      final teacher = state.extra as TeacherModel?;
      return PublicTeacherProfileScreen(teacher: teacher);
    },
  ),
  GoRoute(
    path: AppRoute.instructors.path,
    name: AppRoute.instructors.name,
    builder: (context, state) => const InstructorsScreen(),
  ),
  GoRoute(
    path: AppRoute.studentLiveClasses.path,
    name: AppRoute.studentLiveClasses.name,
    builder: (context, state) => AppConfig.isSupabaseEnabled
        ? const LiveMeetingsScreen()
        : const StudentLiveClassesScreen(),
  ),
  GoRoute(
    path: AppRoute.studentAssignment.path,
    name: AppRoute.studentAssignment.name,
    builder: (context, state) {
      final assignment = state.extra as AssignmentModel?;
      final assignmentId = state.uri.queryParameters['assignmentId'];
      if (assignment == null && assignmentId != null) {
        return NotificationAssignmentPage(assignmentId: assignmentId);
      }
      return StudentAssignmentScreen(assignment: assignment);
    },
  ),
];

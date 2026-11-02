enum AppRoute {
  splash,
  onboarding1,
  onboarding2,
  onboarding3,
  onboarding4,
  onboarding5,
  onboarding6,
  welcomeRole,
  welcome,
  login,
  signup,
  forgotPassword,
  resetPassword,
  main,
  accountSettings,
  editProfile,
  appLanguage,
  generateAiQuiz,
  activeQuiz,
  quizCompleted,
  courseCertificate,
  quizReview,
  deleteAccount,
  paymentMethods,
  addPaymentMethod,
  addCard,
  addWallet,
  notifications,
  notificationInbox,
  aboutUs,
  termsOfService,
  privacyPolicy,
  rateApp,
  testAlerts,
  // New Student Learning Routes
  courseDetail,
  categoryCourses,
  newCourses,
  courseSearch,
  courseEnroll,
  lessonPlayer,
  videoFullscreen,
  offlineDownloads,
  offlineLesson,
  lessonReading,
  publicTeacherProfile,
  instructors,
  studentLiveClasses,
  studentAssignment,
  // New Teacher Routes
  teacherWelcome,
  teacherLogin,
  teacherSignup,
  teacherMain,
  teacherCreateCourse,
  teacherCreateLesson,
  teacherCreateQuiz,
  teacherQuizQuestion,
  teacherAnalytics,
  teacherManageCourse,
  teacherLessonMedia,
  teacherLessonActivities,
  curriculumResources,
  teacherCourseAssignments,
  teacherCreateAssignment,
  teacherReviewAssignment,
  teacherDoubts,
  teacherLiveClasses,
  teacherStudents,
  teacherPayouts,
  teacherQuizStudio,
  teacherQuizAnalysis,
  teacherAssessmentList,
}

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.splash:
        return '/';
      case AppRoute.onboarding1:
        return '/o1';
      case AppRoute.onboarding2:
        return '/o2';
      case AppRoute.onboarding3:
        return '/o3';
      case AppRoute.onboarding4:
        return '/o4';
      case AppRoute.onboarding5:
        return '/o5';
      case AppRoute.onboarding6:
        return '/o6';
      case AppRoute.welcomeRole:
        return '/welcome_role';
      case AppRoute.welcome:
        return '/welcome';
      case AppRoute.login:
        return '/login';
      case AppRoute.signup:
        return '/signup';
      case AppRoute.forgotPassword:
        return '/forgot_password';
      case AppRoute.resetPassword:
        return '/reset_password';
      case AppRoute.main:
        return '/main';
      case AppRoute.accountSettings:
        return '/account_settings';
      case AppRoute.editProfile:
        return '/edit_profile';
      case AppRoute.appLanguage:
        return '/app_language';
      case AppRoute.generateAiQuiz:
        return '/generate_ai_quiz';
      case AppRoute.activeQuiz:
        return '/active_quiz';
      case AppRoute.courseCertificate:
        return '/course_certificate';
      case AppRoute.quizCompleted:
        return '/quiz_completed';
      case AppRoute.quizReview:
        return '/quiz_review';
      case AppRoute.deleteAccount:
        return '/delete_account';
      case AppRoute.paymentMethods:
        return '/payment_methods';
      case AppRoute.addPaymentMethod:
        return '/add_payment_method';
      case AppRoute.addCard:
        return '/add_card';
      case AppRoute.addWallet:
        return '/add_wallet';
      case AppRoute.notifications:
        return '/notifications';
      case AppRoute.notificationInbox:
        return '/notification_inbox';
      case AppRoute.aboutUs:
        return '/about_us';
      case AppRoute.termsOfService:
        return '/terms_of_service';
      case AppRoute.privacyPolicy:
        return '/privacy_policy';
      case AppRoute.rateApp:
        return '/rate_app';
      case AppRoute.testAlerts:
        return '/test_alerts';
      case AppRoute.courseDetail:
        return '/course_detail';
      case AppRoute.categoryCourses:
        return '/category_courses';
      case AppRoute.newCourses:
        return '/new_courses';
      case AppRoute.courseSearch:
        return '/course_search';
      case AppRoute.courseEnroll:
        return '/course_enroll';
      case AppRoute.lessonPlayer:
        return '/lesson_player';
      case AppRoute.videoFullscreen:
        return '/video_fullscreen';
      case AppRoute.offlineDownloads:
        return '/offline_downloads';
      case AppRoute.lessonReading:
        return '/lesson_reading';
      case AppRoute.offlineLesson:
        return '/offline_lesson';
      case AppRoute.publicTeacherProfile:
        return '/public_teacher_profile';
      case AppRoute.instructors:
        return '/instructors';
      case AppRoute.studentLiveClasses:
        return '/student_live_classes';
      case AppRoute.studentAssignment:
        return '/student_assignment';
      case AppRoute.teacherWelcome:
        return '/teacher_welcome';
      case AppRoute.teacherLogin:
        return '/teacher_login';
      case AppRoute.teacherSignup:
        return '/teacher_signup';
      case AppRoute.teacherMain:
        return '/teacher_main';
      case AppRoute.teacherCreateCourse:
        return '/teacher_create_course';
      case AppRoute.teacherCreateLesson:
        return '/teacher_create_lesson';
      case AppRoute.teacherCreateQuiz:
        return '/teacher_create_quiz';
      case AppRoute.teacherQuizQuestion:
        return '/teacher_quiz_question';
      case AppRoute.teacherAnalytics:
        return '/teacher_analytics';
      case AppRoute.teacherManageCourse:
        return '/teacher_manage_course';
      case AppRoute.teacherLessonActivities:
        return '/teacher_lesson_activities';
      case AppRoute.teacherLessonMedia:
        return '/teacher_lesson_media';
      case AppRoute.curriculumResources:
        return '/curriculum_resources';
      case AppRoute.teacherCourseAssignments:
        return '/teacher_course_assignments';
      case AppRoute.teacherCreateAssignment:
        return '/teacher_create_assignment';
      case AppRoute.teacherReviewAssignment:
        return '/teacher_review_assignment';
      case AppRoute.teacherDoubts:
        return '/teacher_doubts';
      case AppRoute.teacherLiveClasses:
        return '/teacher_live_classes';
      case AppRoute.teacherStudents:
        return '/teacher_students';
      case AppRoute.teacherPayouts:
        return '/teacher_payouts';
      case AppRoute.teacherQuizStudio:
        return '/teacher_quiz_studio';
      case AppRoute.teacherQuizAnalysis:
        return '/teacher_quiz_analysis';
      case AppRoute.teacherAssessmentList:
        return '/teacher_assessment_list';
    }
  }
}

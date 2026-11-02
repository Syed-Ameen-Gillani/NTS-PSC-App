import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_lesson_activities_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_reading_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/instructors_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/course_certificate_screen.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/assessment_creation_request.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_resources_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/student_assignment_screen.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_course_assignments_screen.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_create_assignment_screen.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_review_assignment_screen.dart';
import 'package:nts_psc_app/features/splash/splash_screen.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_4.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_6.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/welcome_role_screen.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/login_page.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/teacher_welcome_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/teacher_signup_screen.dart';
import 'package:nts_psc_app/features/authentication/presentation/pages/signup_create_account_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:nts_psc_app/features/main/presentation/pages/main_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_detail_screen.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/category_courses_screen.dart';
import 'package:nts_psc_app/features/discover/presentation/pages/course_search_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_player_screen.dart';
import 'package:nts_psc_app/features/learn/domain/lesson_player_mode.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/video_fullscreen_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/offline_downloads_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/offline_lesson_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/app_language_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_generate_ai_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/active_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_completed_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_review_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/delete_account_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/payment_methods_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_payment_method_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_card_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_wallet_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/notifications_screen.dart';
import 'package:nts_psc_app/features/notifications/presentation/pages/notification_inbox_screen.dart';
import 'package:nts_psc_app/features/notifications/presentation/pages/notification_resource_pages.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/about_us_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/terms_of_service_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/privacy_policy_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/rate_app_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_main_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_course_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_lesson_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_quiz_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_question_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_analytics_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_manage_course_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_lesson_media_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_doubts_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_live_classes_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_students_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_payouts_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_analysis_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_assessment_list_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/public_teacher_profile_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/new_courses_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/student_live_classes_screen.dart';
import 'package:nts_psc_app/presentation/pages/test_alerts_screen.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/feature_unavailable.dart';
import 'package:nts_psc_app/features/live_classes/presentation/live_meetings_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/reset_password_screen.dart';

part 'student_routes.dart';
part 'teacher_routes.dart';
part 'assessment_profile_routes.dart';

final _teacherOnlyPaths = {
  AppRoute.teacherMain.path,
  AppRoute.teacherCreateCourse.path,
  AppRoute.teacherCreateLesson.path,
  AppRoute.teacherCreateQuiz.path,
  AppRoute.teacherQuizQuestion.path,
  AppRoute.teacherAnalytics.path,
  AppRoute.teacherManageCourse.path,
  AppRoute.teacherLessonMedia.path,
  AppRoute.teacherLessonActivities.path,
  AppRoute.teacherCourseAssignments.path,
  AppRoute.teacherCreateAssignment.path,
  AppRoute.teacherReviewAssignment.path,
  AppRoute.teacherDoubts.path,
  AppRoute.teacherLiveClasses.path,
  AppRoute.teacherStudents.path,
  AppRoute.teacherPayouts.path,
  AppRoute.teacherQuizStudio.path,
  AppRoute.teacherQuizAnalysis.path,
  AppRoute.teacherAssessmentList.path,
  AppRoute.generateAiQuiz.path,
};

final _signedInPaths = {
  AppRoute.curriculumResources.path,
  AppRoute.accountSettings.path,
  AppRoute.editProfile.path,
  AppRoute.deleteAccount.path,
  AppRoute.lessonPlayer.path,
  AppRoute.lessonReading.path,
  AppRoute.offlineDownloads.path,
  AppRoute.offlineLesson.path,
  AppRoute.studentAssignment.path,
  AppRoute.notificationInbox.path,
};

final appRouter = GoRouter(
  initialLocation: AppConfig.restoredRole == UserRole.teacher
      ? AppRoute.teacherMain.path
      : AppConfig.restoredRole == UserRole.student
      ? AppRoute.main.path
      : AppRoute.welcomeRole.path,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == AppRoute.splash.path) {
      return AppConfig.restoredRole == UserRole.teacher
          ? AppRoute.teacherMain.path
          : AppConfig.restoredRole == UserRole.student
          ? AppRoute.main.path
          : AppRoute.welcomeRole.path;
    }
    if (!AppConfig.isSupabaseEnabled) return null;
    if (path == AppRoute.offlineDownloads.path ||
        path == AppRoute.offlineLesson.path) {
      return Supabase.instance.client.auth.currentUser == null
          ? AppRoute.login.path
          : null;
    }
    if (_teacherOnlyPaths.contains(path) &&
        AppConfig.restoredRole != UserRole.teacher) {
      return AppRoute.teacherLogin.path;
    }
    if (_signedInPaths.contains(path) && AppConfig.restoredRole == null) {
      return AppRoute.login.path;
    }
    return null;
  },
  routes: [
    ..._studentRoutes(),
    ..._teacherRoutes(),
    ..._assessmentProfileRoutes(),
  ],
);

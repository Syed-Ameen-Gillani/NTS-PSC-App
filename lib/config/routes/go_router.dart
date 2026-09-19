import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
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
import 'package:nts_psc_app/features/learn/presentation/pages/lesson_player_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/app_language_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/generate_ai_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_ready_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/active_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_completed_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_review_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/delete_account_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/payment_methods_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_payment_method_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_card_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/add_wallet_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/notifications_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/about_us_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/terms_of_service_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/privacy_policy_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/rate_app_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_main_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_course_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_quiz_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_analytics_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_manage_course_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_doubts_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_live_classes_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_students_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_payouts_screen.dart';
import 'package:nts_psc_app/features/home/presentation/pages/public_teacher_profile_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/student_live_classes_screen.dart';
import 'package:nts_psc_app/presentation/pages/test_alerts_screen.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoute.welcomeRole.path,
  routes: [
    GoRoute(path: AppRoute.splash.path, name: AppRoute.splash.name, builder: (context, state) => const SplashScreen()),
    
    // --- ONBOARDING FLOW ---
    GoRoute(path: AppRoute.onboarding1.path, name: AppRoute.onboarding1.name, builder: (context, state) => const OnboardingScreen1()),
    GoRoute(path: AppRoute.onboarding2.path, name: AppRoute.onboarding2.name, builder: (context, state) => const OnboardingScreen2()),
    GoRoute(path: AppRoute.onboarding3.path, name: AppRoute.onboarding3.name, builder: (context, state) => const OnboardingScreen3()),
    GoRoute(path: AppRoute.onboarding4.path, name: AppRoute.onboarding4.name, builder: (context, state) => const OnboardingScreen4()),
    GoRoute(path: AppRoute.onboarding5.path, name: AppRoute.onboarding5.name, builder: (context, state) => const OnboardingScreen5()),
    GoRoute(path: AppRoute.onboarding6.path, name: AppRoute.onboarding6.name, builder: (context, state) => const OnboardingScreen6()),
    
    // --- ROLE SELECTION & ONBOARDING ---
    GoRoute(path: AppRoute.welcomeRole.path, name: AppRoute.welcomeRole.name, builder: (context, state) => const WelcomeRoleScreen()),
    GoRoute(path: AppRoute.welcome.path, name: AppRoute.welcome.name, builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: AppRoute.teacherWelcome.path, name: AppRoute.teacherWelcome.name, builder: (context, state) => const TeacherWelcomeScreen()),

    // --- AUTHENTICATION ---
    GoRoute(path: AppRoute.login.path, name: AppRoute.login.name, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppRoute.teacherLogin.path, name: AppRoute.teacherLogin.name, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppRoute.signup.path, name: AppRoute.signup.name, builder: (context, state) => const SignupCreateAccountScreen()),
    GoRoute(path: AppRoute.teacherSignup.path, name: AppRoute.teacherSignup.name, builder: (context, state) => const TeacherSignupScreen()),
    GoRoute(path: AppRoute.forgotPassword.path, name: AppRoute.forgotPassword.name, builder: (context, state) => const ForgotPasswordScreen()),

    // --- STUDENT SHELL & LEARNING FLOW ---
    GoRoute(path: AppRoute.main.path, name: AppRoute.main.name, builder: (context, state) => const MainScreen()),
    GoRoute(
      path: AppRoute.courseDetail.path,
      name: AppRoute.courseDetail.name,
      builder: (context, state) {
        final course = state.extra as CourseModel?;
        return CourseDetailScreen(course: course);
      },
    ),
    GoRoute(
      path: AppRoute.lessonPlayer.path,
      name: AppRoute.lessonPlayer.name,
      builder: (context, state) {
        final map = state.extra as Map<String, dynamic>?;
        final course = map?['course'] as CourseModel?;
        final lesson = map?['lesson'] as LessonModel?;
        return LessonPlayerScreen(course: course, initialLesson: lesson);
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
      path: AppRoute.studentLiveClasses.path,
      name: AppRoute.studentLiveClasses.name,
      builder: (context, state) => const StudentLiveClassesScreen(),
    ),

    // --- TEACHER SHELL & STUDIO FLOW ---
    GoRoute(path: AppRoute.teacherMain.path, name: AppRoute.teacherMain.name, builder: (context, state) => const TeacherMainScreen()),
    GoRoute(path: AppRoute.teacherCreateCourse.path, name: AppRoute.teacherCreateCourse.name, builder: (context, state) => const TeacherCreateCourseScreen()),
    GoRoute(path: AppRoute.teacherCreateQuiz.path, name: AppRoute.teacherCreateQuiz.name, builder: (context, state) => const TeacherCreateQuizScreen()),
    GoRoute(path: AppRoute.teacherAnalytics.path, name: AppRoute.teacherAnalytics.name, builder: (context, state) => const TeacherAnalyticsScreen()),
    GoRoute(
      path: AppRoute.teacherManageCourse.path,
      name: AppRoute.teacherManageCourse.name,
      builder: (context, state) {
        final course = state.extra as CourseModel;
        return TeacherManageCourseScreen(course: course);
      },
    ),
    GoRoute(path: AppRoute.teacherDoubts.path, name: AppRoute.teacherDoubts.name, builder: (context, state) => const TeacherDoubtsScreen()),
    GoRoute(path: AppRoute.teacherLiveClasses.path, name: AppRoute.teacherLiveClasses.name, builder: (context, state) => const TeacherLiveClassesScreen()),
    GoRoute(path: AppRoute.teacherStudents.path, name: AppRoute.teacherStudents.name, builder: (context, state) => TeacherStudentsScreen(initialCourseTitle: state.extra as String?)),
    GoRoute(path: AppRoute.teacherPayouts.path, name: AppRoute.teacherPayouts.name, builder: (context, state) => const TeacherPayoutsScreen()),

    // --- QUIZZES & ASSESSMENTS ---
    GoRoute(path: AppRoute.generateAiQuiz.path, name: AppRoute.generateAiQuiz.name, builder: (context, state) => const GenerateAiQuizScreen()),
    GoRoute(path: AppRoute.quizReady.path, name: AppRoute.quizReady.name, builder: (context, state) => const QuizReadyScreen()),
    GoRoute(
      path: AppRoute.activeQuiz.path,
      name: AppRoute.activeQuiz.name,
      builder: (context, state) {
        final quiz = state.extra as QuizModel?;
        return ActiveQuizScreen(quiz: quiz);
      },
    ),
    GoRoute(
      path: AppRoute.quizCompleted.path,
      name: AppRoute.quizCompleted.name,
      builder: (context, state) {
        final result = state.extra as QuizSubmissionResultModel?;
        return QuizCompletedScreen(result: result);
      },
    ),
    GoRoute(
      path: AppRoute.quizReview.path,
      name: AppRoute.quizReview.name,
      builder: (context, state) {
        final result = state.extra as QuizSubmissionResultModel?;
        return QuizReviewScreen(result: result);
      },
    ),

    // --- PROFILE & SETTINGS ---
    GoRoute(path: AppRoute.accountSettings.path, name: AppRoute.accountSettings.name, builder: (context, state) => const AccountSettingsScreen()),
    GoRoute(path: AppRoute.editProfile.path, name: AppRoute.editProfile.name, builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: AppRoute.appLanguage.path, name: AppRoute.appLanguage.name, builder: (context, state) => const AppLanguageScreen()),
    GoRoute(path: AppRoute.deleteAccount.path, name: AppRoute.deleteAccount.name, builder: (context, state) => const DeleteAccountScreen()),
    GoRoute(path: AppRoute.paymentMethods.path, name: AppRoute.paymentMethods.name, builder: (context, state) => const PaymentMethodsScreen()),
    GoRoute(path: AppRoute.addPaymentMethod.path, name: AppRoute.addPaymentMethod.name, builder: (context, state) => const AddPaymentMethodScreen()),
    GoRoute(path: AppRoute.addCard.path, name: AppRoute.addCard.name, builder: (context, state) => const AddCardScreen()),
    GoRoute(
      path: AppRoute.addWallet.path,
      name: AppRoute.addWallet.name,
      builder: (context, state) {
        final walletType = state.extra as WalletType? ?? WalletType.easypaisa;
        return AddWalletScreen(walletType: walletType);
      },
    ),
    GoRoute(path: AppRoute.notifications.path, name: AppRoute.notifications.name, builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: AppRoute.aboutUs.path, name: AppRoute.aboutUs.name, builder: (context, state) => const AboutUsScreen()),
    GoRoute(path: AppRoute.termsOfService.path, name: AppRoute.termsOfService.name, builder: (context, state) => const TermsOfServiceScreen()),
    GoRoute(path: AppRoute.privacyPolicy.path, name: AppRoute.privacyPolicy.name, builder: (context, state) => const PrivacyPolicyScreen()),
    GoRoute(path: AppRoute.rateApp.path, name: AppRoute.rateApp.name, builder: (context, state) => const RateAppScreen()),
    GoRoute(path: AppRoute.testAlerts.path, name: AppRoute.testAlerts.name, builder: (context, state) => const TestAlertsScreen()),
  ],
);
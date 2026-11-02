part of 'go_router.dart';

List<RouteBase> _assessmentProfileRoutes() => [
  // --- QUIZZES & ASSESSMENTS ---
  GoRoute(
    path: AppRoute.courseCertificate.path,
    name: AppRoute.courseCertificate.name,
    builder: (context, state) => CourseCertificateScreen(
      courseId: state.uri.queryParameters['courseId'] ?? '',
    ),
  ),
  GoRoute(
    path: AppRoute.generateAiQuiz.path,
    name: AppRoute.generateAiQuiz.name,
    builder: (context, state) => const TeacherGenerateAiQuizScreen(),
  ),
  GoRoute(
    path: AppRoute.activeQuiz.path,
    name: AppRoute.activeQuiz.name,
    builder: (context, state) {
      final quiz = state.extra as QuizModel?;
      final quizId = state.uri.queryParameters['quizId'];
      if (quiz == null && quizId != null) {
        return NotificationQuizPage(quizId: quizId);
      }
      return ActiveQuizScreen(quiz: quiz);
    },
  ),
  GoRoute(
    path: AppRoute.quizCompleted.path,
    name: AppRoute.quizCompleted.name,
    builder: (context, state) {
      final result = state.extra as QuizSubmissionResultModel?;
      return QuizCompletedScreen(
        result: result,
        attemptId: state.uri.queryParameters['attemptId'],
      );
    },
  ),
  GoRoute(
    path: AppRoute.quizReview.path,
    name: AppRoute.quizReview.name,
    builder: (context, state) {
      final result = state.extra as QuizSubmissionResultModel?;
      return QuizReviewScreen(
        result: result,
        attemptId: state.uri.queryParameters['attemptId'],
      );
    },
  ),

  // --- PROFILE & SETTINGS ---
  GoRoute(
    path: AppRoute.accountSettings.path,
    name: AppRoute.accountSettings.name,
    builder: (context, state) => const AccountSettingsScreen(),
  ),
  GoRoute(
    path: AppRoute.editProfile.path,
    name: AppRoute.editProfile.name,
    builder: (context, state) => const EditProfileScreen(),
  ),
  GoRoute(
    path: AppRoute.appLanguage.path,
    name: AppRoute.appLanguage.name,
    builder: (context, state) => const AppLanguageScreen(),
  ),
  GoRoute(
    path: AppRoute.deleteAccount.path,
    name: AppRoute.deleteAccount.name,
    builder: (context, state) => const DeleteAccountScreen(),
  ),
  GoRoute(
    path: AppRoute.paymentMethods.path,
    name: AppRoute.paymentMethods.name,
    builder: (context, state) => const PaymentMethodsScreen(),
  ),
  GoRoute(
    path: AppRoute.addPaymentMethod.path,
    name: AppRoute.addPaymentMethod.name,
    builder: (context, state) => const AddPaymentMethodScreen(),
  ),
  GoRoute(
    path: AppRoute.addCard.path,
    name: AppRoute.addCard.name,
    builder: (context, state) => const AddCardScreen(),
  ),
  GoRoute(
    path: AppRoute.addWallet.path,
    name: AppRoute.addWallet.name,
    builder: (context, state) {
      final walletType = state.extra as WalletType? ?? WalletType.easypaisa;
      return AddWalletScreen(walletType: walletType);
    },
  ),
  GoRoute(
    path: AppRoute.notifications.path,
    name: AppRoute.notifications.name,
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: AppRoute.notificationInbox.path,
    name: AppRoute.notificationInbox.name,
    builder: (context, state) => const NotificationInboxScreen(),
  ),
  GoRoute(
    path: AppRoute.aboutUs.path,
    name: AppRoute.aboutUs.name,
    builder: (context, state) => const AboutUsScreen(),
  ),
  GoRoute(
    path: AppRoute.termsOfService.path,
    name: AppRoute.termsOfService.name,
    builder: (context, state) => const TermsOfServiceScreen(),
  ),
  GoRoute(
    path: AppRoute.privacyPolicy.path,
    name: AppRoute.privacyPolicy.name,
    builder: (context, state) => const PrivacyPolicyScreen(),
  ),
  GoRoute(
    path: AppRoute.rateApp.path,
    name: AppRoute.rateApp.name,
    builder: (context, state) => const RateAppScreen(),
  ),
  GoRoute(
    path: AppRoute.testAlerts.path,
    name: AppRoute.testAlerts.name,
    builder: (context, state) => const TestAlertsScreen(),
  ),
];

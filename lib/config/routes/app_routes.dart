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
  main,
  accountSettings,
  editProfile,
  appLanguage,
  generateAiQuiz,
  quizReady,
  activeQuiz,
  quizCompleted,
  deleteAccount,
  paymentMethods,
  addPaymentMethod,
  addCard,
  addWallet,
  notifications,
  aboutUs,
  termsOfService,
  privacyPolicy,
  rateApp,
  testAlerts,
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
      case AppRoute.quizReady:
        return '/quiz_ready';
      case AppRoute.activeQuiz:
        return '/active_quiz';
      case AppRoute.quizCompleted:
        return '/quiz_completed';
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
    }
  }
}

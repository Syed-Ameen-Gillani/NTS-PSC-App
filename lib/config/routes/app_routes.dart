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
    }
  }
}

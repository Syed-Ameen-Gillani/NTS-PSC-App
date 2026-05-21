
import 'package:go_router/go_router.dart';
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
import 'package:nts_psc_app/features/authentication/presentation/pages/signup_create_account_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoute.welcome.path,
  routes: [
    GoRoute(path: AppRoute.splash.path, name: AppRoute.splash.name, builder: (context, state) => const SplashScreen()),
    
    // --- ONBOARDING FLOW ---
    GoRoute(path: AppRoute.onboarding1.path, name: AppRoute.onboarding1.name, builder: (context, state) => const OnboardingScreen1()),
    GoRoute(path: AppRoute.onboarding2.path, name: AppRoute.onboarding2.name, builder: (context, state) => const OnboardingScreen2()),
    GoRoute(path: AppRoute.onboarding3.path, name: AppRoute.onboarding3.name, builder: (context, state) => const OnboardingScreen3()),
    GoRoute(path: AppRoute.onboarding4.path, name: AppRoute.onboarding4.name, builder: (context, state) => const OnboardingScreen4()),
    GoRoute(path: AppRoute.onboarding5.path, name: AppRoute.onboarding5.name, builder: (context, state) => const OnboardingScreen5()),
    GoRoute(path: AppRoute.onboarding6.path, name: AppRoute.onboarding6.name, builder: (context, state) => const OnboardingScreen6()),
    
    
    // --- FINAL SCREEN ---
    GoRoute(path: AppRoute.welcomeRole.path, name: AppRoute.welcomeRole.name, builder: (context, state) => const WelcomeRoleScreen()),
    GoRoute(path: AppRoute.welcome.path, name: AppRoute.welcome.name, builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: AppRoute.login.path, name: AppRoute.login.name, builder: (context, state) => const LoginPage()),
    GoRoute(path: AppRoute.signup.path, name: AppRoute.signup.name, builder: (context, state) => const SignupCreateAccountScreen()),
    GoRoute(path: AppRoute.forgotPassword.path, name: AppRoute.forgotPassword.name, builder: (context, state) => const ForgotPasswordScreen()),
  ],
);
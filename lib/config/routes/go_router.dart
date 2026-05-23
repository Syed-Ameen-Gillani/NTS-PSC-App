
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
import 'package:nts_psc_app/features/main/presentation/pages/main_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/app_language_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/generate_ai_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_ready_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/active_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_completed_screen.dart';
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
import 'package:nts_psc_app/presentation/pages/test_alerts_screen.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoute.testAlerts.path,
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
    GoRoute(path: AppRoute.main.path, name: AppRoute.main.name, builder: (context, state) => const MainScreen()),
    GoRoute(path: AppRoute.accountSettings.path, name: AppRoute.accountSettings.name, builder: (context, state) => const AccountSettingsScreen()),
    GoRoute(path: AppRoute.editProfile.path, name: AppRoute.editProfile.name, builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: AppRoute.appLanguage.path, name: AppRoute.appLanguage.name, builder: (context, state) => const AppLanguageScreen()),
    GoRoute(path: AppRoute.generateAiQuiz.path, name: AppRoute.generateAiQuiz.name, builder: (context, state) => const GenerateAiQuizScreen()),
    GoRoute(path: AppRoute.quizReady.path, name: AppRoute.quizReady.name, builder: (context, state) => const QuizReadyScreen()),
    GoRoute(path: AppRoute.activeQuiz.path, name: AppRoute.activeQuiz.name, builder: (context, state) => const ActiveQuizScreen()),
    GoRoute(path: AppRoute.quizCompleted.path, name: AppRoute.quizCompleted.name, builder: (context, state) => const QuizCompletedScreen()),
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
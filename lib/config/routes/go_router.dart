
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/features/splash/splash_screen.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_2.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_3.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_4.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_5.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen_6.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/welcome_role_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    
    // --- ONBOARDING FLOW ---
    GoRoute(path: '/o1', builder: (context, state) => const OnboardingScreen1()),
    GoRoute(path: '/o2', builder: (context, state) => const OnboardingScreen2()),
    GoRoute(path: '/o3', builder: (context, state) => const OnboardingScreen3()),
    GoRoute(path: '/o4', builder: (context, state) => const OnboardingScreen4()),
    GoRoute(path: '/o5', builder: (context, state) => const OnboardingScreen5()),
    GoRoute(path: '/o6', builder: (context, state) => const OnboardingScreen6()),
    
    
    // --- FINAL SCREEN ---
    GoRoute(path: '/welcome_role', builder: (context, state) => const WelcomeRoleScreen()),
  ],
);
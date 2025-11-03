import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/onboarding_screen.dart'; // We'll create this next!

// GoRouter instance
final appRouter = GoRouter(
  // The initial location/path the app starts at
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      // The screen/widget to show when navigating to '/'
      builder: (context, state) => const OnboardingScreen(),
    ),
    // will add other routes here later (e.g '/home', '/login')
  ],
);
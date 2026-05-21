# Onboarding Feature

## Feature Name
Onboarding & Initialization

## Purpose
Handles the initial app launch sequence. This includes the Splash screen initialization, a 6-step educational walkthrough for new users, role selection, and the primary Welcome screen directing users to Login, Signup, or Guest Access.

## Screens Included
- `SplashScreen` (`lib/features/splash/splash_screen.dart`)
- `OnboardingScreen1` to `OnboardingScreen6` (`lib/features/onboarding/presentation/screens/`)
- `WelcomeRoleScreen` (`lib/features/onboarding/presentation/screens/welcome_role_screen.dart`)
- `WelcomeScreen` (`lib/features/onboarding/presentation/screens/welcome_screen.dart`)

## User Flow
1. App boots into `SplashScreen`.
2. Evaluates if the user is first-time. If yes -> `OnboardingScreen1`. (Currently hardcoded for testing).
3. User progresses through 6 onboarding slides.
4. User lands on `WelcomeRoleScreen` (Currently bypassed/navigated to Welcome in some flows).
5. User lands on `WelcomeScreen` where they choose "Create Account", "Log In", or "Explore Courses as Guest".

## APIs Used
- *None currently implemented. Local asset loading only.*

## State Management Used
- Riverpod (Providers will be utilized to track `hasSeenOnboarding` in local storage in the future).

## Important Business Logic
- The `WelcomeScreen` dynamically resizes to prevent flex overflows. The top image uses `0.45.sh` height constraint, and a single flexible `Spacer()` pushes the buttons to the bottom, ensuring it renders perfectly on both small and large devices without requiring a scroll view.

## Reusable Widgets/Components Involved
- `CustomButton`: For primary actions (Next, Create Account).
- `OutlinedButton`: Styled dynamically for "Log In" and guest options.

## Navigation Flow
- Controlled via `GoRouter` using the `AppRoute` enum. 
- `SplashScreen` -> `Onboarding` -> `WelcomeScreen`.
- `WelcomeScreen` -> `AppRoute.login` or `AppRoute.signup`.

## Limitations/TODOs
- Hook up local storage (SharedPreferences / Hive) to bypass onboarding if the user has already seen it.
- Integrate the `WelcomeRoleScreen` properly into the flow when the user hits "Create Account".

## Dependencies/Packages Used
- `go_router`: Named routing.
- `flutter_screenutil`: Precise, responsive layout dimensions (`.h`, `.w`).
- `flutter_svg`: Rendering vector assets.

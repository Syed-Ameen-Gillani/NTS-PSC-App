# Auth Feature

## Feature Name
Authentication (Login & Signup)

## Purpose
Manages user identity, registration, and login. Includes beautifully styled, pixel-perfect UI screens matching the Figma design system, offering email/password authentication as well as social SSO (Google, Apple).

## Screens Included
- `LoginPage` (`lib/features/auth/presentation/pages/login_page.dart`)
- `SignupCreateAccountScreen` (`lib/features/authentication/presentation/pages/signup_create_account_screen.dart`)
- `RegistrationSuccessModal` (`lib/features/authentication/presentation/pages/registration_success_modal.dart`)

## User Flow
1. From `WelcomeScreen`, user taps "Create Account" -> `SignupCreateAccountScreen`.
2. From `WelcomeScreen`, user taps "Log In" -> `LoginPage`.
3. Users can toggle freely between Login and Signup via footer links (using `pushReplacement` to avoid stack bloat).
4. Users fill in their details or tap social SSO buttons.

## APIs Used
- *Pending backend integration (Firebase/Supabase).*

## State Management Used
- Ready for Riverpod integration to manage form states and auth tokens.

## Important Business Logic
- **Routing Protection**: The footer links use `context.pushReplacementNamed()` instead of standard `.push()` to ensure users don't build up a massive navigation history stack by tapping back and forth between Login and Signup.

## Reusable Widgets/Components Involved
- `CustomTextFormField`: Highly customized input field. We completely stripped fixed heights from this widget, allowing it to size intrinsically. Default padding (`vertical: 18.h`, `horizontal: 16.w`), border radii (`24.r`), and specific hex colors (`AppColors.grey100` background, `AppColors.grey300` border) are baked directly into the widget to strictly enforce design system consistency.
- `CustomButton`: Used for primary actions (Sign Up / Log In). Fixed to a default height of `68.0`.

## Navigation Flow
- `AppRoute.login` <-> `AppRoute.signup`.

## Limitations/TODOs
- Implement form validation logic (email regex, password strength).
- Hook up Google and Apple SSO SDKs.
- Implement API calls to register/authenticate the user and store JWTs.
- Navigate to Home/Dashboard upon successful auth.

## Dependencies/Packages Used
- `go_router`: Named routing.
- `flutter_screenutil`: Precise, responsive layout dimensions (`.h`, `.w`).
- `flutter_svg`: Rendering social icons.

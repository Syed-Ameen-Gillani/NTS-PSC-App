# Forgot Password Feature

## Feature Name
Forgot Password / Password Recovery

## Purpose
Allows users who have forgotten their password to request a password reset link sent to their registered email address. This screen seamlessly matches the aesthetic constraints of the Login/Signup flow.

## Screens Included
- `ForgotPasswordScreen` (`lib/features/auth/presentation/pages/forgot_password_screen.dart`)

## User Flow
1. From `LoginPage`, user taps "Forgot password?" text.
2. Navigates via `context.pushNamed` to `ForgotPasswordScreen`.
3. User is presented with a standard AppBar with a back button (to return to login), a title, instructions, and an email input field.
4. User enters email and taps "Send Reset Link".
5. A green `SnackBar` confirms the link was sent.
6. After a 2-second delay, the user is automatically navigated back to the Login screen via `context.pop()`.

## APIs Used
- *Pending backend integration to trigger actual password reset email.*

## State Management Used
- Ready for Riverpod (Notifiers) to manage loading states when the API is implemented.

## Important Business Logic
- **Automatic Navigation**: Implements `Future.delayed` to pause briefly after success before popping the screen, allowing the user enough time to see the success SnackBar.

## Reusable Widgets/Components Involved
- `CustomTextFormField`: Reused for the email input. Uses the newly established padding (`top/bottom: 16.h`, `left: 44.w`, `right: 16.w`), border radii (`16.r`), and hint styling matching the `grey400` prefix icon.
- `CustomButton`: Reused for the primary "Send Reset Link" action.

## Navigation Flow
- `AppRoute.login` -> `AppRoute.forgotPassword` -> `context.pop()`.

## Limitations/TODOs
- Implement actual form validation for the email field before allowing submission.
- Hook up backend API to send the reset email.
- Show a loading indicator in the `CustomButton` during the network request.

## Dependencies/Packages Used
- `go_router`: Named routing.
- `flutter_screenutil`: Precise, responsive layout dimensions (`.h`, `.w`).

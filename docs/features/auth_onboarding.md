# Auth & Onboarding Feature Memory

## Overview
The Authentication and Onboarding modules act as the entry point to the application, providing role selection, app introductions, and secure sign-up/login functionality. State is managed by Riverpod (`authControllerProvider`).

## Screens & Components

### Onboarding Flow
1. **Splash Screen (`splash_screen.dart`)**
   - Displays the central App Logo (`AppAssets.appLogo`).
   - Sizing is fully responsive utilizing `flutter_screenutil` (`200.w`).

2. **Welcome & Role Selection (`welcome_screen.dart`, `welcome_role_screen.dart`)**
   - Introduces the user to the platform.
   - Allows users to select their persona (e.g., Student, Teacher, etc.) before proceeding into the specific onboarding carousel.

3. **Onboarding Carousel (`onboarding_screen_1.dart` through `6.dart`)**
   - A sequential series of screens detailing features and value propositions.
   - Designed to be visually engaging using custom graphics and robust typography.

### Authentication Flow
1. **Signup / Create Account (`signup_create_account_screen.dart`)**
   - Collects Full Name, Email Address, and Password.
   - Utilizes `CustomTextFormField` with internal `FormValidators` to ensure robust data entry constraints (e.g., > 8 char password).
   - Integrates Social Sign-up stubs (Google, Apple).
   - Employs a `CustomToast` to deliver a "Welcome" success message upon account creation.

2. **Forgot Password (`forgot_password_screen.dart`)**
   - Captures email input to dispatch password reset instructions.
   - On success, triggers a `CustomSnackBar` (`CustomSnackBar.showSuccess`) to inform the user that a link was dispatched, replacing generic inline Snackbars.

## Design Patterns
- Both modules heavily rely on `AppTextStyles` for `Inter` font rendering.
- `CustomButton` and `CustomTextFormField` are standard reusable blocks utilized exclusively here to eliminate boilerplate code and retain standard border radii, padding, and disabled states.

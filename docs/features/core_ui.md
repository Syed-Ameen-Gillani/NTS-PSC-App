# Core UI & Infrastructure Memory

## Overview
The Core UI module defines the foundational visual language, responsiveness strategy, and reusable global utility widgets for the NTS-PSC-App. It ensures consistency across all feature modules.

## Theming (`lib/core/theme/`)
1. **AppColors (`app_colors.dart`)**
   - Centralized repository for all hex color codes.
   - Includes primary brand colors, background colors, typography colors (e.g., `AppColors.onBackground`), and utility states (e.g., Error reds, Success greens).

2. **AppTextStyles (`app_text_styles.dart`)**
   - Implements the `Inter` and `DM Sans` font families as defined in `pubspec.yaml`.
   - Organizes standard scale properties: `interBold30`, `interSemiBold16`, `interRegular14`, etc.
   - Always modified with `.copyWith(fontSize: X.sp)` at the call site to enforce dynamic scaling via `flutter_screenutil`.

## Global Alert Utilities (`lib/presentation/widgets/`)
Following a global app audit, the app utilizes two primary custom alert utilities to handle non-blocking feedback, avoiding boilerplate `ScaffoldMessenger` code.

1. **CustomSnackBar (`custom_snackbar.dart`)**
   - A floating, styled wrapper around Flutter's native `SnackBar`.
   - **Usage**: Used for distinct state changes tied closely to standard workflows (e.g. `CustomSnackBar.showSuccess` after saving an Edit Profile form, or `CustomSnackBar.showError` on invalid form submissions).
   - **Styling**: Distinct colored backgrounds (Emerald Green, Red, Blue) with an internal `Row` containing a leading icon and `AppTextStyles` formatted string.

2. **CustomToast (`custom_toast.dart`)**
   - A lightweight, animated, pill-shaped overlay that does not block user interaction.
   - Built using Flutter's native `OverlayEntry` and `TweenAnimationBuilder` (does not rely on third-party toast packages).
   - **Usage**: Used for micro-interactions and rapid acknowledgments (e.g., deleting a payment method, saving a wallet, verifying an account deletion).

## Responsiveness Standards
- Every screen in the app depends heavily on `flutter_screenutil`.
- **Rules**:
  - `padding`/`margin` use `.w` or `.h`.
  - `height` uses `.h`.
  - `width` uses `.w`.
  - `fontSize` uses `.sp`.
  - `borderRadius` uses `.r`.
- Hardcoded numerical values without these extensions are strictly prohibited to ensure 100% Android/iOS cross-device compatibility.

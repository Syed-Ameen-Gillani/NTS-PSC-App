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
Following a UI consolidation audit, the application completely eliminated the use of native `ScaffoldMessenger` Snackbars. Instead, it relies on a single, unified, custom overlay system for all non-blocking feedback.

1. **CustomToast (`custom_toast.dart`)**
   - A lightweight, animated overlay that perfectly mimics the look of a modern floating SnackBar but does not block or push bottom UI elements (like Navigation Bars or FABs).
   - Built using Flutter's native `OverlayEntry` and `TweenAnimationBuilder` without third-party packages.
   - **Styling**: Full-width container (with 24px margins), left-aligned text, rounded corners (`8.r`), and a trailing dismiss ('X') icon to manually close it before the timeout.
   - **API**: 
     - `CustomToast.showSuccess`: Uses `AppColors.primary` (Brand Blue) and a checkmark.
     - `CustomToast.showInfo`: Uses `AppColors.primary` (Brand Blue) and an info icon.
     - `CustomToast.showError`: Uses `AppColors.error` (Red) and an error icon.
     - `CustomToast.show`: Generic fallback (Slate Grey).
   - **Usage**: Deployed across all form submissions (Auth, Profile Edits) and micro-interactions (Payment removals, language switches).

## Responsiveness Standards
- Every screen in the app depends heavily on `flutter_screenutil`.
- **Rules**:
  - `padding`/`margin` use `.w` or `.h`.
  - `height` uses `.h`.
  - `width` uses `.w`.
  - `fontSize` uses `.sp`.
  - `borderRadius` uses `.r`.
- Hardcoded numerical values without these extensions are strictly prohibited to ensure 100% Android/iOS cross-device compatibility.

# Project Structure & Architecture

This document outlines the architecture, tools, and folder structure used in the **NTS-PSC-App**.

## Tech Stack & Core Libraries
- **Framework**: Flutter (Material 3 disabled for specific widgets via Theme)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Routing**: GoRouter (`go_router`) with strong-typed enum navigation.
- **Responsiveness**: ScreenUtil (`flutter_screenutil`)
- **Assets/Icons**: SVG rendering via `flutter_svg`
- **Fonts**: Google Fonts / Local Inter & DM Sans (`google_fonts`)

## Architecture Pattern
The project uses **Feature-First Clean Architecture**. 

Code is primarily divided by feature, and then by architectural layer within that feature:
- `presentation/`: UI screens, local widgets, and Riverpod view models/controllers.
- `domain/`: Business logic, entities, and repository interfaces.
- `data/`: API calls, local storage, DTOs, and repository implementations.

## Directory Structure

```text
lib/
├── config/
│   └── routes/               # Centralized GoRouter setup and AppRoute enum
├── core/
│   ├── constants/            # AppAssets, strings, endpoints
│   └── theme/                # AppColors, AppTextStyles, AppTheme
├── features/                 # Feature modules
│   ├── auth/                 # Login flows
│   ├── authentication/       # Signup & registration flows
│   ├── home/                 # Main dashboard
│   ├── onboarding/           # Walkthrough and Welcome screens
│   └── splash/               # Initialization screen
├── presentation/
│   └── widgets/              # Globally shared UI components (CustomButton, CustomTextFormField)
└── main.dart                 # App entry point, ProviderScope, ScreenUtilInit
```

## Data & Navigation Flow
1. **Routing**: `GoRouter` handles all navigation. Paths are strictly defined in `AppRoute` enum to prevent typos. (`context.pushNamed(AppRoute.login.name)`)
2. **State Management / DI**: Riverpod acts as both the state manager and the dependency injection container. Global services, repositories, and controllers are exposed via `@riverpod` or `Provider`.
3. **UI -> Logic**: UI widgets consume state using `ConsumerWidget` or `ConsumerStatefulWidget` and trigger logic by calling methods on Notifier providers (`ref.read(myProvider.notifier).doSomething()`).
4. **Logic -> Data**: Notifiers talk to Repository interfaces (`domain/repositories`). The Repositories execute API calls or database queries (`data/datasources`).

## Theme Management
Theme is strictly managed through the `core/theme/` directory.
- `AppColors`: Defines strict hex codes matched perfectly to Figma (e.g., `grey100`, `primary`).
- `AppTextStyles`: Defines typography scales (using `Inter`).
- `AppTheme`: Injects these colors into the global `ThemeData` to control native Material components (e.g., removing `scrolledUnderElevation` globally).

## Coding Conventions
- **UI Responsiveness**: Every hardcoded dimension MUST use a `.h` (height), `.w` (width), `.r` (radius), or `.sp` (font size) extension provided by `flutter_screenutil`.
- **Imports**: Favor absolute imports (`package:nts_psc_app/...`) over relative imports to avoid confusion and maintain consistency.

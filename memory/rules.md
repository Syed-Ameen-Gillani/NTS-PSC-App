# NTS-PSC-App Project Rules

These rules must be strictly adhered to by all developers and AI agents working on this project.

## Core Engineering Principles
- **SOLID Principles**: Ensure all code follows Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion.
- **KISS Principle**: Keep it simple, stupid. Avoid over-engineering solutions.
- **Clean Architecture**: Follow feature-first clean architecture (`lib/features/{feature}/presentation`, `domain`, `data`).
- **DRY Principle**: Avoid duplicate code. Extract common logic into reusable methods, helpers, or services.

## State Management & Logic
- **NEVER use `setState()`**: Do not use `StatefulWidget` with `setState()`. 
- **Riverpod for State Management**: Use `flutter_riverpod` and `riverpod_generator` consistently for all state management needs.
- **Separation of Concerns**: Keep business logic completely separate from UI layers. UI should only consume state and trigger actions via Riverpod Notifiers/Controllers.
- **Dispose Properly**: Ensure any controllers, streams, or listeners are properly disposed when no longer needed.
- **Immutability**: Prefer immutable state classes and `const` constructors wherever possible to prevent unnecessary rebuilds.

## UI & Styling
- **ScreenUtil for Responsiveness**: Always use `flutter_screenutil` extensions (`.h` for height/vertical padding, `.w` for width/horizontal padding, `.sp` for fonts, `.r` for radii). NEVER hardcode pixel values.
- **Centralized Theme**: Always use predefined tokens from `AppColors` and `AppTextStyles` (Inter font family). Never hardcode hex colors or text styles inline.
- **Reusability**: Prefer reusable widgets (e.g., `CustomButton`, `CustomTextFormField`) over reinventing the wheel.
- **Widget Composition**: Avoid deeply nested widget trees. Prefer composition over massive widgets. Break complex UI into smaller, private widget methods or standalone widget classes.

## Architecture & Data Flow
- **Centralized Routing**: Use `GoRouter` with strongly-typed enums (`AppRoute` in `app_routes.dart`). Do not use `Navigator.push` with raw string paths.
- **Centralized API Handling**: Keep all API logic in the `data` layer (Repositories/DataSources). Avoid direct API calls inside UI files.
- **Dependency Injection**: Use Riverpod providers as the primary dependency injection mechanism.
- **No Hardcoded Values**: Extract strings to constants or localization files. Extract magic numbers to constants.

## Code Structure & Quality
- **File Length Limits**: Files MUST be under 500 lines. The absolute maximum is 700 lines only if completely unavoidable.
- **Naming Conventions**: Use `camelCase` for variables/methods, `PascalCase` for classes/enums, `snake_case` for file names.
- **Feature-wise Organization**: Always place new code in the appropriate `lib/features/` folder.
- **Documentation**: Write documentation for complex logic, repositories, and complex state notifiers.

## Git & Collaboration
- **Atomic Commits**: Keep commits focused and atomic.
- **Linting**: Ensure there are no warnings from `flutter_lints` or `custom_lint` before finalizing a feature.

## Note for AI Agents
When analyzing or generating code for this repository, you must cross-reference these rules before committing to a solution. Ensure total consistency with the existing project structure and themes.

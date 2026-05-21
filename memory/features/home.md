# Home Screen Feature

## Feature Name
Home Screen / Dashboard

## Purpose
Serves as the primary landing dashboard for users post-authentication. Displays a personalized greeting, a search bar, horizontal scrolling featured courses, filter categories, continue learning progress, category browsing grid, and a vertical list of new courses.

## Screens & Widgets Included
- `MainScreen` (`lib/features/main/presentation/pages/main_screen.dart`): The shell holding the `BottomNavigationBar` and routing between the 5 core tabs.
- `HomeScreen` (`lib/features/home/presentation/pages/home_screen.dart`): The actual dashboard UI.
- Modular Widgets (`lib/features/home/presentation/widgets/`):
  - `HomeHeader`: Greeting and Avatar.
  - `HomeSearchBar`: Search input.
  - `FeaturedCourseList`: Horizontal list of cards with absolute-positioned "Featured" badges.
  - `CategoryFilterChips`: Horizontal scrollable list of toggleable filter chips.
  - `ContinueLearningList`: Cards with linear progress bars.
  - `BrowseCategoryGrid`: 2x2 grid for categories with custom blue icons.
  - `NewCoursesList`: Vertical list of courses (physics disabled so it scrolls with the main view).

## Architecture & Data Flow
- **Data Models**: `CourseModel` and `CategoryModel` (`home_models.dart`).
- **State Management**: Uses Riverpod's `AsyncNotifierProvider` via `HomeController` to simulate network fetching of dashboard content.
- **UI Binding**: `HomeScreen` is a `ConsumerWidget` that strictly observes the `homeControllerProvider`. The UI layer handles NO business logic or static data definitions.

## Routing
- Added `AppRoute.main` to routing enums.
- The Login and Signup screens successfully route to `AppRoute.main` upon auth success using `context.goNamed()`, which clears the auth screens from the navigation stack.

## Dependencies & Packages
- `flutter_riverpod`: State management.
- `flutter_screenutil`: Precise, responsive layout dimensions (`.h`, `.w`).
- `go_router`: Named navigation.

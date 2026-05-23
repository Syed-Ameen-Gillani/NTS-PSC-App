# Quizzes & Learning Feature Memory

## Overview
The Quizzes and Learning modules form the core academic interaction loop of the NTS-PSC-App. They include dynamic interfaces for generating, preparing for, and executing quizzes, alongside browsing enrolled educational materials.

## Screens & Components

### Quizzes Flow
1. **Quizzes Screen (`quizzes_screen.dart`)**
   - The central hub for user assessments.
   - Includes structured horizontal/vertical lists for filtering and browsing available quizzes.
   - Fully responsive `Divider` styling using `.h` for dynamic height mapping on high-density displays.

2. **Generate AI Quiz (`generate_ai_quiz_screen.dart`)**
   - Allows users to parameterize and prompt the AI to build custom, focused quiz sets for specific study sessions.

3. **Active Quiz Execution (`quiz_ready_screen.dart`, `active_quiz_screen.dart`)**
   - **Quiz Ready**: Interstitial pre-flight screen displaying rules, time limits, and question counts before the timer starts.
   - **Active Quiz**: The test-taking interface featuring question carousels, progress indicators, and multiple-choice selection logic.

4. **Quiz Completed (`quiz_completed_screen.dart`)**
   - The post-test analytics screen.
   - Visualizes the score, accuracy breakdown, and provides pathways to review incorrect answers or return to the main hub.

### Learning Flow
1. **My Learning (`my_learning_screen.dart`)**
   - Tracks ongoing and completed courses.
   - Uses linear progress bars and modular cards to display percentage-based completion metrics.
   - Follows global design tokens for typography (`AppTextStyles`) and color branding (`AppColors`).

## UI Architecture
- Navigation between states heavily utilizes `go_router` via named routes (e.g. `AppRoute.activeQuiz.name`).
- Complex states like timer ticks and selected options in active quizzes are maintained using Riverpod providers scoped specifically to the quiz domain.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/onboarding/data/learning_preferences_repository.dart';
import 'package:nts_psc_app/features/onboarding/presentation/screens/interest_survey_screen.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

/// Runs inside the app only after authentication has resolved to a student.
/// The survey owns a navigator so its skill sheet works above the app router.
class StudentInterestGate extends ConsumerWidget {
  const StudentInterestGate({super.key, required this.child});
  final Widget child;

  Widget _frame(Widget? overlay) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(offstage: overlay != null, child: child),
      if (overlay != null) Positioned.fill(child: overlay),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final user = auth?.user;
    if (!AppConfig.isSupabaseEnabled ||
        auth?.isAuthenticated != true ||
        user?.role != UserRole.student ||
        AuthIntegrations.recoveringPassword) {
      return _frame(null);
    }
    return _frame(
      ref
          .watch(learningPreferencesProvider(user!.id))
          .when(
            skipLoadingOnRefresh: false,
            data: (preferences) => preferences.completed
                ? null
                : HeroControllerScope.none(
                    child: Navigator(
                      key: ValueKey('interests-${user.id}'),
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => InterestSurveyScreen(
                          owner: user.id,
                          initial: preferences,
                          onboarding: true,
                        ),
                      ),
                    ),
                  ),
            loading: () => const AppScaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => AppScaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not load your interests. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            learningPreferencesProvider(user.id),
                          ),
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class LearningInterestsPage extends ConsumerWidget {
  const LearningInterestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    if (user == null || user.role != UserRole.student) {
      return const AppScaffold(
        body: Center(
          child: Text('Sign in as a student to edit your interests.'),
        ),
      );
    }
    return ref
        .watch(learningPreferencesProvider(user.id))
        .when(
          data: (preferences) => InterestSurveyScreen(
            key: ValueKey(user.id),
            owner: user.id,
            initial: preferences,
          ),
          loading: () => const AppScaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => AppScaffold(
            appBar: AppBar(title: const Text('Learning preferences')),
            body: Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(learningPreferencesProvider(user.id)),
                child: const Text('Could not load interests. Retry'),
              ),
            ),
          ),
        );
  }
}

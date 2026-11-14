import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/utils/background_return_observer.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/learning_activity_repository.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_activity_sync.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/my_learning_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    user: UserModel(
      id: 'student',
      name: 'Student',
      email: 'test@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
    isAuthenticated: true,
  );
  void updateName() => state = AsyncData(
    state.value!.copyWith(
      user: state.value!.user!.copyWith(name: 'Updated student'),
    ),
  );
}

class _Learning extends MyLearningController {
  static int loads = 0;
  @override
  Future<MyLearningState> build() async {
    loads++;
    return MyLearningState();
  }
}

class _Activity extends LearningActivityRepository {
  _Activity(super.client);
  int subscriptions = 0;
  int disposals = 0;
  VoidCallback? changed;
  @override
  RealtimeChannel subscribe(String userId, VoidCallback onChange) {
    subscriptions++;
    changed = onChange;
    return _Channel();
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {
    disposals++;
  }
}

class _Client implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channel implements RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Evidence extends LearningEvidenceRepository {
  _Evidence(super.client);
  int syncs = 0;
  @override
  Future<void> sync() async {
    syncs++;
  }
}

class _Screen extends ConsumerWidget {
  const _Screen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(learningActivitySyncProvider);
    return Scaffold(
      body: ref
          .watch(myLearningControllerProvider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => const Text('Loading'),
            error: (_, _) => const Text('Error'),
            data: (_) => SingleChildScrollView(
              child: Column(
                children: [
                  const TextField(key: ValueKey('draft')),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(myLearningControllerProvider),
                    child: const Text('Refresh'),
                  ),
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 70, child: Text('Item $i')),
                ],
              ),
            ),
          ),
    );
  }
}

void main() {
  test(
    'background observer ignores focus interruptions and repeated resume',
    () {
      var returns = 0;
      final observer = BackgroundReturnObserver(() => returns++);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
        AppLifecycleState.resumed,
      ]) {
        observer.didChangeAppLifecycleState(state);
      }
      expect(returns, 0);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
        AppLifecycleState.resumed,
      ]) {
        observer.didChangeAppLifecycleState(state);
      }
      expect(returns, 1);
    },
  );

  testWidgets(
    'resume keeps data, form, scroll and subscription; real changes refresh',
    (tester) async {
      final previous = AppConfig.isSupabaseEnabled;
      AppConfig.isSupabaseEnabled = true;
      _Learning.loads = 0;
      addTearDown(() => AppConfig.isSupabaseEnabled = previous);
      final client = _Client();
      final activity = _Activity(client);
      final evidence = _Evidence(client);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            myLearningControllerProvider.overrideWith(_Learning.new),
            learningActivityRepositoryProvider.overrideWithValue(activity),
            learningEvidenceRepositoryProvider.overrideWithValue(evidence),
          ],
          child: const MaterialApp(home: _Screen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('draft')),
        'Keep this draft',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offset = scroll.position.pixels;
      expect(_Learning.loads, 1);
      expect(activity.subscriptions, 1);
      expect(evidence.syncs, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(evidence.syncs, 1);
      for (var i = 0; i < 3; i++) {
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();
      }
      expect(_Learning.loads, 1);
      expect(evidence.syncs, 4);
      expect(scroll.position.pixels, offset);
      expect(find.text('Keep this draft'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(_Screen)),
      );
      (container.read(authControllerProvider.notifier) as _Auth).updateName();
      await tester.pumpAndSettle();
      expect(activity.subscriptions, 1);
      expect(activity.disposals, 0);
      activity.changed!();
      activity.changed!();
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pumpAndSettle();
      expect(_Learning.loads, 2);
      container.invalidate(myLearningControllerProvider);
      await tester.pumpAndSettle();
      expect(_Learning.loads, 3);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(activity.disposals, 1);
    },
  );
}

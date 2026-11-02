import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/curriculum/data/lesson_activity_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/lesson_activity_configuration_controller.dart';

class _Repository extends LessonActivityRepository {
  _Repository()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final items = [
    const ConfiguredActivity(
      LessonActivity(
        id: 'video',
        kind: 'video',
        title: 'Video',
        order: 0,
        isRequired: true,
      ),
      null,
    ),
    const ConfiguredActivity(
      LessonActivity(
        id: 'reading',
        kind: 'reading',
        title: 'Reading',
        order: 1,
        isRequired: true,
      ),
      null,
    ),
  ];
  List<ConfiguredActivity>? saved;
  bool fail = false;
  @override
  Future<List<ConfiguredActivity>> list(String lesson) async => items;
  @override
  Future<void> save(String lesson, List<ConfiguredActivity> activities) async {
    if (fail) throw StateError('offline');
    saved = activities;
  }
}

void main() {
  test(
    'persists order and requirements; failed saves preserve previous state',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          lessonActivityRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = lessonActivityConfigurationProvider('lesson');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final next = [repository.items[1].required(false), repository.items[0]];
      await container.read(provider.notifier).save(next);
      expect(repository.saved?.first.activity.id, 'reading');
      expect(container.read(provider).value?.first.activity.isRequired, false);
      repository.fail = true;
      await expectLater(
        container.read(provider.notifier).save(repository.items),
        throwsStateError,
      );
      expect(container.read(provider).value?.first.activity.id, 'reading');
    },
  );
}

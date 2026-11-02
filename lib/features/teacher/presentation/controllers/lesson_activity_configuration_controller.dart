import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/data/lesson_activity_repository.dart';

final lessonActivityConfigurationProvider = AsyncNotifierProvider.autoDispose
    .family<LessonActivityConfiguration, List<ConfiguredActivity>, String>(
      LessonActivityConfiguration.new,
    );

class LessonActivityConfiguration
    extends AsyncNotifier<List<ConfiguredActivity>> {
  LessonActivityConfiguration(this.lessonId);
  final String lessonId;
  bool _saving = false;
  @override
  Future<List<ConfiguredActivity>> build() {
    ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
    return ref.read(lessonActivityRepositoryProvider).list(lessonId);
  }

  Future<void> save(List<ConfiguredActivity> items) async {
    if (_saving) return;
    _saving = true;
    final previous = state;
    state = const AsyncLoading();
    try {
      await ref.read(lessonActivityRepositoryProvider).save(lessonId, items);
      if (ref.mounted) state = AsyncData(items);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    } finally {
      _saving = false;
    }
  }

  Future<void> prepare(String materialId) async {
    if (_saving) return;
    _saving = true;
    final previous = state;
    state = const AsyncLoading();
    try {
      await ref.read(lessonActivityRepositoryProvider).prepare(materialId);
      final items = await ref
          .read(lessonActivityRepositoryProvider)
          .list(lessonId);
      if (ref.mounted) state = AsyncData(items);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    } finally {
      _saving = false;
    }
  }
}

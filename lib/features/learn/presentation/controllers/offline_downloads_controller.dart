import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/data/offline_reading_store.dart';

final offlineDownloadsProvider = FutureProvider<List<OfflineLessonEntry>>((
  ref,
) {
  ref.watch(authControllerProvider.select((auth) => auth.value?.user?.id));
  return ref.read(offlineLessonLibraryProvider).listDownloads();
});

final offlineReadingsProvider = FutureProvider<List<OfflineReadingEntry>>((
  ref,
) {
  final owner = ref.watch(
    authControllerProvider.select((auth) => auth.value?.user?.id),
  );
  if (owner == null) return Future.value([]);
  return ref.read(offlineReadingStoreProvider).list(owner);
});

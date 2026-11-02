import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/data/offline_reading_store.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
export 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(offlineDownloadsProvider);
    final readings = ref.watch(offlineReadingsProvider);
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Downloads'),
      ),
      body: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(offlineDownloadsProvider),
            child: const Text('Retry downloads'),
          ),
        ),
        data: (items) => readings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(offlineReadingsProvider),
              child: const Text('Retry saved readings'),
            ),
          ),
          data: (savedReadings) => items.isEmpty && savedReadings.isEmpty
              ? const Center(child: Text('No saved lessons or readings'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + savedReadings.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final bytes =
                          items.fold<int>(
                            0,
                            (sum, item) => sum + item.byteSize,
                          ) +
                          savedReadings.fold<int>(
                            0,
                            (sum, item) => sum + item.byteSize,
                          );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          savedReadings.isEmpty
                              ? '${items.length} lessons | ${(bytes / 1048576).toStringAsFixed(1)} MB'
                              : '${items.length} videos · ${savedReadings.length} readings · ${(bytes / 1048576).toStringAsFixed(1)} MB',
                        ),
                      );
                    }
                    if (index > items.length) {
                      return _ReadingDownloadTile(
                        item: savedReadings[index - items.length - 1],
                      );
                    }
                    final item = items[index - 1];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.needsAccessRefresh
                            ? '${(item.byteSize / 1048576).toStringAsFixed(1)} MB · Reconnect to refresh access'
                            : '${(item.byteSize / 1048576).toStringAsFixed(1)} MB',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.needsAccessRefresh)
                            IconButton(
                              tooltip: 'Refresh access',
                              icon: const Icon(Icons.sync),
                              onPressed: () =>
                                  _refreshAccess(context, ref, item),
                            ),
                          IconButton(
                            tooltip: 'Remove download',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(offlineLessonLibraryProvider)
                                    .delete(item.lessonId, item.mediaPath);
                                ref.invalidate(offlineDownloadsProvider);
                              } catch (_) {
                                if (context.mounted) {
                                  CustomToast.showError(
                                    context,
                                    message: 'Could not remove download',
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (item.needsAccessRefresh) {
                          if (!await _refreshAccess(context, ref, item)) return;
                        }
                        if (!context.mounted) return;
                        context.pushNamed(
                          AppRoute.offlineLesson.name,
                          extra: LessonModel(
                            id: item.lessonId,
                            title: item.title,
                            durationMinutes: item.durationMinutes,
                            videoPath: item.mediaPath,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<bool> _refreshAccess(
    BuildContext context,
    WidgetRef ref,
    OfflineLessonEntry item,
  ) async {
    try {
      await ref
          .read(offlineLessonLibraryProvider)
          .refreshAccess(item.lessonId, item.mediaPath);
      ref.invalidate(offlineDownloadsProvider);
      return true;
    } catch (_) {
      if (context.mounted) {
        CustomToast.showError(
          context,
          message: 'Could not refresh access. Check your connection.',
        );
      }
      return false;
    }
  }
}

class _ReadingDownloadTile extends ConsumerWidget {
  const _ReadingDownloadTile({required this.item});
  final OfflineReadingEntry item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(
      authControllerProvider.select((state) => state.value?.user?.id),
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.needsAccessRefresh
            ? 'Reconnect to refresh access'
            : '${(item.byteSize / 1048576).toStringAsFixed(1)} MB · Saved reading',
      ),
      trailing: IconButton(
        tooltip: 'Remove saved reading',
        icon: const Icon(Icons.delete_outline),
        onPressed: owner == null
            ? null
            : () async {
                try {
                  await ref
                      .read(offlineReadingStoreProvider)
                      .remove(owner, item.lessonId, item.materialId);
                  ref.invalidate(offlineReadingsProvider);
                } catch (_) {
                  if (context.mounted) {
                    CustomToast.showError(
                      context,
                      message: 'Could not remove reading',
                    );
                  }
                }
              },
      ),
      onTap: () => context.pushNamed(
        AppRoute.lessonReading.name,
        queryParameters: {
          'lessonId': item.lessonId,
          if (item.materialId != null) 'materialId': item.materialId!,
          'title': item.title,
          if (!item.needsAccessRefresh) 'offline': '1',
        },
      ),
    );
  }
}

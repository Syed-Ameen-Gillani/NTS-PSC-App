import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/offline_downloads_screen.dart';

void main() {
  testWidgets('download manager shows saved lessons and storage use', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineDownloadsProvider.overrideWith(
            (ref) async => [
              const OfflineLessonEntry(
                lessonId: '00000000-0000-0000-0000-000000000001',
                title: 'Pakistan Affairs lecture',
                durationMinutes: 12,
                mediaPath: 'teacher/lesson/version.mp4',
                byteSize: 2 * 1024 * 1024,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: OfflineDownloadsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pakistan Affairs lecture'), findsOneWidget);
    expect(find.text('1 lessons | 2.0 MB'), findsOneWidget);
    expect(find.byTooltip('Remove download'), findsOneWidget);
  });

  testWidgets('expired download stays visible and requests access refresh', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineDownloadsProvider.overrideWith(
            (ref) async => [
              const OfflineLessonEntry(
                lessonId: '00000000-0000-0000-0000-000000000001',
                title: 'Saved lecture',
                durationMinutes: 12,
                mediaPath: 'teacher/lesson/version.mp4',
                byteSize: 2 * 1024 * 1024,
                needsAccessRefresh: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: OfflineDownloadsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved lecture'), findsOneWidget);
    expect(find.textContaining('Reconnect to refresh access'), findsOneWidget);
    expect(find.byTooltip('Refresh access'), findsOneWidget);
  });
}

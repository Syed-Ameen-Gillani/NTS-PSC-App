import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_source_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_video_viewport.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';

import 'support/fake_video_controller.dart';

class _DelayedSpeedVideo extends FakeVideoController {
  Completer<void>? pending;
  final speeds = <double>[];
  int plays = 0;
  int pauses = 0;
  bool fail = false;
  @override
  Future<void> setPlaybackSpeed(double speed) async {
    speeds.add(speed);
    await pending?.future;
    if (fail) throw StateError('Native speed unavailable');
    await super.setPlaybackSpeed(speed);
  }

  @override
  Future<void> play() {
    plays++;
    return super.play();
  }

  @override
  Future<void> pause() {
    pauses++;
    return super.pause();
  }
}

Future<void> _open(WidgetTester tester, _DelayedSpeedVideo video) async {
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(body: ProfessionalVideoPlayer(controller: video)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'native state feedback is not replayed but quiz checkpoints still pause',
    (tester) async {
      final video = _DelayedSpeedVideo();
      addTearDown(video.dispose);
      final oldMode = AppConfig.isSupabaseEnabled;
      AppConfig.isSupabaseEnabled = false;
      addTearDown(() => AppConfig.isSupabaseEnabled = oldMode);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            videoSourceProvider((
              location: 'assets/videos/lecture.mp4',
              asset: true,
            )).overrideWith((ref) async => video),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: LessonVideoViewport(
                  course: CourseModel(
                    id: 'course',
                    title: 'Course',
                    author: 'Teacher',
                    rating: 0,
                    price: 'Free',
                    imagePath: '',
                  ),
                  lesson: LessonModel(
                    id: 'lesson',
                    title: 'Lesson',
                    durationMinutes: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      video.value = video.value.copyWith(
        isPlaying: true,
        duration: const Duration(minutes: 20),
        position: const Duration(seconds: 20),
      );
      await tester.pump();
      expect(video.plays, 0);
      expect(video.pauses, 0);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LessonVideoViewport)),
      );
      // An unrelated preference update must not replay stale transport state.
      video.value = video.value.copyWith(isPlaying: false, isBuffering: true);
      container
          .read(lessonPlaybackControllerProvider.notifier)
          .setQuality('Original');
      await tester.pump();
      expect(video.plays, 0);
      expect(video.pauses, 0);
      video.value = video.value.copyWith(
        isPlaying: true,
        isBuffering: false,
        position: const Duration(seconds: 374),
      );
      await tester.pump();
      expect(video.pauses, 1);
      expect(video.value.isPlaying, false);
      expect(
        container.read(lessonPlaybackControllerProvider).activeQuizTriggerId,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final playing in [true, false]) {
    testWidgets(
      'speed changes preserve ${playing ? 'playing' : 'paused'} transport without extra commands',
      (tester) async {
        final video = _DelayedSpeedVideo()..pending = Completer<void>();
        addTearDown(video.dispose);
        video.value = video.value.copyWith(
          isPlaying: playing,
          position: const Duration(seconds: 23),
        );
        await _open(tester, video);
        final popup = tester.widget<PopupMenuButton<double>>(
          find.byType(PopupMenuButton<double>),
        );
        popup.onSelected!(1.5);
        popup.onSelected!(2);
        await tester.pump();
        expect(video.speeds, [1.5]);
        expect(
          tester
              .widget<PopupMenuButton<double>>(
                find.byType(PopupMenuButton<double>),
              )
              .enabled,
          false,
        );
        video.pending!.complete();
        await tester.pump();
        expect(video.value.playbackSpeed, 1.5);
        expect(video.value.position, const Duration(seconds: 23));
        expect(video.value.isPlaying, playing);
        expect(video.plays, 0);
        expect(video.pauses, 0);
        expect(video.seeks, isEmpty);
        popup.onSelected!(1.5);
        await tester.pump();
        expect(video.speeds, [1.5]);
        expect(
          tester
              .widget<PopupMenuButton<double>>(
                find.byType(PopupMenuButton<double>),
              )
              .enabled,
          true,
        );
      },
    );
  }

  testWidgets('a speed failure unlocks selection and a later change succeeds', (
    tester,
  ) async {
    final video = _DelayedSpeedVideo()..fail = true;
    addTearDown(video.dispose);
    await _open(tester, video);
    tester
        .widget<PopupMenuButton<double>>(find.byType(PopupMenuButton<double>))
        .onSelected!(1.5);
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<PopupMenuButton<double>>(find.byType(PopupMenuButton<double>))
          .enabled,
      true,
    );
    video.fail = false;
    tester
        .widget<PopupMenuButton<double>>(find.byType(PopupMenuButton<double>))
        .onSelected!(2);
    await tester.pump();
    expect(video.value.playbackSpeed, 2);
    expect(video.plays, 0);
    expect(video.pauses, 0);
    expect(tester.takeException(), isNull);
  });
}

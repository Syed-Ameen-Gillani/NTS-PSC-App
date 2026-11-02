import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_controls_state.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/video_fullscreen_screen.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_quality_menu.dart';

import 'support/fake_video_controller.dart';

Widget _app(Widget player) => ProviderScope(
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(home: Scaffold(body: player)),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter_18pt-Regular.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('time, seeking and caption bounds handle malformed data', () {
    expect(
      videoTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(videoTime(const Duration(seconds: -1)), '0:00');
    expect(
      boundedVideoSeek(
        const Duration(seconds: 500),
        const Duration(seconds: 60),
      ),
      const Duration(seconds: 60),
    );
    expect(
      boundedVideoSeek(
        const Duration(seconds: -10),
        const Duration(seconds: 60),
      ),
      Duration.zero,
    );
    expect(
      activeVideoCaption([
        {'start': 'bad', 'end': 3, 'text': 'Hidden'},
      ], Duration.zero),
      isNull,
    );
    expect(
      activeVideoCaption([
        {'start': 0, 'end': 3, 'text': 'Real caption'},
      ], const Duration(seconds: 1)),
      'Real caption',
    );
  });

  testWidgets('play, seek, mute and speed operate on the supplied controller', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(ProfessionalVideoPlayer(controller: video, title: 'Lesson')),
    );
    await tester.tap(find.byTooltip('Play').first);
    await tester.pump();
    expect(video.value.isPlaying, true);
    await tester.tap(find.byTooltip('Forward 10 seconds'));
    await tester.pump();
    expect(video.value.position, const Duration(seconds: 10));
    await tester.tap(find.byTooltip('Rewind 10 seconds'));
    await tester.pump();
    expect(video.value.position, Duration.zero);
    await tester.tap(find.byTooltip('Mute'));
    await tester.pump();
    expect(video.value.volume, 0);
    await tester.tap(find.byTooltip('Playback speed'));
    await tester.pumpAndSettle();
    final speedItem = find.widgetWithText(CheckedPopupMenuItem<double>, '1.5x');
    await tester.ensureVisible(speedItem);
    await tester.tap(speedItem);
    await tester.pumpAndSettle();
    expect(video.value.playbackSpeed, 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fit control is landscape-only and portrait always contains video',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final video = FakeVideoController();
      addTearDown(video.dispose);
      await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
      expect(find.byTooltip('Fill video'), findsOneWidget);
      await tester.tap(find.byTooltip('Fill video'));
      await tester.pump();
      expect(find.byTooltip('Fit video'), findsOneWidget);
      expect(
        tester.widget<FittedBox>(find.byType(FittedBox)).fit,
        BoxFit.cover,
      );
      tester.view.physicalSize = const Size(375, 812);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fit video'), findsNothing);
      expect(find.byTooltip('Fill video'), findsNothing);
      expect(find.byTooltip('Fullscreen'), findsOneWidget);
      expect(
        tester.widget<FittedBox>(find.byType(FittedBox)).fit,
        BoxFit.contain,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quality menu reports the actual source without fake resolutions',
    (tester) async {
      final video = FakeVideoController();
      addTearDown(video.dispose);
      await video.seekTo(const Duration(seconds: 25));
      await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
      await tester.tap(find.byTooltip('Video quality'));
      await tester.pumpAndSettle();
      expect(find.text('Original (720p)'), findsOneWidget);
      expect(find.text('1080p'), findsNothing);
      expect(find.text('360p'), findsNothing);
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<String>, 'Original (720p)'),
      );
      await tester.pumpAndSettle();
      expect(video.value.position, const Duration(seconds: 25));
      expect(video.seeks, [const Duration(seconds: 25)]);
      expect(
        VideoQualityMenu.sourceLabel(const Size(1080, 1920)),
        'Original (1080p)',
      );
      expect(VideoQualityMenu.sourceLabel(Size.zero), 'Original');
    },
  );

  testWidgets(
    'mute restores the previous level and keyboard volume is bounded',
    (tester) async {
      final video = FakeVideoController();
      addTearDown(video.dispose);
      await video.setVolume(0.6);
      await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
      await tester.tap(find.byTooltip('Mute'));
      await tester.pump();
      expect(video.value.volume, 0);
      await tester.tap(find.byTooltip('Unmute'));
      await tester.pump();
      expect(video.value.volume, 0.6);
      await tester.tapAt(
        tester.getTopLeft(find.byType(ProfessionalVideoPlayer)) +
            const Offset(8, 64),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(video.value.volume, closeTo(0.5, 0.001));
      await video.setVolume(1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(video.value.volume, 1);
    },
  );

  testWidgets(
    'buffering reveals controls and prevents auto-hide until recovery',
    (tester) async {
      final video = FakeVideoController();
      addTearDown(video.dispose);
      await video.play();
      await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
      video.value = video.value.copyWith(isBuffering: true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      video.value = video.value.copyWith(isBuffering: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    },
  );

  testWidgets('captions are only available for supplied transcript segments', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await tester.pumpWidget(
      _app(
        ProfessionalVideoPlayer(
          controller: video,
          title: 'Lesson',
          segments: const [
            {'start': 0, 'end': 30, 'text': 'Actual lesson caption'},
          ],
        ),
      ),
    );
    expect(find.text('Actual lesson caption'), findsNothing);
    await tester.tap(find.byTooltip('Captions'));
    await tester.pump();
    expect(find.text('Actual lesson caption'), findsOneWidget);
    video.value = video.value.copyWith(position: const Duration(seconds: 40));
    await tester.pump();
    expect(find.text('Actual lesson caption'), findsNothing);
  });

  testWidgets('scrubbing seeks once and restores the previous playback state', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await video.play();
    await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
    var slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(0);
    await tester.pump();
    expect(video.value.isPlaying, false);
    slider = tester.widget<Slider>(find.byType(Slider));
    video.value = video.value.copyWith(isBuffering: true);
    slider.onChanged!(30000);
    await tester.pump();
    expect(video.seeks, isEmpty);
    slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeEnd!(30000);
    await tester.pump();
    expect(video.seeks, [const Duration(seconds: 30)]);
    expect(video.value.isPlaying, true);
    video.value = video.value.copyWith(isBuffering: false);
    await video.pause();
    await tester.pump();
    slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(30000);
    await tester.pump();
    slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeEnd!(60000);
    await tester.pump();
    expect(video.value.isPlaying, false);
  });

  testWidgets('controls hide during playback and reappear when paused', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    await video.play();
    await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await video.pause();
    await tester.pump();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
  });

  testWidgets('buffering and retry states do not invent captions', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    var retries = 0;
    video.value = video.value.copyWith(isBuffering: true);
    await tester.pumpWidget(
      _app(
        ProfessionalVideoPlayer(controller: video, onRetry: () => retries++),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Captions'), findsNothing);
    video.value = video.value.copyWith(errorDescription: 'Decoder failed');
    await tester.pump();
    expect(find.text('Video could not be played.'), findsOneWidget);
    expect(find.text('Decoder failed'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('ended playback replays and backgrounding pauses', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    video.value = video.value.copyWith(position: video.value.duration);
    await tester.pumpWidget(_app(ProfessionalVideoPlayer(controller: video)));
    await tester.tap(find.byTooltip('Replay'));
    await tester.pump();
    expect(video.value.position, Duration.zero);
    expect(video.value.isPlaying, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(video.value.isPlaying, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('fullscreen retains controller, position, volume and speed', (
    tester,
  ) async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    video.value = video.value.copyWith(
      position: const Duration(seconds: 25),
      playbackSpeed: 1.5,
      volume: 0,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: ProfessionalVideoPlayer(controller: video, title: 'Lesson'),
          ),
        ),
        GoRoute(
          path: AppRoute.videoFullscreen.path,
          name: AppRoute.videoFullscreen.name,
          pageBuilder: (_, state) => NoTransitionPage(
            child: VideoFullscreenScreen(
              session: state.extra as VideoPlayerSession,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fullscreen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProfessionalVideoPlayer>(
            find.byType(ProfessionalVideoPlayer).last,
          )
          .controller,
      same(video),
    );
    await tester.tap(find.byTooltip('Exit fullscreen').first);
    await tester.pumpAndSettle();
    expect(video.value.position, const Duration(seconds: 25));
    expect(video.value.playbackSpeed, 1.5);
    expect(video.value.volume, 0);
    expect(video.disposed, false);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 600.0, 1024.0]) {
    testWidgets('player controls render without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final video = FakeVideoController();
      addTearDown(video.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: boundaryKey,
            child: ProfessionalVideoPlayer(
              controller: video,
              title: 'Introduction to Kashmir studies and regional history',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fullscreen'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 320) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/video_controls_320.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

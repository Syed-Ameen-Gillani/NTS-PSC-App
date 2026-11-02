import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/study_video_player.dart';
import '../test/support/fake_learning_evidence_repository.dart';
import '../test/support/memory_video_study_repository.dart';

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Native test learner',
      email: 'native@example.invalid',
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
  );
}

class _Evidence extends FakeLearningEvidenceRepository {
  final samples = <Map<String, num>>[];
  @override
  Future<Map<String, dynamic>?> videoSession(
    String lesson, {
    String? source,
  }) async => {'id': 'native-fixture', 'lesson_id': lesson, 'source': source};
  @override
  Future<void> append(
    String owner,
    Map<String, dynamic> ticket, {
    required int start,
    required int end,
    required int wallMs,
    double speed = 1,
  }) async {
    samples.add({'start': start, 'end': end, 'wall': wallMs, 'speed': speed});
  }
}

Uint8List _pdf() {
  String stream(String label) {
    final commands = 'BT /F1 16 Tf 30 150 Td ($label) Tj ET\n';
    return '<< /Length ${commands.length} >>\nstream\n${commands}endstream';
  }

  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Contents 4 0 R /Resources << /Font << /F1 7 0 R >> >> >>',
    stream('Reading page one'),
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Contents 6 0 R /Resources << /Font << /F1 7 0 R >> >> >>',
    stream('Reading page two'),
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  var text = '%PDF-1.4\n';
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(text.length);
    text += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = text.length;
  text += 'xref\n0 ${offsets.length}\n0000000000 65535 f \n';
  for (final offset in offsets.skip(1)) {
    text += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  text +=
      'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF';
  return Uint8List.fromList(ascii.encode(text));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native video speed and foreground evidence', (tester) async {
    final video = VideoPlayerController.asset('assets/videos/lecture.mp4');
    final evidence = _Evidence();
    await video.initialize().timeout(const Duration(seconds: 30));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          learningEvidenceRepositoryProvider.overrideWithValue(evidence),
          videoStudyRepositoryProvider.overrideWithValue(
            MemoryVideoStudyRepository(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: StudyVideoPlayer(
                controller: video,
                lessonId: '22222222-2222-2222-2222-222222222222',
                source: 'assets/videos/lecture.mp4',
                title: 'Native video',
                trackLearning: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await video.play();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await video.setPlaybackSpeed(2);
    final before = video.value.position;
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(video.value.isPlaying, true);
    expect(video.value.position, greaterThan(before));
    await video.pause();
    await tester.pump(const Duration(seconds: 1));
    expect(evidence.samples, isNotEmpty);
    expect(
      evidence.samples.every(
        (e) => e['end']! - e['start']! <= e['wall']! * e['speed']! + 300,
      ),
      true,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await video.dispose().timeout(const Duration(seconds: 10));
  });
  testWidgets('native PDF rendering', (tester) async {
    var pageCount = 0;
    final viewer = PdfViewerController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdfViewer.data(
            _pdf(),
            sourceName: 'native-reading.pdf',
            controller: viewer,
            params: PdfViewerParams(
              onViewerReady: (document, controller) {
                pageCount = document.pages.length;
              },
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 80 && pageCount == 0; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(pageCount, 2);
    expect(find.byType(PdfViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

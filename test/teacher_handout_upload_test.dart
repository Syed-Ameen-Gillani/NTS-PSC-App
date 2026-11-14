import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_lesson_media_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_lesson_media_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

const _scope = CurriculumScope(
  courseId: 'course',
  moduleId: 'module',
  lessonId: 'lesson',
);

class _Auth extends AuthController {
  @override
  AuthState build() => AuthState();
}

class _Picker extends FilePickerPlatform {
  PlatformFile? file;
  int calls = 0;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    return file;
  }
}

final class _PickedDocument extends PlatformFile {
  _PickedDocument(this.file);
  final File file;
  @override
  String get name => 'Lesson.pdf';
  @override
  Uri get uri => file.uri;
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int lengthSync() => file.lengthSync();
  @override
  Future<int> length() => file.length();
  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
}

class _Documents extends CurriculumRepository {
  _Documents()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final started = Completer<void>();
  final transferred = Completer<void>();
  final finalized = Completer<void>();
  final processed = Completer<void>();
  final files = <CurriculumMaterial>[];
  bool fail = false;
  void Function(double)? reportProgress;
  int uploads = 0;

  @override
  Future<CurriculumContext> resolve(CurriculumScope scope) async =>
      const CurriculumContext(
        scope: _scope,
        title: 'Lesson',
        courseTitle: 'Course',
        canManage: true,
      );
  @override
  Future<List<CurriculumMaterial>> materials(CurriculumScope scope) async {
    if (scope != _scope) return [];
    return [...files];
  }

  @override
  Future<List<CurriculumAssessment>> assessments(CurriculumScope scope) async =>
      [];
  @override
  Future<void> upload(
    CurriculumScope scope,
    PendingMaterial material, {
    void Function(double)? onProgress,
    void Function(CurriculumMaterial)? onUploaded,
  }) async {
    expect(scope, _scope);
    uploads++;
    reportProgress = onProgress;
    onProgress?.call(0.25);
    started.complete();
    await transferred.future;
    if (fail) throw ArgumentError('Upload interrupted. Try again.');
    final file = CurriculumMaterial(
      id: 'new',
      title: material.name,
      path: 'saved.pdf',
      sizeBytes: material.sizeBytes,
    );
    files.add(file);
    onUploaded?.call(file);
    finalized.complete();
    await processed.future;
  }
}

Future<void> _open(WidgetTester tester, _Documents repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        curriculumRepositoryProvider.overrideWithValue(repository),
        teacherLessonMediaProvider('lesson').overrideWith((ref) async => []),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: TeacherLessonMediaScreen(
            lesson: LessonModel(
              id: 'lesson',
              title: 'Lesson',
              durationMinutes: 10,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(Tab, 'Handouts'));
  await tester.pumpAndSettle();
}

// File.length() performs real I/O while widget continuations use the fake clock.
Future<void> _flushFileIo(WidgetTester tester, bool Function() finished) async {
  for (var i = 0; i < 100 && !finished(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(finished(), true);
}

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);

  for (final fail in [false, true]) {
    testWidgets(
      fail
          ? 'upload failure restores upload action without a fake document'
          : 'progress updates and finalized document appears before extraction finishes',
      (tester) async {
        final repository = _Documents()..fail = fail;
        final picker = _Picker();
        final previousPicker = FilePickerPlatform.instance;
        FilePickerPlatform.instance = picker;
        addTearDown(() => FilePickerPlatform.instance = previousPicker);
        await tester.runAsync(() async {
          final directory = await Directory.systemTemp.createTemp(
            'cboa-handout-',
          );
          addTearDown(() => directory.delete(recursive: true));
          final file = await File(
            '${directory.path}/Lesson.pdf',
          ).writeAsString('%PDF-test');
          picker.file = _PickedDocument(file);
        });
        await _open(tester, repository);
        await tester.runAsync(() => tester.tap(find.text('Upload handouts')));
        await _flushFileIo(tester, () => repository.started.isCompleted);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(picker.calls, 1);
        expect(find.text('Uploading document'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('Upload Lecture Handouts'), findsNothing);
        repository.reportProgress?.call(0.6);
        await tester.pump();
        expect(find.text('60%'), findsOneWidget);
        expect(repository.uploads, 1);
        repository.transferred.complete();
        if (fail) {
          await tester.pumpAndSettle();
          expect(find.text('Upload handouts'), findsOneWidget);
          expect(find.byTooltip('Delete handout'), findsNothing);
          expect(find.text('Upload interrupted. Try again.'), findsOneWidget);
        } else {
          await _flushFileIo(tester, () => repository.finalized.isCompleted);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byTooltip('Delete handout'), findsOneWidget);
          expect(find.text('Preparing document'), findsOneWidget);
          repository.processed.complete();
          await tester.pumpAndSettle();
          expect(find.text('Lesson.pdf'), findsOneWidget);
          expect(find.text('Add another document'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('document-upload-progress')),
            findsNothing,
          );
        }
        await tester.pump(const Duration(seconds: 4));
      },
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/teacher/data/course_cover_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('accepts decoded JPEG and PNG artwork', () async {
    expect(
      await CourseCoverRepository.validateImage(
        await File('assets/images/course1.jpg').readAsBytes(),
      ),
      'image/jpeg',
    );
    expect(
      await CourseCoverRepository.validateImage(
        await File('assets/images/logo.png').readAsBytes(),
      ),
      'image/png',
    );
  });

  test('rejects empty, unsupported and oversized uploads', () async {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      Uint8List(CourseCoverRepository.maxBytes + 1),
    ]) {
      await expectLater(
        CourseCoverRepository.validateImage(bytes),
        throwsArgumentError,
      );
    }
  });

  test('rejects a corrupt file with an image signature', () async {
    await expectLater(
      CourseCoverRepository.validateImage(
        Uint8List.fromList([137, 80, 78, 71, 0, 0, 0, 0]),
      ),
      throwsA(anything),
    );
  });
}

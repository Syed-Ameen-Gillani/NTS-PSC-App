import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/services/app_image_picker_service.dart';

void main() {
  group('AppImageCropPreset', () {
    test('profile photos use a square upload frame', () {
      final spec = AppImageCropPreset.profilePhoto.spec;

      expect(spec.ratioX / spec.ratioY, 1);
      expect(spec.maxWidth, spec.maxHeight);
    });

    test('course covers use the displayed 16:9 frame', () {
      final spec = AppImageCropPreset.courseCover.spec;

      expect(spec.ratioX / spec.ratioY, closeTo(16 / 9, 0.0001));
      expect(spec.maxWidth / spec.maxHeight, closeTo(16 / 9, 0.0001));
    });
  });
}

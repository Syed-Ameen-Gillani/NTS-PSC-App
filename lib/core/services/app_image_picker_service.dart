import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/utils/image_upload_validator.dart';

enum AppImageCropPreset { profilePhoto, courseCover }

class AppImageCropSpec {
  const AppImageCropSpec({
    required this.ratioX,
    required this.ratioY,
    required this.maxWidth,
    required this.maxHeight,
    required this.title,
  });

  final double ratioX;
  final double ratioY;
  final int maxWidth;
  final int maxHeight;
  final String title;
}

extension AppImageCropPresetX on AppImageCropPreset {
  AppImageCropSpec get spec => switch (this) {
    AppImageCropPreset.profilePhoto => const AppImageCropSpec(
      ratioX: 1,
      ratioY: 1,
      maxWidth: 1200,
      maxHeight: 1200,
      title: 'Crop profile photo',
    ),
    AppImageCropPreset.courseCover => const AppImageCropSpec(
      ratioX: 16,
      ratioY: 9,
      maxWidth: 1920,
      maxHeight: 1080,
      title: 'Crop course cover',
    ),
  };
}

class CroppedImageData {
  const CroppedImageData({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

final appImagePickerServiceProvider = Provider<AppImagePickerService>(
  (ref) => const AppImagePickerService(),
);

class AppImagePickerService {
  const AppImagePickerService();

  static const int maxSourceBytes = 25 * 1024 * 1024;
  static const int outputQuality = 88;
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  Future<CroppedImageData?> pickAndCrop({
    required BuildContext context,
    required AppImageCropPreset preset,
  }) async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (selected == null || !context.mounted) return null;

    final sourceLength = selected.lengthSync() ?? await selected.length();
    if (sourceLength == null || sourceLength <= 0) {
      throw ArgumentError('Could not read that image. Try another file.');
    }
    if (sourceLength > maxSourceBytes) {
      throw ArgumentError('Choose an image no larger than 25 MB.');
    }
    if (!context.mounted) return null;

    final spec = preset.spec;
    final screenSize = MediaQuery.sizeOf(context);
    final cropped = await ImageCropper().cropImage(
      sourcePath: selected.xFile.path,
      maxWidth: spec.maxWidth,
      maxHeight: spec.maxHeight,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: outputQuality,
      aspectRatio: CropAspectRatio(ratioX: spec.ratioX, ratioY: spec.ratioY),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: spec.title,
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.onBackground,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          cropFrameColor: AppColors.primary,
          statusBarLight: true,
          navBarLight: true,
          lockAspectRatio: true,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: spec.title,
          doneButtonTitle: 'Use photo',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: true,
          aspectRatioLockDimensionSwapEnabled: false,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          showCancelConfirmationDialog: true,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: CropperSize(
            width: math.min(640, math.max(280, screenSize.width - 32)).round(),
            height: math
                .min(560, math.max(360, screenSize.height - 80))
                .round(),
          ),
        ),
      ],
    );
    if (cropped == null) return null;

    final bytes = await cropped.readAsBytes();
    await ImageUploadValidator.validate(bytes);
    return CroppedImageData(name: _croppedName(selected.name), bytes: bytes);
  }

  String _croppedName(String sourceName) {
    final separator = sourceName.lastIndexOf('.');
    final baseName = separator > 0
        ? sourceName.substring(0, separator)
        : sourceName;
    return '${baseName}_cropped.jpg';
  }
}

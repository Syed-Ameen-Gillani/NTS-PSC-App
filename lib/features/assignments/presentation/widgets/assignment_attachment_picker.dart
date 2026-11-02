import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

Future<List<AssignmentAttachmentModel>> pickAssignmentAttachments(
  BuildContext context,
  List<AssignmentAttachmentModel> current,
) async {
  final updated = [...current];
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
      ],
    );
    if (!context.mounted) return current;
    for (final file in files) {
      if (updated.length >= 3) {
        CustomToast.showError(
          context,
          message: 'Maximum 3 files per submission',
        );
        break;
      }
      final size = file.lengthSync() ?? await file.length() ?? 0;
      if (!context.mounted) return current;
      if (size < 1 || size > 25 * 1024 * 1024) {
        CustomToast.showError(context, message: 'Choose a file up to 25 MB.');
        continue;
      }
      final bytes = AppConfig.isSupabaseEnabled
          ? await file.readAsBytes()
          : null;
      if (!context.mounted) return current;
      updated.add(
        AssignmentAttachmentModel(
          name: file.name,
          sizeBytes: size,
          path: file.path,
          bytes: bytes,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      CustomToast.showError(
        context,
        message: 'Could not add that file. Please try again.',
      );
    }
  }
  return updated;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/data/assignment_repository_provider.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentAttachmentTile extends ConsumerWidget {
  const AssignmentAttachmentTile({super.key, required this.attachment});

  final AssignmentAttachmentModel attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    type: MaterialType.transparency,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.attach_file),
      title: Text(
        attachment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${(attachment.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
      ),
      trailing: AppConfig.isSupabaseEnabled && attachment.path != null
          ? const Icon(Icons.open_in_new, size: 18)
          : null,
      onTap: !AppConfig.isSupabaseEnabled || attachment.path == null
          ? null
          : () async {
              try {
                final url = await ref
                    .read(assignmentRepositoryProvider)
                    .getAttachmentUrl(attachment.path!);
                if (!await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                )) {
                  throw StateError('Could not open attachment');
                }
              } catch (_) {
                if (context.mounted) {
                  CustomToast.showError(
                    context,
                    message: 'Could not open attachment',
                  );
                }
              }
            },
    ),
  );
}

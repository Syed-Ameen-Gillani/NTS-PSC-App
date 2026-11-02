import 'package:flutter/material.dart';

Future<bool> confirmAssessmentLinkChange({
  required BuildContext context,
  required String title,
  required String target,
  required bool unlink,
  bool publish = false,
}) async {
  final action = unlink ? 'Unlink' : 'Link';
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('$action assessment?'),
          content: Text(
            unlink
                ? 'Remove "$title" from $target? Publish course changes to update what students see.'
                : publish
                ? 'Link "$title" to $target? Publish the course changes to make it available to students.'
                : 'Link "$title" to $target? Students will see it after the course changes are published.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

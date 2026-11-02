import 'package:flutter/material.dart';
import 'automatic_learning_status.dart';

/// Compatibility name for the downloaded-lesson status. No completion action.
class OfflineCompletionButton extends StatelessWidget {
  const OfflineCompletionButton({super.key, required this.lessonId});
  final String lessonId;
  @override
  Widget build(BuildContext context) =>
      AutomaticLearningStatus(lessonId: lessonId);
}

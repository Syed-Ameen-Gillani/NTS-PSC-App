import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final assignmentSubmittingProvider = StateProvider.autoDispose
    .family<bool, String>((ref, id) => false);

/// Prevents leaving or changing a submission while its upload is in flight.
class AssignmentSubmissionGuard extends ConsumerWidget {
  const AssignmentSubmissionGuard({
    super.key,
    required this.assignmentId,
    required this.child,
  });

  final String assignmentId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(assignmentSubmittingProvider(assignmentId));
    return PopScope(
      canPop: !busy,
      child: Stack(
        children: [
          AbsorbPointer(absorbing: busy, child: child),
          if (busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:nts_psc_app/features/assignments/data/assignment_draft_store.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';

/// Owns draft restoration/debounce independently from the submission UI.
class AssignmentDraftBinding {
  AssignmentDraftBinding({
    required this.userId,
    required this.assignmentId,
    required this.response,
    required this.attachments,
    required this.isCurrentUser,
    required this.onError,
  }) {
    response.addListener(_changed);
    attachments.addListener(_changed);
    unawaited(_restore());
  }
  final String userId, assignmentId;
  final TextEditingController response;
  final ValueNotifier<List<AssignmentAttachmentModel>> attachments;
  final bool Function() isCurrentUser;
  final VoidCallback onError;
  final _store = AssignmentDraftStore();
  Timer? _timer;
  bool _restoring = true,
      _alive = true,
      _cleared = false,
      _changedDuringRestore = false;
  bool _reportedError = false;

  void _report() {
    if (_alive && !_reportedError) {
      _reportedError = true;
      onError();
    }
  }

  Future<void> _restore() async {
    try {
      final draft = await _store.read(userId, assignmentId);
      if (_alive &&
          isCurrentUser() &&
          !_changedDuringRestore &&
          draft != null) {
        response.text = draft.response;
        attachments.value = draft.attachments;
      }
    } catch (_) {
      _report();
    } finally {
      _restoring = false;
      if (_changedDuringRestore) _changed();
    }
  }

  void _changed() {
    if (!_alive || _cleared) return;
    if (_restoring) {
      _changedDuringRestore = true;
      return;
    }
    _timer?.cancel();
    final draft = AssignmentDraft(response.text, List.of(attachments.value));
    _timer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_write(draft)),
    );
  }

  Future<void> _write(AssignmentDraft draft) async {
    if (_cleared || !isCurrentUser()) return;
    try {
      await _store.write(userId, assignmentId, draft);
    } catch (_) {
      _report();
    }
  }

  Future<void> clear() async {
    _cleared = true;
    _timer?.cancel();
    await _store.clear(userId, assignmentId);
  }

  void dispose() {
    final draft = AssignmentDraft(response.text, List.of(attachments.value));
    _alive = false;
    _timer?.cancel();
    response.removeListener(_changed);
    attachments.removeListener(_changed);
    if (!_restoring && !_cleared) unawaited(_write(draft));
  }
}

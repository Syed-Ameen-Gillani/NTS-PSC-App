import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/domain/assignment_link.dart';
import 'package:nts_psc_app/features/assignments/domain/repositories/assignment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseAssignmentRepository implements AssignmentRepository {
  SupabaseAssignmentRepository(this._client);

  final SupabaseClient _client;
  static const _baseAssignmentColumns =
      'id, course_id, title, instructions, due_at, status, courses(title)';
  static const _linkAssignmentColumns =
      'id, course_id, title, instructions, external_url, due_at, status, courses(title)';
  bool? _linksAvailable;

  String get _assignmentColumns => _linksAvailable == false
      ? _baseAssignmentColumns
      : _linkAssignmentColumns;

  static bool _missingLinkColumn(PostgrestException error) =>
      (error.code == '42703' || error.code == 'PGRST204') &&
      error.message.contains('external_url');

  Future<void> _checkLinkColumn() async {
    if (_linksAvailable != null) return;
    try {
      await _client.from('assignments').select('external_url').limit(0);
      _linksAvailable = true;
    } on PostgrestException catch (error) {
      if (!_missingLinkColumn(error)) rethrow;
      _linksAvailable = false;
    }
  }

  Future<void> _requireLinkSupport(String? externalUrl) async {
    await _checkLinkColumn();
    if (_linksAvailable == false && (externalUrl?.trim().isNotEmpty ?? false)) {
      throw StateError('Assignment links need a database update.');
    }
  }

  static const bucket = 'assignment-submissions';
  static const briefBucket = 'assignment-briefs';
  static const maxFileBytes = 25 * 1024 * 1024;
  static const maxFiles = 3;
  static const maxBriefFiles = 5;
  static const _mimeTypes = <String, String>{
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };
  static const _briefMimeTypes = <String, String>{
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'txt': 'text/plain',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  @override
  Future<String> getAttachmentUrl(String path) async {
    _userId;
    return _client.storage
        .from(path.startsWith('briefs/') ? briefBucket : bucket)
        .createSignedUrl(path, 60);
  }

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in to access assignments.'));

  @override
  Future<List<AssignmentModel>> getAssignments() async {
    _userId;
    List<Map<String, dynamic>> rows;
    try {
      rows = await _client
          .from('assignments')
          .select(_assignmentColumns)
          .order('created_at', ascending: false);
      if (_linksAvailable != false) _linksAvailable = true;
    } on PostgrestException catch (error) {
      if (!_missingLinkColumn(error)) rethrow;
      _linksAvailable = false;
      rows = await _client
          .from('assignments')
          .select(_baseAssignmentColumns)
          .order('created_at', ascending: false);
    }
    if (rows.isEmpty) return [];
    final briefs = await _loadBriefs(
      rows.map((row) => row['id'] as String).toList(),
    );
    return rows
        .map(
          (row) =>
              mapAssignmentRow(row, attachments: briefs[row['id']] ?? const []),
        )
        .toList();
  }

  Future<Map<String, List<AssignmentAttachmentModel>>> _loadBriefs(
    List<String> assignmentIds,
  ) async {
    if (assignmentIds.isEmpty) return {};
    final rows = await _client
        .from('assignment_brief_attachments')
        .select('assignment_id,original_name,size_bytes,object_path')
        .inFilter('assignment_id', assignmentIds)
        .eq('status', 'ready')
        .order('created_at');
    final result = <String, List<AssignmentAttachmentModel>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row['assignment_id'] as String, () => [])
          .add(
            AssignmentAttachmentModel(
              name: row['original_name'] as String,
              sizeBytes: (row['size_bytes'] as num).toInt(),
              path: row['object_path'] as String,
            ),
          );
    }
    return result;
  }

  static String _briefExtension(String name) =>
      name.split('.').last.toLowerCase();

  static void validateBriefs(List<AssignmentAttachmentModel> attachments) {
    if (attachments.length > maxBriefFiles) {
      throw ArgumentError('Add up to five assignment files.');
    }
    for (final attachment in attachments) {
      final bytes = attachment.bytes;
      if (attachment.name.trim().isEmpty ||
          attachment.name.length > 255 ||
          !_briefMimeTypes.containsKey(_briefExtension(attachment.name)) ||
          attachment.sizeBytes < 1 ||
          attachment.sizeBytes > maxFileBytes ||
          (bytes != null && bytes.length != attachment.sizeBytes) ||
          (bytes == null &&
              (attachment.path == null ||
                  !attachment.path!.startsWith('briefs/')))) {
        throw ArgumentError('Choose a supported file up to 25 MB.');
      }
    }
  }

  Future<AssignmentAttachmentModel> _uploadBrief(
    String assignmentId,
    AssignmentAttachmentModel attachment,
  ) async {
    final bytes = attachment.bytes!;
    final extension = _briefExtension(attachment.name);
    final reservation = Map<String, dynamic>.from(
      await _client.rpc(
        'begin_assignment_brief',
        params: {
          'p_assignment_id': assignmentId,
          'p_name': attachment.name,
          'p_extension': extension,
          'p_size': attachment.sizeBytes,
        },
      ),
    );
    final path = reservation['object_path'] as String;
    try {
      await _client.storage
          .from(briefBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _briefMimeTypes[extension],
              upsert: false,
            ),
          );
      await _client.rpc(
        'finish_assignment_brief',
        params: {'p_id': reservation['id']},
      );
      return AssignmentAttachmentModel(
        name: attachment.name,
        sizeBytes: attachment.sizeBytes,
        path: path,
      );
    } catch (_) {
      try {
        await _deleteBrief(path);
      } catch (_) {
        // Keep the draft and metadata available for a later cleanup attempt.
      }
      rethrow;
    }
  }

  Future<void> _deleteBrief(String path) async {
    await _client.storage.from(briefBucket).remove([path]);
    await _client
        .from('assignment_brief_attachments')
        .delete()
        .eq('object_path', path);
  }

  Future<AssignmentModel> _assignmentWithBriefs(
    Map<String, dynamic> row,
  ) async {
    final id = row['id'] as String;
    final briefs = await _loadBriefs([id]);
    return mapAssignmentRow(row, attachments: briefs[id] ?? const []);
  }

  @override
  Future<List<AssignmentSubmissionModel>> getSubmissions() async {
    _userId;
    final rows = await _client
        .from('assignment_submissions')
        .select(
          'id, assignment_id, student_id, status, submitted_at, feedback, current_revision',
        )
        .order('submitted_at', ascending: false);
    if (rows.isEmpty) return [];
    final ids = rows.map((row) => row['id'] as String).toList();
    final revisions = await _client
        .from('assignment_submission_revisions')
        .select('id, submission_id, revision_number, response, submitted_at')
        .inFilter('submission_id', ids);
    final revisionIds = revisions.map((row) => row['id'] as String).toList();
    final attachmentRows = revisionIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('assignment_submission_attachments')
              .select('revision_id, object_path, original_name, size_bytes')
              .inFilter('revision_id', revisionIds);
    final attachmentsByRevision = <String, List<AssignmentAttachmentModel>>{};
    for (final attachment in attachmentRows) {
      attachmentsByRevision
          .putIfAbsent(attachment['revision_id'] as String, () => [])
          .add(
            AssignmentAttachmentModel(
              name: attachment['original_name'] as String,
              sizeBytes: (attachment['size_bytes'] as num).toInt(),
              path: attachment['object_path'] as String,
            ),
          );
    }
    return rows.map((row) {
      final studentId = row['student_id'] as String;
      final history =
          revisions
              .where((revision) => revision['submission_id'] == row['id'])
              .map(
                (revision) => AssignmentRevisionModel(
                  number: (revision['revision_number'] as num).toInt(),
                  response: revision['response'] as String,
                  submittedAt: DateTime.parse(
                    revision['submitted_at'] as String,
                  ).toLocal(),
                  attachments:
                      attachmentsByRevision[revision['id']] ?? const [],
                ),
              )
              .toList()
            ..sort((a, b) => b.number.compareTo(a.number));
      final current = history
          .where((item) => item.number == row['current_revision'])
          .firstOrNull;
      return mapSubmissionRow(
        row,
        response: current?.response ?? '',
        studentName: studentId == _userId ? 'You' : 'Student',
        attachments: current?.attachments ?? const [],
        revisions: history,
      );
    }).toList();
  }

  @override
  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String courseTitle,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    _userId;
    final linkError = assignmentLinkError(externalUrl);
    if (linkError != null) throw ArgumentError(linkError);
    await _requireLinkSupport(externalUrl);
    validateBriefs(attachments);
    if (attachments.any((item) => item.bytes == null)) {
      throw ArgumentError('Choose assignment files from this device.');
    }
    if (title.trim().isEmpty ||
        instructions.trim().isEmpty ||
        !dueAt.isAfter(DateTime.now())) {
      throw ArgumentError(
        'Title, instructions, and a future due date are required.',
      );
    }
    final row = await _client
        .from('assignments')
        .insert({
          'course_id': courseId,
          'title': title.trim(),
          'instructions': instructions.trim(),
          if (_linksAvailable == true)
            'external_url': externalUrl?.trim().isEmpty ?? true
                ? null
                : externalUrl!.trim(),
          'due_at': dueAt.toUtc().toIso8601String(),
        })
        .select(_assignmentColumns)
        .single();
    final uploaded = <AssignmentAttachmentModel>[];
    try {
      for (final attachment in attachments) {
        uploaded.add(await _uploadBrief(row['id'] as String, attachment));
      }
    } catch (_) {
      var cleaned = true;
      for (final attachment in uploaded) {
        try {
          await _deleteBrief(attachment.path!);
        } catch (_) {
          cleaned = false;
        }
      }
      if (cleaned) {
        try {
          await _client.from('assignments').delete().eq('id', row['id']);
        } catch (_) {
          cleaned = false;
        }
      }
      if (!cleaned) {
        throw StateError(
          'Draft saved, but file upload failed. Reopen it to retry.',
        );
      }
      rethrow;
    }
    return _assignmentWithBriefs(row);
  }

  @override
  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    String? externalUrl,
    required DateTime dueAt,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    _userId;
    final linkError = assignmentLinkError(externalUrl);
    if (linkError != null) throw ArgumentError(linkError);
    await _requireLinkSupport(externalUrl);
    validateBriefs(attachments);
    if (title.trim().isEmpty ||
        instructions.trim().isEmpty ||
        !dueAt.isAfter(DateTime.now())) {
      throw ArgumentError(
        'Title, instructions, and a future due date are required.',
      );
    }
    final previous = await _loadBriefs([assignmentId]);
    final oldPaths = {
      for (final item
          in previous[assignmentId] ?? const <AssignmentAttachmentModel>[])
        item.path!,
    };
    final keptPaths = {
      for (final item in attachments)
        if (item.bytes == null) item.path!,
    };
    if (!oldPaths.containsAll(keptPaths)) {
      throw ArgumentError('Assignment files have changed. Reopen the draft.');
    }
    final uploaded = <AssignmentAttachmentModel>[];
    late final Map<String, dynamic> row;
    try {
      for (final attachment in attachments.where(
        (item) => item.bytes != null,
      )) {
        uploaded.add(await _uploadBrief(assignmentId, attachment));
      }
      row = await _client
          .from('assignments')
          .update({
            'title': title.trim(),
            'instructions': instructions.trim(),
            if (_linksAvailable == true)
              'external_url': externalUrl?.trim().isEmpty ?? true
                  ? null
                  : externalUrl!.trim(),
            'due_at': dueAt.toUtc().toIso8601String(),
          })
          .eq('id', assignmentId)
          .eq('status', 'draft')
          .select(_assignmentColumns)
          .single();
    } catch (_) {
      for (final attachment in uploaded) {
        try {
          await _deleteBrief(attachment.path!);
        } catch (_) {
          // A retained draft lets the teacher retry the cleanup.
        }
      }
      rethrow;
    }
    try {
      for (final path in oldPaths.difference(keptPaths)) {
        await _deleteBrief(path);
      }
    } catch (_) {
      throw StateError(
        'Draft saved, but a file could not be removed. Reopen it to retry.',
      );
    }
    return _assignmentWithBriefs(row);
  }

  @override
  Future<AssignmentModel> publishAssignment(String assignmentId) async {
    _userId;
    await _checkLinkColumn();
    final row = await _client
        .from('assignments')
        .update({'status': 'published'})
        .eq('id', assignmentId)
        .eq('status', 'draft')
        .select(_assignmentColumns)
        .single();
    return _assignmentWithBriefs(row);
  }

  @override
  Future<AssignmentSubmissionModel> submit({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String response,
    List<AssignmentAttachmentModel> attachments = const [],
  }) async {
    if (studentId != _userId) throw StateError('Student identity mismatch.');
    if (attachments.length > maxFiles ||
        (response.trim().isEmpty && attachments.isEmpty)) {
      throw ArgumentError('Provide a response or up to three files.');
    }
    final uploads = <String>[];
    var committed = false;
    var commitRequested = false;
    final requestId = const Uuid().v4();
    try {
      final metadata = <Map<String, String>>[];
      for (final attachment in attachments) {
        final extension = attachment.name.split('.').last.toLowerCase();
        final mime = _mimeTypes[extension];
        final bytes = attachment.bytes;
        if (mime == null ||
            bytes == null ||
            bytes.length != attachment.sizeBytes ||
            bytes.isEmpty ||
            bytes.length > maxFileBytes ||
            attachment.name.length > 255) {
          throw ArgumentError('Invalid attachment: ${attachment.name}');
        }
        final path = '$studentId/$assignmentId/${const Uuid().v4()}.$extension';
        await _client.storage
            .from(bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: mime, upsert: false),
            );
        uploads.add(path);
        metadata.add({'path': path, 'name': attachment.name});
      }
      commitRequested = true;
      Future<Map<String, dynamic>> send() async =>
          await _client.rpc(
                'submit_assignment_request',
                params: {
                  'p_request_id': requestId,
                  'p_assignment_id': assignmentId,
                  'p_response': response,
                  'p_attachments': metadata,
                },
              )
              as Map<String, dynamic>;
      late final Map<String, dynamic> row;
      try {
        row = await send();
      } catch (_) {
        // The same key returns the committed revision if its response was lost.
        row = await send();
      }
      committed = true;
      try {
        final persisted = await getSubmissions();
        return persisted.firstWhere((item) => item.id == row['id']);
      } catch (_) {
        return mapSubmissionRow(
          row,
          response: response.trim(),
          studentName: studentName,
          attachments: [
            for (var i = 0; i < uploads.length; i++)
              AssignmentAttachmentModel(
                name: attachments[i].name,
                sizeBytes: attachments[i].sizeBytes,
                path: uploads[i],
              ),
          ],
        );
      }
    } catch (_) {
      if (!committed && !commitRequested && uploads.isNotEmpty) {
        try {
          await _client.storage.from(bucket).remove(uploads);
        } catch (_) {
          // Never remove files after an ambiguous commit response.
        }
      }
      rethrow;
    }
  }

  @override
  Future<AssignmentSubmissionModel> review({
    required String submissionId,
    required AssignmentReviewStatus decision,
    required String feedback,
  }) async {
    _userId;
    if (decision == AssignmentReviewStatus.pending) {
      throw ArgumentError('Choose approve or reject.');
    }
    final row =
        await _client.rpc(
              'review_assignment',
              params: {
                'p_submission_id': submissionId,
                'p_decision': decision.name,
                'p_feedback': feedback,
              },
            )
            as Map<String, dynamic>;
    final persisted = await getSubmissions();
    return persisted.firstWhere((item) => item.id == row['id']);
  }

  static AssignmentModel mapAssignmentRow(
    Map<String, dynamic> row, {
    List<AssignmentAttachmentModel> attachments = const [],
  }) {
    final course = row['courses'] as Map<String, dynamic>?;
    return AssignmentModel(
      id: row['id'] as String,
      courseId: row['course_id'] as String,
      courseTitle: course?['title'] as String? ?? '',
      title: row['title'] as String,
      instructions: row['instructions'] as String,
      externalUrl: row['external_url'] as String?,
      dueAt: DateTime.parse(row['due_at'] as String).toLocal(),
      isPublished: row['status'] == 'published',
      attachments: attachments,
    );
  }

  static AssignmentSubmissionModel mapSubmissionRow(
    Map<String, dynamic> row, {
    required String response,
    required String studentName,
    List<AssignmentAttachmentModel> attachments = const [],
    List<AssignmentRevisionModel> revisions = const [],
  }) => AssignmentSubmissionModel(
    id: row['id'] as String,
    assignmentId: row['assignment_id'] as String,
    studentId: row['student_id'] as String,
    studentName: studentName,
    response: response,
    submittedAt: DateTime.parse(row['submitted_at'] as String).toLocal(),
    status: AssignmentReviewStatus.values.byName(row['status'] as String),
    feedback: row['feedback'] as String? ?? '',
    attachments: attachments,
    revisions: revisions,
  );
}

import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public instructor listings are separate from course detail hydration.
class SupabaseTeacherDirectory {
  const SupabaseTeacherDirectory(this.client);
  final SupabaseClient client;

  Future<List<TeacherModel>> list({int? limit, int offset = 0}) async {
    if (limit != null && (limit < 1 || limit > 100)) {
      throw ArgumentError('Invalid instructor preview limit.');
    }
    if (offset < 0) throw ArgumentError('Invalid instructor page.');
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var pageOffset = offset; ; pageOffset += pageSize) {
      final length = limit == null
          ? pageSize
          : (limit - (pageOffset - offset)).clamp(0, pageSize);
      if (length == 0) break;
      final page = await client
          .from('public_teacher_profiles')
          .select('id, display_name, avatar_path, subject, qualification, bio')
          .order('id')
          .range(pageOffset, pageOffset + length - 1);
      rows.addAll(page);
      if (page.length < length) break;
    }
    return rows.map(_fromRow).toList();
  }

  Future<TeacherModel?> find(String teacherId) async {
    final row = await client
        .from('public_teacher_profiles')
        .select('id, display_name, avatar_path, subject, qualification, bio')
        .eq('id', teacherId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  TeacherModel _fromRow(Map<String, dynamic> row) {
    final path = row['avatar_path'] as String?;
    return TeacherModel(
      id: row['id'] as String,
      name: row['display_name'] as String,
      subject: row['subject'] as String? ?? '',
      imagePath: path == null || path.isEmpty
          ? ''
          : client.storage.from('profile-avatars').getPublicUrl(path),
      qualification: row['qualification'] as String? ?? '',
      bio: row['bio'] as String? ?? '',
      rating: 0,
      studentCount: 0,
    );
  }
}

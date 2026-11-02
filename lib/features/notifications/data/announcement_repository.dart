import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(Supabase.instance.client);
});

class AnnouncementRepository {
  AnnouncementRepository(this._client);
  final SupabaseClient _client;

  Future<void> broadcast({
    required String courseId,
    required String title,
    required String message,
    required bool urgent,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to post an announcement.');
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();
    if (cleanTitle.isEmpty ||
        cleanTitle.length > 120 ||
        cleanMessage.isEmpty ||
        cleanMessage.length > 1000) {
      throw ArgumentError(
        'Enter a title and a message under 1,000 characters.',
      );
    }
    await _client.from('course_announcements').insert({
      'course_id': courseId,
      'instructor_id': userId,
      'title': cleanTitle,
      'message': cleanMessage,
      'is_urgent': urgent,
    });
  }
}

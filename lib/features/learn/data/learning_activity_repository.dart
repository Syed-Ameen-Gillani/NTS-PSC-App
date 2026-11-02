import 'package:supabase_flutter/supabase_flutter.dart';

class LearningActivityRepository {
  LearningActivityRepository(this.client);
  final SupabaseClient client;

  RealtimeChannel subscribe(String userId, void Function() onChange) {
    final channel = client.channel('learning:$userId');
    for (final table in [
      'assignment_submissions',
      'quiz_attempts',
      'course_completions',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'student_id',
          value: userId,
        ),
        callback: (_) => onChange(),
      );
    }
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'lesson_progress',
      callback: (_) => onChange(),
    );
    return channel.subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}

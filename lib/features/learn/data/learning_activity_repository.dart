import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/lifecycle_diagnostics.dart';

final learningActivityRepositoryProvider = Provider(
  (ref) => LearningActivityRepository(Supabase.instance.client),
);

class LearningActivityRepository {
  LearningActivityRepository(this.client);
  final SupabaseClient client;

  RealtimeChannel subscribe(String userId, void Function() onChange) {
    LifecycleDiagnostics.event('learning-realtime', 'subscribe');
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
        callback: (_) {
          LifecycleDiagnostics.event('learning-realtime', 'change $table');
          onChange();
        },
      );
    }
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'lesson_progress',
      callback: (_) {
        LifecycleDiagnostics.event(
          'learning-realtime',
          'change lesson_progress',
        );
        onChange();
      },
    );
    return channel.subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    LifecycleDiagnostics.event('learning-realtime', 'unsubscribe');
    await client.removeChannel(channel);
  }
}

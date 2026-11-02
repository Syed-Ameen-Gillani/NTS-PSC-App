import 'package:supabase_flutter/supabase_flutter.dart';

/// Prevents an in-flight owner response from being reused after account switching.
class CourseRequestIdentity {
  CourseRequestIdentity(this.client) : userId = client.auth.currentUser?.id;
  final SupabaseClient client;
  final String? userId;

  void check() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Account changed. Please reopen this course.');
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/repositories/auth_repository.dart';
import 'package:nts_psc_app/core/repositories/supabase_auth_repository.dart';
import 'package:nts_psc_app/core/repositories/course_repository.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/core/repositories/quiz_repository.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static UserRole? restoredRole;
  static const bool usesSupabaseInProduction = true;

  // Normal debug, profile and release app runs always start with Supabase.
  // The test bootstrap overrides this for isolated mock fixtures only.
  static bool isSupabaseEnabled = true;
  static const bool areLessonCheckpointsEnabled = bool.fromEnvironment(
    'LESSON_CHECKPOINTS_ENABLED',
    defaultValue: false,
  );
  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String supabasePublishableKey = const String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static Future<void> loadPublicConfig() async {
    if (hasSupabaseConfiguration) return;
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/config/supabase_public.json'),
      );
      if (data is! Map<String, dynamic>) return;
      supabaseUrl = data['SUPABASE_URL'] as String? ?? '';
      supabasePublishableKey =
          data['SUPABASE_PUBLISHABLE_KEY'] as String? ?? '';
    } on FlutterError {
      // validate() reports a clear startup error when local config is absent.
    } on FormatException {
      // Malformed local config is treated as unavailable.
    }
  }

  static bool get hasSupabaseConfiguration =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validate() {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('SUPABASE_URL must be a valid HTTPS URL.');
    }
    if (!supabasePublishableKey.startsWith('sb_publishable_')) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is missing or invalid.');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AppConfig.isSupabaseEnabled
      ? SupabaseAuthRepository(Supabase.instance.client)
      : MockAuthRepository();
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return AppConfig.isSupabaseEnabled
      ? SupabaseCourseRepository(Supabase.instance.client)
      : MockCourseRepository();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return AppConfig.isSupabaseEnabled
      ? SupabaseQuizRepository(Supabase.instance.client)
      : MockQuizRepository();
});

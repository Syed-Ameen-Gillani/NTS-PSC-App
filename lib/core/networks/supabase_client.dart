import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/core/repositories/auth_repository.dart';
import 'package:nts_psc_app/core/repositories/course_repository.dart';
import 'package:nts_psc_app/core/repositories/quiz_repository.dart';

class AppConfig {
  static const bool isSupabaseEnabled = false;
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return MockCourseRepository();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return MockQuizRepository();
});

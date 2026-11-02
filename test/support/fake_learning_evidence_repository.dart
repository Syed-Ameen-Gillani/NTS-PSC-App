import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';

class FakeLearningEvidenceRepository extends LearningEvidenceRepository {
  FakeLearningEvidenceRepository()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  @override
  String? get user => 'student';
  @override
  Future<void> sync() async {}
  @override
  Future<Map<String, dynamic>?> videoSession(
    String lesson, {
    String? source,
  }) async => null;
  @override
  Future<Map<String, dynamic>> outcome(String lesson) async => {
    'completed': false,
    'activities': <dynamic>[],
  };
}

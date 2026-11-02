import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class CourseCertificate {
  const CourseCertificate({
    required this.url,
    required this.name,
    required this.course,
    required this.id,
    required this.completedAt,
  });
  final Uri url;
  final String name, course, id;
  final DateTime completedAt;
  static const _issuerUtcOffset = Duration(hours: 5);
  DateTime get certificateDate => completedAt.toUtc().add(_issuerUtcOffset);
}

class CourseCertificateRepository {
  CourseCertificateRepository(this.client);
  final SupabaseClient client;

  Future<CourseCertificate> prepare(String courseId) async {
    final response = await client.functions.invoke(
      'course-certificate',
      body: {'courseId': courseId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final row = Map<String, dynamic>.from(data['completion'] as Map);
    final url = Uri.parse(data['url'] as String);
    if (url.scheme != 'https') throw StateError('Certificate unavailable');
    return CourseCertificate(
      url: url,
      name: row['student_name'] as String,
      course: row['course_title'] as String,
      id: row['id'] as String,
      completedAt: DateTime.parse(row['completed_at'] as String),
    );
  }
}

final courseCertificateRepositoryProvider = Provider(
  (ref) => CourseCertificateRepository(Supabase.instance.client),
);

final courseCertificateProvider = FutureProvider.autoDispose
    .family<CourseCertificate, String>((ref, id) {
      final user = ref.watch(authControllerProvider).value?.user;
      if (user == null) throw StateError('Sign in required');
      return ref.watch(courseCertificateRepositoryProvider).prepare(id);
    });

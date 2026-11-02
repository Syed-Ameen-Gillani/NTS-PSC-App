import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_SUPABASE_INTEGRATION');
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  test('public Supabase catalog reads categories and courses', () async {
    final client = SupabaseClient(url, key);
    try {
      final repository = SupabaseCourseRepository(client);
      final categories = await repository.getCategories();
      expect(categories.map((category) => category.name), contains('FPSC'));
      expect(categories.map((category) => category.name), contains('NTS'));
      expect(
        categories.map((category) => category.name),
        contains('CSS / PMS'),
      );
      expect(categories.map((category) => category.name), contains('General'));
      expect(await repository.getCoursesByCategory(null), isA<List>());
      expect(await repository.getPublicTeachers(), isA<List>());
    } finally {
      client.dispose();
    }
  }, skip: !enabled);
}

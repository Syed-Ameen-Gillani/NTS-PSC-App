import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/course_reviews.dart';

final courseReviewsRepositoryProvider = Provider(
  (ref) => CourseReviewsRepository(Supabase.instance.client),
);

class CourseReviewsRepository {
  CourseReviewsRepository(this.client);
  final SupabaseClient client;
  Future<CourseReviewsPage> page(
    CourseReviewsKey key, {
    int offset = 0,
  }) async => CourseReviewsPage.fromJson(
    Map<String, dynamic>.from(
      await client
              .rpc(
                'get_course_reviews',
                params: {
                  'p_course_id': key.courseId,
                  'p_rating': key.rating,
                  'p_offset': offset,
                },
              )
              .timeout(const Duration(seconds: 15))
          as Map,
    ),
  );
  Future<void> save(String course, int rating, String body) async {
    await client
        .rpc(
          'save_course_review',
          params: {'p_course_id': course, 'p_rating': rating, 'p_body': body},
        )
        .timeout(const Duration(seconds: 15));
  }
}

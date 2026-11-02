import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/repositories/course_repository.dart';
import 'package:nts_psc_app/features/curriculum/data/course_outline_loader.dart';
import 'package:nts_psc_app/features/curriculum/data/course_request_identity.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_mapping.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_search.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_enrichment.dart';
import 'package:nts_psc_app/core/repositories/supabase_teacher_directory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository(this._client);

  final SupabaseClient _client;

  static const _courseSelect = '''
    id, instructor_id, title, description, image_path, pending_image_path, price_amount,
    status, is_featured, created_at, published_at,
    categories(id, name),
    course_modules(id, title, display_order,
      lessons(id, title, duration_seconds, video_path, external_video_url, notes,
        display_order, status))
  ''';

  @override
  Future<List<CourseModel>> getFeaturedCourses() => _loadCourses(
    publishedOnly: true,
    featuredOnly: true,
    includeProgress: true,
  );

  Future<List<CourseModel>> getFeaturedCoursesPreview() => _loadCourses(
    publishedOnly: true,
    featuredOnly: true,
    includeProgress: true,
    pageLimit: 4,
  );

  @override
  Future<List<CourseModel>> getContinueLearningCourses(
    String studentId,
  ) async => (await getEnrolledCourses(
    studentId,
  )).where((course) => course.learningComplete != true).toList();

  @override
  Future<List<CategoryModel>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name, slug, icon_key')
        .order('display_order');
    // Count on the server: the category header needs a number, not every
    // matching course row. These independent requests can run concurrently.
    final counts = await Future.wait(
      rows.map(
        (row) => _client
            .from('courses')
            .count(CountOption.exact)
            .eq('status', 'published')
            .eq('category_id', row['id'] as String),
      ),
    );
    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      final name = row['name'] as String;
      return CategoryModel(
        id: row['id'] as String,
        name: name,
        courseCount: counts[entry.key],
        iconType: categoryIconForSlug(row['slug'] as String),
      );
    }).toList();
  }

  @override
  Future<List<CourseModel>> getCoursesByCategory(String? category) async {
    if (category == null) {
      return _loadCourses(publishedOnly: true, includeProgress: true);
    }
    final row = await _client
        .from('categories')
        .select('id')
        .eq('name', category)
        .maybeSingle();
    if (row == null) return [];
    return _loadCourses(
      publishedOnly: true,
      categoryId: row['id'] as String,
      includeProgress: true,
    );
  }

  @override
  Future<List<CourseModel>> getNewCourses() =>
      _loadCourses(publishedOnly: true, includeProgress: true);

  /// Bounded landing-page preview. Full catalog routes use getNewCourses.
  Future<List<CourseModel>> getNewCoursesPage({
    required int offset,
    required int limit,
    String? category,
    bool featuredOnly = false,
  }) async {
    if (offset < 0 || limit < 1 || limit > 100) {
      throw ArgumentError('Invalid course page.');
    }
    String? categoryId;
    if (category != null) {
      final row = await _client
          .from('categories')
          .select('id')
          .eq('name', category)
          .maybeSingle();
      if (row == null) return [];
      categoryId = row['id'] as String;
    }
    return _loadCourses(
      publishedOnly: true,
      featuredOnly: featuredOnly,
      categoryId: categoryId,
      includeProgress: true,
      pageOffset: offset,
      pageLimit: limit,
    );
  }

  /// Returns one published search page. The RPC searches course, category and
  /// instructor text, and the regular catalog loader applies RLS to details.
  Future<List<CourseModel>> searchPublishedCourses(
    String query, {
    required int offset,
    int limit = 20,
  }) => SupabaseCourseSearch(
    _client,
    (ids) => _loadCourses(
      publishedOnly: true,
      courseIds: ids,
      includeProgress: true,
    ),
  ).search(query, offset: offset, limit: limit);

  @override
  Future<List<CourseModel>> getEnrolledCourses(String studentId) async {
    _requireUser(studentId);
    final enrollments = await _client
        .from('enrollments')
        .select('id, course_id')
        .eq('student_id', studentId)
        .inFilter('status', ['active', 'completed']);
    _requireUser(studentId);
    if (enrollments.isEmpty) return [];
    return _loadCourses(
      courseIds: [for (final row in enrollments) row['course_id'] as String],
      includeProgress: true,
      enrollmentRows: enrollments,
    );
  }

  Future<List<TeacherModel>> getPublicTeachers({int? limit, int offset = 0}) =>
      SupabaseTeacherDirectory(_client).list(limit: limit, offset: offset);

  Future<TeacherModel?> getPublicTeacher(String teacherId) =>
      SupabaseTeacherDirectory(_client).find(teacherId);

  @override
  Future<List<CourseModel>> getTeacherCourses(String teacherId) async {
    _requireUser(teacherId);
    final courses = await _loadCourses(instructorId: teacherId);
    return _withTeacherEnrollmentCounts(courses);
  }

  Future<List<CourseModel>> getPublicCoursesByTeacher(String teacherId) =>
      _loadCourses(
        publishedOnly: true,
        instructorId: teacherId,
        includeProgress: true,
      );

  @override
  Future<CourseModel?> getCourseById(String courseId) async {
    final courses = await _loadCourses(
      courseId: courseId,
      includeProgress: true,
    );
    for (final course in courses) {
      if (course.id == courseId) {
        if (course.instructorId == _client.auth.currentUser?.id) {
          return (await _withTeacherEnrollmentCounts([course])).single;
        }
        return course;
      }
    }
    return null;
  }

  Future<List<CourseModel>> _withTeacherEnrollmentCounts(
    List<CourseModel> courses,
  ) async {
    if (courses.isEmpty) return courses;
    final rows =
        await _client.rpc('get_teacher_course_learner_counts') as List<dynamic>;
    final counts = mapTeacherEnrollmentCounts(rows);
    return courses
        .map((course) => course.copyWith(enrolledCount: counts[course.id] ?? 0))
        .toList();
  }

  static Map<String, int> mapTeacherEnrollmentCounts(List<dynamic> rows) =>
      mapTeacherCounts(rows);

  @override
  Future<bool> enrollInCourse(String courseId, String studentId) async {
    _requireUser(studentId);
    await _client.rpc('enroll_free_course', params: {'p_course_id': courseId});
    return true;
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) throw StateError('Sign in to create a course.');
    final courseId =
        await _client.rpc(
              'create_priced_course_draft',
              params: {
                'p_course_id': course.id,
                'p_category': course.category,
                'p_title': course.title,
                'p_description': course.description,
                'p_price_amount':
                    course.priceAmount ??
                    (course.price == 'Free'
                        ? 0
                        : (throw ArgumentError(
                            'A paid course needs a numeric price.',
                          ))),
                'p_modules': course.modules
                    .map(
                      (module) => {
                        'title': module.title,
                        'lessons': module.lessons
                            .map(
                              (lesson) => {
                                'title': lesson.title,
                                'duration_seconds': lesson.durationMinutes * 60,
                                'notes': lesson.notes,
                              },
                            )
                            .toList(),
                      },
                    )
                    .toList(),
              },
            )
            as String;
    return (await getCourseById(courseId))!;
  }

  Future<CourseModuleModel> addModule(
    String courseId,
    String title,
    int order,
  ) async {
    final row = await _client
        .from('course_modules')
        .insert({'course_id': courseId, 'title': title, 'display_order': order})
        .select('id')
        .single();
    return CourseModuleModel(id: row['id'] as String, title: title);
  }

  Future<LessonModel> addLesson(
    String moduleId,
    LessonModel lesson,
    int order,
  ) async {
    final id = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(lesson.id)
        ? lesson.id
        : const Uuid().v4();
    final row = Map<String, dynamic>.from(
      await _client.rpc(
        'create_curriculum_lesson',
        params: {
          'p_id': id,
          'p_module_id': moduleId,
          'p_title': lesson.title,
          'p_duration_seconds': lesson.durationMinutes * 60,
          'p_external_video_url': lesson.videoUrl,
          'p_notes': lesson.notes,
        },
      ),
    );
    return lesson.copyWith(
      id: row['id'] as String,
      title: row['title'] as String,
      durationMinutes: ((row['duration_seconds'] as num) / 60).ceil(),
      videoUrl: row['external_video_url'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
    );
  }

  Future<bool> publishChanges(String courseId) async {
    // Read persisted details, not a potentially stale management-page model.
    final saved = await _client
        .from('courses')
        .select('description, image_path')
        .eq('id', courseId)
        .single();
    if ((saved['description'] as String? ?? '').trim().isEmpty) {
      throw const PostgrestException(
        message: 'Add a course description before publishing.',
      );
    }
    if ((saved['image_path'] as String? ?? '').trim().isEmpty) {
      throw const PostgrestException(
        message: 'Upload a course cover before publishing.',
      );
    }
    return await _client.rpc(
          'publish_course_changes',
          params: {'p_course_id': courseId},
        )
        as bool;
  }

  Future<void> deleteCourse(String courseId) =>
      _client.from('courses').delete().eq('id', courseId);

  @override
  Future<bool> updateLessonProgress({
    required String courseId,
    required String lessonId,
    required bool isCompleted,
  }) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) {
      throw StateError('Sign in to track lesson progress.');
    }
    await _client.rpc(
      'record_lesson_completion',
      params: {
        'p_course_id': courseId,
        'p_lesson_id': lessonId,
        'p_completed': isCompleted,
      },
    );
    return true;
  }

  Future<List<CourseModel>> _loadCourses({
    bool publishedOnly = false,
    bool featuredOnly = false,
    bool includeProgress = false,
    String? categoryId,
    String? instructorId,
    String? courseId,
    List<String>? courseIds,
    List<Map<String, dynamic>>? enrollmentRows,
    int? pageLimit,
    int pageOffset = 0,
  }) async {
    final requestIdentity = CourseRequestIdentity(_client);
    var query = _client.from('courses').select(_courseSelect);
    if (publishedOnly) query = query.eq('status', 'published');
    if (featuredOnly) query = query.eq('is_featured', true);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (instructorId != null) query = query.eq('instructor_id', instructorId);
    if (courseId != null) query = query.eq('id', courseId);
    if (courseIds != null) query = query.inFilter('id', courseIds);
    const pageSize = 100;
    final ordered = query.order('published_at', ascending: false).order('id');
    final rows = <Map<String, dynamic>>[];
    if (pageLimit != null) {
      rows.addAll(await ordered.range(pageOffset, pageOffset + pageLimit - 1));
    } else {
      for (var offset = 0; ; offset += pageSize) {
        final page = await ordered.range(offset, offset + pageSize - 1);
        rows.addAll(page);
        if (page.length < pageSize) break;
      }
    }
    if (rows.isEmpty) return [];
    await CourseOutlineLoader(_client).hydrate(rows);
    final teacherIds = {for (final row in rows) row['instructor_id'] as String};
    final teachers = teacherIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('public_teacher_profiles')
              .select('id, display_name')
              .inFilter('id', teacherIds.toList());
    final names = {
      for (final row in teachers)
        row['id'] as String: row['display_name'] as String,
    };
    final courses = await SupabaseCourseEnrichment(_client).enrich(
      rows
          .map(
            (row) => mapCourseRow(
              row,
              names,
              isOwner: row['instructor_id'] == _client.auth.currentUser?.id,
            ),
          )
          .toList(),
    );
    final userId = _client.auth.currentUser?.id;
    requestIdentity.check();
    if (!includeProgress || userId == null) return courses;
    final visibleCourseIds = {for (final course in courses) course.id};
    var enrollmentQuery = _client
        .from('enrollments')
        .select('id, course_id')
        .eq('student_id', userId)
        .inFilter('status', ['active', 'completed']);
    if (visibleCourseIds.length <= 100) {
      enrollmentQuery = enrollmentQuery.inFilter(
        'course_id',
        visibleCourseIds.toList(),
      );
    }
    final enrollments = enrollmentRows ?? await enrollmentQuery;
    requestIdentity.check();
    final visibleEnrollments = enrollments
        .where((row) => visibleCourseIds.contains(row['course_id']))
        .toList();
    if (visibleEnrollments.isEmpty) return courses;
    final eligibilityRows =
        await _client.rpc('get_my_course_eligibility') as List;
    final eligibility = {
      for (final row in eligibilityRows)
        row['course_id'] as String: Map<String, dynamic>.from(row as Map),
    };
    final enrollmentIds = {
      for (final row in visibleEnrollments)
        row['course_id'] as String: row['id'] as String,
    };
    final progressRows = await _client
        .from('lesson_progress')
        .select('enrollment_id, lesson_id, completed_at')
        .inFilter('enrollment_id', enrollmentIds.values.toList());
    requestIdentity.check();
    return courses.map((course) {
      final enrollmentId = enrollmentIds[course.id];
      if (enrollmentId == null) return course;
      final lessonIds = {
        for (final module in course.modules)
          for (final lesson in module.lessons) lesson.id,
      };
      final completedIds = progressRows
          .where(
            (row) =>
                row['enrollment_id'] == enrollmentId &&
                row['completed_at'] != null,
          )
          .map((row) => row['lesson_id'] as String)
          .toSet();
      return course.copyWith(
        learningComplete: eligibility[course.id]?['is_complete'] == true,
        remainingAssessments:
            ((eligibility[course.id]?['quizzes_remaining'] as num?)?.toInt() ??
                0) +
            ((eligibility[course.id]?['assignments_remaining'] as num?)
                    ?.toInt() ??
                0),
        progress: lessonIds.isEmpty
            ? 0.0
            : lessonIds.intersection(completedIds).length / lessonIds.length,
        modules: course.modules
            .map(
              (module) => CourseModuleModel(
                id: module.id,
                title: module.title,
                lessons: module.lessons
                    .map(
                      (lesson) => lesson.copyWith(
                        isCompleted: completedIds.contains(lesson.id),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    }).toList();
  }

  static CourseModel mapCourseRow(
    Map<String, dynamic> row,
    Map<String, String> names, {
    bool isOwner = false,
  }) => mapSupabaseCourseRow(row, names, isOwner: isOwner);

  void _requireUser(String userId) {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('Sign in again to continue.');
    }
  }
}

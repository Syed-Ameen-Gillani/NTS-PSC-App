import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/mock_teacher_data.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/home_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/catalog_pages_controller.dart';
import 'package:nts_psc_app/features/discover/presentation/controllers/category_courses_controller.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/domain/lesson_limits.dart';

class TeacherState {
  final TeacherStatsModel stats;
  final List<CourseModel> courses;
  final List<QuizModel> quizzes;
  final List<StudentDoubtModel> doubts;
  final List<LiveSessionModel> liveSessions;
  final List<StudentRosterModel> students;
  final List<RecentEnrollmentModel> recentEnrollments;
  // Retained for callers that construct teacher state; financial screens
  // fetch their own overview so this value never delays the studio.
  final TeacherFinancialOverview financialOverview;

  TeacherState({
    required this.stats,
    this.courses = const [],
    this.quizzes = const [],
    this.doubts = const [],
    this.liveSessions = const [],
    this.students = const [],
    this.recentEnrollments = const [],
    this.financialOverview = const TeacherFinancialOverview(),
  });

  TeacherState copyWith({
    TeacherStatsModel? stats,
    List<CourseModel>? courses,
    List<QuizModel>? quizzes,
    List<StudentDoubtModel>? doubts,
    List<LiveSessionModel>? liveSessions,
    List<StudentRosterModel>? students,
    List<RecentEnrollmentModel>? recentEnrollments,
    TeacherFinancialOverview? financialOverview,
  }) {
    return TeacherState(
      stats: stats ?? this.stats,
      courses: courses ?? this.courses,
      quizzes: quizzes ?? this.quizzes,
      doubts: doubts ?? this.doubts,
      liveSessions: liveSessions ?? this.liveSessions,
      students: students ?? this.students,
      recentEnrollments: recentEnrollments ?? this.recentEnrollments,
      financialOverview: financialOverview ?? this.financialOverview,
    );
  }
}

class TeacherController extends AsyncNotifier<TeacherState> {
  final _publishingCourses = <String>{};
  @override
  FutureOr<TeacherState> build() async {
    final courseRepo = ref.read(courseRepositoryProvider);
    final quizRepo = ref.read(quizRepositoryProvider);
    final insightsRepo = ref.read(teacherInsightsRepositoryProvider);

    final teacherId = AppConfig.isSupabaseEnabled
        ? ref.watch(
            authControllerProvider.select((state) => state.value?.user?.id),
          )
        : null;
    final coursesRequest = AppConfig.isSupabaseEnabled
        ? teacherId == null
              ? Future.value(<CourseModel>[])
              : courseRepo.getTeacherCourses(teacherId)
        : courseRepo.getTeacherCourses('teacher_1');
    final quizzesRequest = AppConfig.isSupabaseEnabled
        ? teacherId == null
              ? Future.value(<QuizModel>[])
              : quizRepo.getTeacherQuizzes(teacherId)
        : quizRepo.getTeacherQuizzes('teacher_1');
    final dashboardRequest = teacherId == null && AppConfig.isSupabaseEnabled
        ? Future.value(const TeacherDashboardOverview())
        : insightsRepo.getDashboardOverview();
    final courses = await coursesRequest;
    final quizzes = await quizzesRequest;
    final dashboardOverview = await dashboardRequest;

    return TeacherState(
      stats: TeacherStatsModel(
        totalStudents: dashboardOverview.totalStudents,
        activeCourses: dashboardOverview.activeCourses,
        totalQuizzes: quizzes.length,
        avgRating: AppConfig.isSupabaseEnabled ? 0 : 4.9,
        totalEarnings: '',
      ),
      courses: courses,
      quizzes: quizzes,
      doubts: AppConfig.isSupabaseEnabled ? [] : MockTeacherData.initialDoubts,
      liveSessions: AppConfig.isSupabaseEnabled
          ? []
          : MockTeacherData.initialLiveSessions,
      students: AppConfig.isSupabaseEnabled
          ? []
          : MockTeacherData.initialStudents,
      recentEnrollments: dashboardOverview.recentEnrollments,
    );
  }

  Future<CourseModel> addCourse(CourseModel course) async {
    final courseRepo = ref.read(courseRepositoryProvider);
    final created = await courseRepo.createCourse(course);
    final current = state.value;
    if (current != null) {
      final updatedCourses = [
        created,
        ...current.courses.where((item) => item.id != created.id),
      ];
      state = AsyncValue.data(
        current.copyWith(
          courses: updatedCourses,
          stats: TeacherStatsModel(
            totalStudents: current.stats.totalStudents,
            activeCourses: updatedCourses
                .where((item) => item.isPublished)
                .length,
            totalQuizzes: current.stats.totalQuizzes,
            avgRating: current.stats.avgRating,
            totalEarnings: current.stats.totalEarnings,
          ),
        ),
      );
    }
    return created;
  }

  Future<void> addModule(String courseId, String moduleTitle) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(courseRepositoryProvider);
    final course = current.courses.firstWhere((c) => c.id == courseId);
    final persisted = repo is SupabaseCourseRepository
        ? await repo.addModule(courseId, moduleTitle, course.modules.length)
        : null;
    final updatedCourses = current.courses.map((c) {
      if (c.id == courseId) {
        final newModule =
            persisted ??
            CourseModuleModel(
              id: 'm_${DateTime.now().millisecondsSinceEpoch}',
              title: moduleTitle,
              lessons: [],
            );
        return c.copyWith(
          modules: [...c.modules, newModule],
          isPublished: c.isPublished,
        );
      }
      return c;
    }).toList();

    state = AsyncValue.data(
      current.copyWith(courses: updatedCourses, stats: current.stats),
    );
  }

  void updateCourseCover(String courseId, String coverUrl) {
    final current = state.value;
    if (current == null) return;
    final updatedCourses = current.courses
        .map(
          (course) => course.id == courseId
              ? course.copyWith(coverUrl: coverUrl)
              : course,
        )
        .toList();
    state = AsyncValue.data(current.copyWith(courses: updatedCourses));
    ref.invalidate(homeControllerProvider);
    ref.invalidate(publishedCatalogProvider);
    ref.invalidate(featuredCatalogProvider);
    ref.invalidate(catalogPageProvider);
    ref.invalidate(allNewCoursesProvider);
    ref.invalidate(categoryCoursesProvider);
    ref.invalidate(allCategoriesProvider);
  }

  Future<LessonModel> addLesson(
    String courseId,
    String moduleId,
    LessonModel lesson,
  ) async {
    final current = state.value;
    if (current == null) throw StateError('Course data is not ready.');

    final repo = ref.read(courseRepositoryProvider);
    final course = current.courses.firstWhere((c) => c.id == courseId);
    final module = course.modules.firstWhere((m) => m.id == moduleId);
    if (module.lessons.length >= maxLessonsPerModule) {
      throw StateError('A module can have up to $maxLessonsPerModule lessons.');
    }
    final persisted = repo is SupabaseCourseRepository
        ? await repo.addLesson(moduleId, lesson, module.lessons.length)
        : lesson;
    final updatedCourses = current.courses.map((c) {
      if (c.id == courseId) {
        final updatedModules = c.modules.map((m) {
          if (m.id == moduleId) {
            return CourseModuleModel(
              id: m.id,
              title: m.title,
              lessons: m.lessons.any((item) => item.id == persisted.id)
                  ? m.lessons
                  : [...m.lessons, persisted],
            );
          }
          return m;
        }).toList();
        return c.copyWith(modules: updatedModules);
      }
      return c;
    }).toList();

    state = AsyncValue.data(
      current.copyWith(courses: updatedCourses, stats: current.stats),
    );
    return persisted;
  }

  Future<bool> togglePublishCourse(String courseId) async {
    if (!_publishingCourses.add(courseId)) {
      throw StateError('Course publication is already being updated.');
    }
    try {
      final current = state.value;
      if (current == null) return false;
      final repo = ref.read(courseRepositoryProvider);
      CourseModel? refreshed;
      var changed = !current.courses
          .firstWhere((c) => c.id == courseId)
          .isPublished;
      if (repo is SupabaseCourseRepository) {
        changed = await repo.publishChanges(courseId);
        try {
          refreshed = await repo.getCourseById(courseId);
        } catch (_) {
          // The release is committed; a refresh failure must not report it as failed.
        }
      }

      final updatedCourses = current.courses.map((c) {
        if (c.id == courseId) {
          return refreshed ?? c.copyWith(isPublished: true);
        }
        return c;
      }).toList();

      state = AsyncValue.data(
        current.copyWith(
          courses: updatedCourses,
          stats: TeacherStatsModel(
            totalStudents: current.stats.totalStudents,
            activeCourses: updatedCourses
                .where((item) => item.isPublished)
                .length,
            totalQuizzes: current.stats.totalQuizzes,
            avgRating: current.stats.avgRating,
            totalEarnings: current.stats.totalEarnings,
          ),
        ),
      );
      ref.invalidate(homeControllerProvider);
      ref.invalidate(publishedCatalogProvider);
      ref.invalidate(featuredCatalogProvider);
      ref.invalidate(catalogPageProvider);
      ref.invalidate(allNewCoursesProvider);
      ref.invalidate(categoryCoursesProvider);
      ref.invalidate(allCategoriesProvider);
      return changed;
    } finally {
      _publishingCourses.remove(courseId);
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(courseRepositoryProvider);
    if (repo is SupabaseCourseRepository) await repo.deleteCourse(courseId);

    final updatedCourses = current.courses
        .where((c) => c.id != courseId)
        .toList();
    state = AsyncValue.data(
      current.copyWith(
        courses: updatedCourses,
        stats: TeacherStatsModel(
          totalStudents: current.stats.totalStudents,
          activeCourses: updatedCourses.length,
          totalQuizzes: current.stats.totalQuizzes,
          avgRating: current.stats.avgRating,
          totalEarnings: current.stats.totalEarnings,
        ),
      ),
    );
    ref.invalidate(publishedCatalogProvider);
    ref.invalidate(featuredCatalogProvider);
    ref.invalidate(catalogPageProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(categoryCoursesProvider);
    ref.invalidate(allCategoriesProvider);
  }

  Future<void> addQuiz(QuizModel quiz) async {
    final quizRepo = ref.read(quizRepositoryProvider);
    final created = await quizRepo.createQuiz(quiz);
    _recordQuiz(created);
  }

  Future<QuizModel> generateAiQuiz({
    required String topic,
    required String difficulty,
    required int questionCount,
    required int durationMinutes,
  }) async {
    final quiz = await ref
        .read(quizRepositoryProvider)
        .generateAiQuiz(
          topic: topic,
          difficulty: difficulty,
          questionCount: questionCount,
          durationMinutes: durationMinutes,
        );
    _recordQuiz(quiz);
    return quiz;
  }

  Future<void> updateDraftQuiz(QuizModel quiz) async {
    if (quiz.isPublished) {
      throw StateError('Published quizzes cannot be edited');
    }
    final updated = await ref.read(quizRepositoryProvider).updateQuiz(quiz);
    _recordQuiz(updated);
  }

  void _recordQuiz(QuizModel created) {
    final current = state.value;
    if (current != null) {
      final updatedQuizzes = [
        created,
        ...current.quizzes.where((quiz) => quiz.id != created.id),
      ];
      state = AsyncValue.data(
        current.copyWith(
          quizzes: updatedQuizzes,
          stats: TeacherStatsModel(
            totalStudents: current.stats.totalStudents,
            activeCourses: current.stats.activeCourses,
            totalQuizzes: updatedQuizzes.length,
            avgRating: current.stats.avgRating,
            totalEarnings: current.stats.totalEarnings,
          ),
        ),
      );
    }
  }

  void markQuizLinked(String quizId, String courseId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        quizzes: current.quizzes
            .map(
              (quiz) => quiz.id == quizId
                  ? quiz.copyWith(courseId: courseId, isPublished: true)
                  : quiz,
            )
            .toList(),
      ),
    );
  }

  Future<void> answerDoubt(String doubtId, String answer) async {
    final current = state.value;
    if (current == null) return;

    final updatedDoubts = current.doubts.map((d) {
      if (d.id == doubtId) {
        return d.copyWith(answer: answer, isResolved: true);
      }
      return d;
    }).toList();

    state = AsyncValue.data(current.copyWith(doubts: updatedDoubts));
  }

  Future<void> scheduleLiveSession(LiveSessionModel session) async {
    final current = state.value;
    if (current == null) return;

    final updatedSessions = [session, ...current.liveSessions];
    state = AsyncValue.data(current.copyWith(liveSessions: updatedSessions));
  }

  Future<void> sendStudentNudge(
    String studentId, {
    String? customMessage,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updatedStudents = current.students.map((st) {
      if (st.id == studentId) {
        return st.copyWith(lastNudgedAt: DateTime.now());
      }
      return st;
    }).toList();

    state = AsyncValue.data(current.copyWith(students: updatedStudents));
  }
}

final teacherControllerProvider =
    AsyncNotifierProvider<TeacherController, TeacherState>(() {
      return TeacherController();
    });

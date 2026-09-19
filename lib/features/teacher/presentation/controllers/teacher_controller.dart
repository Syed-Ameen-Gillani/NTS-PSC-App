import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/mock_teacher_data.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

class TeacherState {
  final TeacherStatsModel stats;
  final List<CourseModel> courses;
  final List<QuizModel> quizzes;
  final List<StudentDoubtModel> doubts;
  final List<LiveSessionModel> liveSessions;
  final List<StudentRosterModel> students;
  final List<PayoutRecordModel> payouts;

  TeacherState({
    required this.stats,
    this.courses = const [],
    this.quizzes = const [],
    this.doubts = const [],
    this.liveSessions = const [],
    this.students = const [],
    this.payouts = const [],
  });

  TeacherState copyWith({
    TeacherStatsModel? stats,
    List<CourseModel>? courses,
    List<QuizModel>? quizzes,
    List<StudentDoubtModel>? doubts,
    List<LiveSessionModel>? liveSessions,
    List<StudentRosterModel>? students,
    List<PayoutRecordModel>? payouts,
  }) {
    return TeacherState(
      stats: stats ?? this.stats,
      courses: courses ?? this.courses,
      quizzes: quizzes ?? this.quizzes,
      doubts: doubts ?? this.doubts,
      liveSessions: liveSessions ?? this.liveSessions,
      students: students ?? this.students,
      payouts: payouts ?? this.payouts,
    );
  }
}

class TeacherController extends AsyncNotifier<TeacherState> {
  @override
  FutureOr<TeacherState> build() async {
    final courseRepo = ref.read(courseRepositoryProvider);
    final quizRepo = ref.read(quizRepositoryProvider);

    final courses = await courseRepo.getTeacherCourses('teacher_1');
    final quizzes = await quizRepo.getTeacherQuizzes('teacher_1');

    return TeacherState(
      stats: TeacherStatsModel(
        totalStudents: 1240,
        activeCourses: courses.length,
        totalQuizzes: quizzes.length,
        avgRating: 4.9,
        totalEarnings: 'Rs 84,500',
      ),
      courses: courses,
      quizzes: quizzes,
      doubts: MockTeacherData.initialDoubts,
      liveSessions: MockTeacherData.initialLiveSessions,
      students: MockTeacherData.initialStudents,
      payouts: MockTeacherData.initialPayouts,
    );
  }

  Future<void> addCourse(CourseModel course) async {
    final courseRepo = ref.read(courseRepositoryProvider);
    final created = await courseRepo.createCourse(course);
    final current = state.value;
    if (current != null) {
      final updatedCourses = [created, ...current.courses];
      state = AsyncValue.data(current.copyWith(
        courses: updatedCourses,
        stats: TeacherStatsModel(
          totalStudents: current.stats.totalStudents,
          activeCourses: updatedCourses.length,
          totalQuizzes: current.stats.totalQuizzes,
          avgRating: current.stats.avgRating,
          totalEarnings: current.stats.totalEarnings,
        ),
      ));
    }
  }

  Future<void> addModule(String courseId, String moduleTitle) async {
    final current = state.value;
    if (current == null) return;

    final updatedCourses = current.courses.map((c) {
      if (c.id == courseId) {
        final newModule = CourseModuleModel(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
          title: moduleTitle,
          lessons: [],
        );
        return c.copyWith(modules: [...c.modules, newModule]);
      }
      return c;
    }).toList();

    state = AsyncValue.data(current.copyWith(courses: updatedCourses));
  }

  Future<void> addLesson(String courseId, String moduleId, LessonModel lesson) async {
    final current = state.value;
    if (current == null) return;

    final updatedCourses = current.courses.map((c) {
      if (c.id == courseId) {
        final updatedModules = c.modules.map((m) {
          if (m.id == moduleId) {
            return CourseModuleModel(
              id: m.id,
              title: m.title,
              lessons: [...m.lessons, lesson],
            );
          }
          return m;
        }).toList();
        return c.copyWith(modules: updatedModules);
      }
      return c;
    }).toList();

    state = AsyncValue.data(current.copyWith(courses: updatedCourses));
  }

  Future<void> togglePublishCourse(String courseId) async {
    final current = state.value;
    if (current == null) return;

    final updatedCourses = current.courses.map((c) {
      if (c.id == courseId) {
        return c.copyWith(isPublished: !c.isPublished);
      }
      return c;
    }).toList();

    state = AsyncValue.data(current.copyWith(courses: updatedCourses));
  }

  Future<void> deleteCourse(String courseId) async {
    final current = state.value;
    if (current == null) return;

    final updatedCourses = current.courses.where((c) => c.id != courseId).toList();
    state = AsyncValue.data(current.copyWith(
      courses: updatedCourses,
      stats: TeacherStatsModel(
        totalStudents: current.stats.totalStudents,
        activeCourses: updatedCourses.length,
        totalQuizzes: current.stats.totalQuizzes,
        avgRating: current.stats.avgRating,
        totalEarnings: current.stats.totalEarnings,
      ),
    ));
  }

  Future<void> addQuiz(QuizModel quiz) async {
    final quizRepo = ref.read(quizRepositoryProvider);
    final created = await quizRepo.createQuiz(quiz);
    final current = state.value;
    if (current != null) {
      final updatedQuizzes = [created, ...current.quizzes];
      state = AsyncValue.data(current.copyWith(
        quizzes: updatedQuizzes,
        stats: TeacherStatsModel(
          totalStudents: current.stats.totalStudents,
          activeCourses: current.stats.activeCourses,
          totalQuizzes: updatedQuizzes.length,
          avgRating: current.stats.avgRating,
          totalEarnings: current.stats.totalEarnings,
        ),
      ));
    }
  }

  Future<void> answerDoubt(String doubtId, String answer) async {
    final current = state.value;
    if (current == null) return;

    final updatedDoubts = current.doubts.map((d) {
      if (d.id == doubtId) {
        return d.copyWith(
          answer: answer,
          isResolved: true,
        );
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

  Future<void> requestPayout({
    required String amount,
    required String method,
    required String accountNumber,
  }) async {
    final current = state.value;
    if (current == null) return;

    final newPayout = PayoutRecordModel(
      id: 'po_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      amount: amount,
      method: method,
      accountNumber: accountNumber,
      date: 'Today, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      status: 'Processing',
    );

    final updatedPayouts = [newPayout, ...current.payouts];
    state = AsyncValue.data(current.copyWith(payouts: updatedPayouts));
  }

  Future<void> sendStudentNudge(String studentId, {String? customMessage}) async {
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

final teacherControllerProvider = AsyncNotifierProvider<TeacherController, TeacherState>(() {
  return TeacherController();
});

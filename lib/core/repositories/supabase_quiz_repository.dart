import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/repositories/quiz_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseQuizRepository implements QuizRepository {
  SupabaseQuizRepository(this._client);

  final SupabaseClient _client;
  static const _quizProjection =
      'id, teacher_id, course_id, title, category, difficulty, duration_minutes, passing_score, is_ai_generated, status, quiz_questions(id, display_order, question_text, options)';
  Future<Map<String, dynamic>> sessionStatus(String id) async =>
      Map<String, dynamic>.from(
        await _client.rpc(
          'get_quiz_session_status',
          params: {'p_session_id': id},
        ),
      );

  Future<Map<String, dynamic>> startSession(String quizId) async =>
      Map<String, dynamic>.from(
        await _client.rpc('start_quiz_session', params: {'p_quiz_id': quizId}),
      );

  Future<void> saveSession(String sessionId, Map<String, int> answers) async {
    await _client.rpc(
      'save_quiz_session',
      params: {'p_session_id': sessionId, 'p_answers': answers},
    );
  }

  Future<QuizSubmissionResultModel> finishSession(String sessionId) async =>
      mapReviewRow(
        Map<String, dynamic>.from(
          await _client.rpc(
            'finish_quiz_session',
            params: {'p_session_id': sessionId},
          ),
        ),
      );

  Future<({int attempts, double averagePercent})> getTeacherQuizSummary(
    String quizId,
  ) async {
    _userId;
    final rows = await _client
        .from('quiz_attempts')
        .select('score,total_questions')
        .eq('quiz_id', quizId);
    if (rows.isEmpty) return (attempts: 0, averagePercent: 0.0);
    final total = rows.fold<double>(0, (sum, row) {
      final questions = (row['total_questions'] as num).toDouble();
      return sum +
          (questions == 0
              ? 0
              : (row['score'] as num).toDouble() / questions * 100);
    });
    return (attempts: rows.length, averagePercent: total / rows.length);
  }

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in to access quizzes.'));

  @override
  Future<List<QuizModel>> getCourseQuizzes() async =>
      (await _loadQuizzes()).where((quiz) => quiz.isPublished).toList();

  @override
  Future<List<QuizModel>> getTeacherQuizzes(String teacherId) async {
    if (teacherId != _userId) throw StateError('Teacher identity mismatch.');
    return (await _loadQuizzes())
        .where((quiz) => _teacherQuizIds.contains(quiz.id))
        .toList();
  }

  final Set<String> _teacherQuizIds = {};

  Future<int> getWeeklyAttemptCount() async {
    final userId = _userId;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final rows = await _client
        .from('quiz_attempts')
        .select('id')
        .eq('student_id', userId)
        .gte('submitted_at', weekStart.toUtc().toIso8601String());
    return rows.length;
  }

  @override
  Future<QuizModel?> getQuizById(String quizId) async {
    final userId = _userId;
    final row = await _client
        .from('quizzes')
        .select(_quizProjection)
        .eq('id', quizId)
        .maybeSingle();
    if (row == null) return null;
    final questions = (row['quiz_questions'] as List<dynamic>?) ?? [];
    final ids = [
      for (final question in questions)
        (question as Map<String, dynamic>)['id'] as String,
    ];
    final keys = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('quiz_answer_keys')
              .select('question_id, correct_option_index, explanation')
              .inFilter('question_id', ids);
    final attempts = await _client
        .from('quiz_attempts')
        .select('id, score, total_questions')
        .eq('student_id', userId)
        .eq('quiz_id', quizId)
        .order('submitted_at');
    final latest = attempts.isEmpty ? null : attempts.last;
    return mapQuizRow(
      row,
      keyByQuestion: {
        for (final key in keys) key['question_id'] as String: key,
      },
      score: latest == null
          ? null
          : '${latest['score']}/${latest['total_questions']}',
      attemptId: latest?['id'] as String?,
    );
  }

  @override
  Future<QuizSubmissionResultModel?> getAttemptResult(String attemptId) async {
    _userId;
    final row =
        await _client.rpc(
              'get_quiz_attempt_review',
              params: {'p_attempt_id': attemptId},
            )
            as Map<String, dynamic>;
    return mapReviewRow(row);
  }

  @override
  Future<QuizModel> generateAiQuiz({
    required String topic,
    required String difficulty,
    required int questionCount,
    required int durationMinutes,
  }) async {
    if (questionCount < 1 ||
        questionCount > 10 ||
        !const [5, 10, 15, 20, 30].contains(durationMinutes)) {
      throw ArgumentError('Choose 1-10 questions and a supported timer.');
    }
    _userId;
    final response = await _client.functions.invoke(
      'generate-ai-quiz',
      body: {
        'topic': topic.trim(),
        'difficulty': difficulty,
        'questionCount': questionCount,
        'durationMinutes': durationMinutes,
      },
    );
    final data = response.data;
    if (data is! Map || data['quizId'] is! String) {
      throw StateError('AI quiz draft was not returned by the server.');
    }
    return await getQuizById(data['quizId'] as String) ??
        (throw StateError('Generated quiz draft is unavailable.'));
  }

  @override
  Future<QuizSubmissionResultModel> submitQuiz({
    required String quizId,
    required Map<int, int> userAnswers,
  }) async {
    _userId;
    final quiz = await getQuizById(quizId);
    if (quiz == null || !quiz.isPublished) {
      throw StateError('Quiz unavailable.');
    }
    final answers = <String, int>{};
    for (final entry in userAnswers.entries) {
      if (entry.key < 0 || entry.key >= quiz.questions.length) {
        throw ArgumentError('Unknown question index.');
      }
      answers[quiz.questions[entry.key].id] = entry.value;
    }
    final row =
        await _client.rpc(
              'submit_quiz',
              params: {'p_quiz_id': quizId, 'p_answers': answers},
            )
            as Map<String, dynamic>;
    return mapReviewRow(row);
  }

  static QuizSubmissionResultModel mapReviewRow(Map<String, dynamic> row) {
    final review = (row['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final reviewedQuestions = review
        .map(
          (question) => QuizQuestionModel(
            id: question['id'] as String,
            questionText: question['question_text'] as String,
            options: (question['options'] as List<dynamic>).cast<String>(),
            correctOptionIndex: question['correct_option_index'] as int,
            explanation: question['explanation'] as String,
          ),
        )
        .toList();
    final reviewedAnswers = <int, int>{};
    for (var i = 0; i < review.length; i++) {
      final selected = review[i]['selected_option_index'] as int?;
      if (selected != null) reviewedAnswers[i] = selected;
    }
    return QuizSubmissionResultModel(
      attemptId: row['attempt_id'] as String,
      passingScore: row['passing_score'] as int? ?? 60,
      quizId: row['quiz_id'] as String,
      quizTitle: row['quiz_title'] as String,
      score: row['score'] as int,
      totalQuestions: row['total_questions'] as int,
      userAnswers: reviewedAnswers,
      questions: reviewedQuestions,
    );
  }

  @override
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    return _saveQuiz(quiz, create: true);
  }

  @override
  Future<QuizModel> updateQuiz(QuizModel quiz) async {
    _userId;
    if (quiz.isPublished) {
      throw StateError('Published quizzes cannot be edited.');
    }
    return _saveQuiz(quiz, create: false);
  }

  Future<QuizModel> _saveQuiz(QuizModel quiz, {required bool create}) async {
    _userId;
    final id =
        await _client.rpc(
              'save_teacher_quiz',
              params: {
                'p_quiz_id': create ? null : quiz.id,
                'p_title': quiz.title.trim(),
                'p_category': quiz.category,
                'p_difficulty': quiz.difficulty,
                'p_duration_minutes': quiz.durationMinutes,
                'p_passing_score': quiz.passingScore,
                'p_is_ai_generated': quiz.isAiGenerated,
                'p_publish': quiz.isPublished,
                'p_questions': questionPayload(quiz.questions),
              },
            )
            as String;
    return await getQuizById(id) ??
        (throw StateError(
          'Quiz saved, but could not be loaded. Refresh quizzes.',
        ));
  }

  static List<Map<String, dynamic>> questionPayload(
    List<QuizQuestionModel> questions,
  ) {
    if (questions.isEmpty) throw ArgumentError('Add at least one question.');
    return questions.map((question) {
      if (question.questionText.trim().isEmpty ||
          question.options.length < 2 ||
          question.options.length > 6 ||
          question.options.any((option) => option.trim().isEmpty) ||
          question.correctOptionIndex < 0 ||
          question.correctOptionIndex >= question.options.length) {
        throw ArgumentError('Each question needs options and a valid answer.');
      }
      return <String, dynamic>{
        'question_text': question.questionText.trim(),
        'options': question.options.map((option) => option.trim()).toList(),
        'correct_option_index': question.correctOptionIndex,
        'explanation': question.explanation,
      };
    }).toList();
  }

  Future<List<QuizModel>> _loadQuizzes() async {
    final userId = _userId;
    final rows = await _client
        .from('quizzes')
        .select(_quizProjection)
        .order('created_at', ascending: false);
    _teacherQuizIds
      ..clear()
      ..addAll(
        rows
            .where((row) => row['teacher_id'] == userId)
            .map((row) => row['id'] as String),
      );
    final questionIds = [
      for (final row in rows)
        for (final question in (row['quiz_questions'] as List<dynamic>))
          (question as Map<String, dynamic>)['id'] as String,
    ];
    final keys = questionIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('quiz_answer_keys')
              .select('question_id, correct_option_index, explanation')
              .inFilter('question_id', questionIds);
    final keyByQuestion = {
      for (final key in keys) key['question_id'] as String: key,
    };
    final attempts = await _client
        .from('quiz_attempts')
        .select('id, quiz_id, score, total_questions')
        .eq('student_id', userId)
        .order('submitted_at');
    final scoreByQuiz = {
      for (final attempt in attempts)
        attempt['quiz_id'] as String:
            '${attempt['score']}/${attempt['total_questions']}',
    };
    final attemptIdByQuiz = {
      for (final attempt in attempts)
        attempt['quiz_id'] as String: attempt['id'] as String,
    };
    return rows
        .map(
          (row) => mapQuizRow(
            row,
            keyByQuestion: keyByQuestion,
            score: scoreByQuiz[row['id']],
            attemptId: attemptIdByQuiz[row['id']],
          ),
        )
        .toList();
  }

  static QuizModel mapQuizRow(
    Map<String, dynamic> row, {
    Map<String, Map<String, dynamic>> keyByQuestion = const {},
    String? score,
    String? attemptId,
  }) {
    final questions =
        (row['quiz_questions'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
          ..sort(
            (a, b) => (a['display_order'] as int).compareTo(
              b['display_order'] as int,
            ),
          );
    return QuizModel(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      isAiGenerated: row['is_ai_generated'] as bool,
      totalQuestions: questions.length,
      score: score,
      attemptId: attemptId,
      durationMinutes: row['duration_minutes'] as int,
      passingScore: row['passing_score'] as int,
      difficulty: row['difficulty'] as String,
      isPublished: row['status'] == 'published',
      courseId: row['course_id'] as String?,
      questions: questions.map((question) {
        final key = keyByQuestion[question['id']];
        return QuizQuestionModel(
          id: question['id'] as String,
          questionText: question['question_text'] as String,
          options: (question['options'] as List<dynamic>).cast<String>(),
          correctOptionIndex: key?['correct_option_index'] as int? ?? -1,
          explanation: key?['explanation'] as String? ?? '',
        );
      }).toList(),
    );
  }
}

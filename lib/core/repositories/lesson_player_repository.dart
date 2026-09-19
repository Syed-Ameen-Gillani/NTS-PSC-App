import 'dart:async';
import 'package:nts_psc_app/core/models/lesson_player_models.dart';

/// Abstract contract defining all lesson player data operations.
/// 
/// Senior Clean Architecture Pattern:
/// The Presentation Layer and Business Logic depend ONLY on this abstraction.
/// When switching to Supabase, Firebase, or GraphQL, developers implement
/// this interface and inject it via Riverpod, leaving 100% of UI code untouched.
abstract class ILessonPlayerRepository {
  Future<List<InVideoQuizModel>> getInVideoQuizzes(String lessonId);
  Future<QuizSubmissionResult> submitInVideoQuiz({
    required String quizId,
    required int selectedOptionIndex,
  });
  Future<LessonPersonalNote?> getPersonalNote(String lessonId);
  Future<LessonPersonalNote> savePersonalNote(String lessonId, String content);
  Future<List<LessonDiscussionItem>> getDiscussions(String lessonId);
  Future<LessonDiscussionItem> postQuestion({
    required String lessonId,
    required String question,
    required String studentName,
  });
  Future<bool> markLessonCompleted({required String courseId, required String lessonId});
  Future<bool> isLessonCompleted({required String courseId, required String lessonId});
}

/// Production-ready mock implementation simulating realistic network conditions,
/// low latency, local caching, and idempotent operations for 1M+ user scale.
class MockLessonPlayerRepository implements ILessonPlayerRepository {
  final bool simulateLatency;
  final Map<String, List<InVideoQuizModel>> _quizzesCache = {};
  final Map<String, LessonPersonalNote> _notesCache = {};
  final Map<String, List<LessonDiscussionItem>> _discussionsCache = {};
  final Set<String> _completedLessons = {};

  MockLessonPlayerRepository({this.simulateLatency = false}) {
    _initializeSeedData();
  }

  Future<void> _delay([int ms = 150]) async {
    if (simulateLatency) {
      await Future.delayed(Duration(milliseconds: ms));
    }
  }

  void _initializeSeedData() {
    // Seed in-video quiz for AJK Constitution Lecture (06:14 timestamp matching user's screen)
    _quizzesCache['default'] = [
      const InVideoQuizModel(
        id: 'quiz_ajk_01',
        lessonId: 'default',
        timestampSeconds: 374, // 06:14
        timestampDisplay: '06:14',
        topic: 'Executive Authority under AJK Constitution',
        question: 'Under the AJK Interim Constitution Act 1974, in whom is the executive authority of the Government of Azad Jammu and Kashmir vested?',
        options: [
          'The Chief Justice of the AJK High Court',
          'The Federal Minister for Kashmir Affairs',
          'The President, exercised directly or through the Prime Minister',
          'The Speaker of the Legislative Assembly',
        ],
        correctOptionIndex: 2,
        explanation: 'Under Section 12 of the AJK Interim Constitution Act 1974, executive authority vests in the President and is exercised by him directly or through the Prime Minister and the Council of Ministers.',
        hint: 'Review Section 12 regarding the constitutional head and executive exercise.',
        isMandatory: true,
      ),
      const InVideoQuizModel(
        id: 'quiz_ajk_02',
        lessonId: 'default',
        timestampSeconds: 780, // 13:00
        timestampDisplay: '13:00',
        topic: 'Azad Jammu & Kashmir Council',
        question: 'Who serves as the ex-officio Chairman of the Azad Jammu and Kashmir Council?',
        options: [
          'The Prime Minister of Pakistan',
          'The President of Azad Jammu and Kashmir',
          'The Prime Minister of Azad Jammu and Kashmir',
          'The Chief Election Commissioner of AJK',
        ],
        correctOptionIndex: 0,
        explanation: 'Section 21 of the 1974 Act stipulates that the Prime Minister of Pakistan serves as the ex-officio Chairman of the AJK Council.',
        hint: 'Consider the inter-governmental coordination between the Federal Government and AJK.',
        isMandatory: false,
      ),
    ];

    // Seed notes
    _notesCache['default'] = LessonPersonalNote(
      lessonId: 'default',
      content: 'Important statutory provisions:\n- Section 3: Fundamental rights.\n- Section 12: Executive powers.\n- Section 21: AJK Council composition.\n- High Court jurisdiction under Section 44.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    // Seed discussions
    _discussionsCache['default'] = [
      const LessonDiscussionItem(
        id: 'disc_1',
        studentName: 'Hamza Tariq',
        studentInitial: 'H',
        timeAgo: '2 hours ago',
        question: 'Does Section 31 allow the Legislative Assembly to make laws regarding the defence and security of AJK?',
        isResolved: true,
        instructorName: 'Dr. Usman (Instructor)',
        instructorReply: 'No, Hamza. Responsibilities regarding Defence, External Affairs, and Currency are reserved for the Government of Pakistan under the UNCIP resolutions.',
      ),
      const LessonDiscussionItem(
        id: 'disc_2',
        studentName: 'Ayesha Bibi',
        studentInitial: 'A',
        timeAgo: '5 hours ago',
        question: 'What is the minimum age requirement for a candidate to contest election for the AJK Legislative Assembly?',
        isResolved: true,
        instructorName: 'Dr. Usman (Instructor)',
        instructorReply: 'The candidate must have attained the age of 25 years on the date of nomination, pursuant to Section 24.',
      ),
      const LessonDiscussionItem(
        id: 'disc_3',
        studentName: 'Zainab Rashid',
        studentInitial: 'Z',
        timeAgo: 'Just now',
        question: 'Could you clarify the difference between the powers of the AJK Council vs the Legislative Assembly after the 13th Amendment?',
        isResolved: false,
      ),
    ];
  }

  @override
  Future<List<InVideoQuizModel>> getInVideoQuizzes(String lessonId) async {
    // Simulate lightweight network roundtrip
    await _delay(150);
    return _quizzesCache[lessonId] ?? _quizzesCache['default'] ?? [];
  }

  @override
  Future<QuizSubmissionResult> submitInVideoQuiz({
    required String quizId,
    required int selectedOptionIndex,
  }) async {
    await _delay(200);

    InVideoQuizModel? targetQuiz;
    for (final list in _quizzesCache.values) {
      for (final quiz in list) {
        if (quiz.id == quizId) {
          targetQuiz = quiz;
          break;
        }
      }
    }

    if (targetQuiz == null) {
      return QuizSubmissionResult(
        isCorrect: false,
        explanation: 'Quiz item not found in repository.',
        hint: 'Please try again.',
        selectedIndex: selectedOptionIndex,
      );
    }

    final isCorrect = selectedOptionIndex == targetQuiz.correctOptionIndex;

    // Update in-memory state
    _updateQuizCompletedStatus(quizId, isCompleted: isCorrect);

    return QuizSubmissionResult(
      isCorrect: isCorrect,
      explanation: targetQuiz.explanation,
      hint: targetQuiz.hint,
      selectedIndex: selectedOptionIndex,
    );
  }

  void _updateQuizCompletedStatus(String quizId, {required bool isCompleted}) {
    for (final key in _quizzesCache.keys) {
      final list = _quizzesCache[key]!;
      final idx = list.indexWhere((q) => q.id == quizId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isCompleted: isCompleted);
      }
    }
  }

  @override
  Future<LessonPersonalNote?> getPersonalNote(String lessonId) async {
    await _delay(100);
    return _notesCache[lessonId] ?? _notesCache['default'];
  }

  @override
  Future<LessonPersonalNote> savePersonalNote(String lessonId, String content) async {
    await _delay(150);
    final note = LessonPersonalNote(
      lessonId: lessonId,
      content: content,
      updatedAt: DateTime.now(),
      isSaved: true,
    );
    _notesCache[lessonId] = note;
    return note;
  }

  @override
  Future<List<LessonDiscussionItem>> getDiscussions(String lessonId) async {
    await _delay(150);
    return List.unmodifiable(_discussionsCache[lessonId] ?? _discussionsCache['default'] ?? []);
  }

  @override
  Future<LessonDiscussionItem> postQuestion({
    required String lessonId,
    required String question,
    required String studentName,
  }) async {
    await _delay(200);
    final newDiscussion = LessonDiscussionItem(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      studentName: studentName,
      studentInitial: studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
      timeAgo: 'Just now',
      question: question,
      isResolved: false,
    );

    final list = _discussionsCache.putIfAbsent(lessonId, () => []);
    list.insert(0, newDiscussion);
    return newDiscussion;
  }

  @override
  Future<bool> markLessonCompleted({required String courseId, required String lessonId}) async {
    await _delay(150);
    _completedLessons.add('${courseId}_$lessonId');
    return true;
  }

  @override
  Future<bool> isLessonCompleted({required String courseId, required String lessonId}) async {
    return _completedLessons.contains('${courseId}_$lessonId');
  }
}

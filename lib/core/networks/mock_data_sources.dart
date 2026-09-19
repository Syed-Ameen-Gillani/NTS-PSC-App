import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/repositories/auth_repository.dart';
import 'package:nts_psc_app/core/repositories/course_repository.dart';
import 'package:nts_psc_app/core/repositories/quiz_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      id: role == UserRole.teacher ? 'teacher_1' : 'student_1',
      name: role == UserRole.teacher ? 'Sir Tariq Mahmood' : 'Ameen Gillani',
      email: email,
      imagePath: role == UserRole.teacher ? AppAssets.teacher1 : AppAssets.appLogo,
      isPremium: true,
      courses: role == UserRole.teacher ? 4 : 3,
      quizzes: role == UserRole.teacher ? 12 : 8,
      avgScore: 88,
      role: role,
      subject: role == UserRole.teacher ? 'Pakistan Affairs & GK' : null,
      qualification: role == UserRole.teacher ? 'M.Phil Political Science / Former Civil Servant' : null,
      bio: role == UserRole.teacher ? 'Mentoring CSS, PMS, FPSC, and AJK PSC candidates for over 8 years.' : null,
      totalEarnings: 84500.0,
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      imagePath: role == UserRole.teacher ? AppAssets.teacher1 : AppAssets.appLogo,
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
      role: role,
      subject: subject,
      qualification: qualification,
      bio: bio,
      totalEarnings: 0.0,
    );
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

class MockCourseRepository implements CourseRepository {
  final List<CourseModel> _allCourses = [
    CourseModel(
      id: 'c1',
      title: 'FPSC Inspector Customs & Intelligence Officer',
      author: 'Sir Tariq',
      rating: 4.9,
      price: 'Rs 2,500',
      imagePath: AppAssets.course4,
      isFeatured: true,
      category: 'FPSC',
      enrolledCount: 340,
      description: 'Comprehensive preparation for FPSC Inspector Customs. Covers Customs Act 1969, General Knowledge, Pakistan Affairs, Everyday Science, and Current Affairs with past papers practice.',
      modules: [
        CourseModuleModel(
          id: 'm1',
          title: 'Module 1: Customs Act 1969 Foundations',
          lessons: [
            LessonModel(
              id: 'l1',
              title: 'Introduction & Key Definitions in Customs Act',
              durationMinutes: 24,
              videoUrl: 'https://example.com/customs_intro.mp4',
              notes: 'Focus on Sections 1 through 9. Understand jurisdiction and appointing customs officers.',
              isCompleted: true,
            ),
            LessonModel(
              id: 'l2',
              title: 'Import & Export Clearance Procedures',
              durationMinutes: 32,
              videoUrl: 'https://example.com/customs_clearance.mp4',
              notes: 'Detailed overview of bill of entry, assessment of duty, and clearance timelines.',
              isCompleted: false,
            ),
          ],
        ),
        CourseModuleModel(
          id: 'm2',
          title: 'Module 2: General Knowledge & Current Affairs',
          lessons: [
            LessonModel(
              id: 'l3',
              title: 'International Organizations & Treaties',
              durationMinutes: 28,
              videoUrl: 'https://example.com/treaties.mp4',
              notes: 'UN organs, Bretton Woods institutions, SCO, and Pakistan relations.',
            ),
            LessonModel(
              id: 'l4',
              title: 'Pakistan Economic Geography & Border Posts',
              durationMinutes: 20,
              videoUrl: 'https://example.com/pak_geography.mp4',
              notes: 'Major dry ports, sea ports (Gwadar, Karachi, Qasim), and Torkham/Chaman corridors.',
            ),
          ],
        ),
      ],
    ),
    CourseModel(
      id: 'c2',
      title: 'AJK PSC General Recruitment Masterclass',
      author: 'Dr. Usman',
      rating: 4.8,
      price: 'Rs 2,000',
      imagePath: AppAssets.course1,
      isFeatured: true,
      category: 'AJK PSC',
      enrolledCount: 210,
      description: 'Complete syllabus guide for Azad Jammu & Kashmir PSC examinations, covering Kashmir Studies, Pakistan Studies, Islamic Studies, and General Ability.',
      modules: [
        CourseModuleModel(
          id: 'm3',
          title: 'Section A: Kashmir History & Constitutional Framework',
          lessons: [
            LessonModel(
              id: 'l5',
              title: 'Treaty of Amritsar (1846) to 1947 Events',
              durationMinutes: 30,
              videoUrl: 'https://example.com/kashmir_history.mp4',
              notes: 'Dogra rule, 1931 agitation, and formation of Azad Jammu & Kashmir government.',
              isCompleted: true,
            ),
            LessonModel(
              id: 'l6',
              title: 'AJK Interim Constitution Act 1974',
              durationMinutes: 25,
              videoUrl: 'https://example.com/ajk_constitution.mp4',
              notes: 'Structure of AJK Legislative Assembly, Council, and High Court/Supreme Court.',
            ),
          ],
        ),
      ],
    ),
    CourseModel(
      id: 'c3',
      title: 'Everyday Science Complete Crash Course',
      author: 'Dr. Usman',
      rating: 4.7,
      price: 'Rs 1,800',
      imagePath: AppAssets.course2,
      progress: 0.45,
      category: 'CSS & PMS',
      enrolledCount: 520,
      description: 'Master Physical Sciences, Biological Sciences, Environmental Science, and Basic Computer Science concepts tested in competitive exams.',
      modules: [
        CourseModuleModel(
          id: 'm4',
          title: 'Physical Sciences',
          lessons: [
            LessonModel(
              id: 'l7',
              title: 'Solar System & Astronomy Basics',
              durationMinutes: 22,
              notes: 'Planetary order, Kepler laws overview, and solar phenomena.',
              isCompleted: true,
            ),
            LessonModel(
              id: 'l8',
              title: 'Energy, Thermodynamics & Electromagnetism',
              durationMinutes: 29,
              notes: 'Forms of energy, laws of thermodynamics, practical everyday applications.',
              isCompleted: true,
            ),
          ],
        ),
      ],
    ),
    CourseModel(
      id: 'c4',
      title: 'English Grammar & Precis Writing Basics',
      author: 'Ms. Fatima',
      rating: 4.8,
      price: 'Rs 1,000',
      imagePath: AppAssets.course3,
      progress: 0.80,
      category: 'General',
      enrolledCount: 680,
      description: 'Step-by-step masterclass on sentence structuring, idioms, phrasal verbs, active/passive, and precis writing rules for CSS and PSC.',
    ),
    CourseModel(
      id: 'c5',
      title: 'Pakistan Affairs Masters & Past Papers 2024',
      author: 'Sir Tariq',
      rating: 4.7,
      price: 'Rs 1,500',
      imagePath: AppAssets.course5,
      category: 'Pakistan Affairs',
      enrolledCount: 410,
      description: 'Post-1947 constitutional dilemmas, foreign policy dynamics, and socioeconomic challenges with model answers.',
    ),
  ];

  @override
  Future<List<CourseModel>> getFeaturedCourses() async {
    return _allCourses.where((c) => c.isFeatured).toList();
  }

  @override
  Future<List<CourseModel>> getContinueLearningCourses(String studentId) async {
    return _allCourses.where((c) => (c.progress ?? 0) > 0).toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return [
      CategoryModel(id: 'c1', name: 'AJK PSC', courseCount: 12, iconType: 'document'),
      CategoryModel(id: 'c2', name: 'FPSC', courseCount: 18, iconType: 'globe'),
      CategoryModel(id: 'c3', name: 'NTS', courseCount: 15, iconType: 'clipboard'),
      CategoryModel(id: 'c4', name: 'CSS / PMS', courseCount: 22, iconType: 'book'),
    ];
  }

  @override
  Future<List<CourseModel>> getNewCourses() async {
    return _allCourses.skip(2).toList();
  }

  @override
  Future<List<CourseModel>> getEnrolledCourses(String studentId) async {
    return _allCourses.where((c) => (c.progress ?? 0) > 0).toList();
  }

  @override
  Future<List<CourseModel>> getTeacherCourses(String teacherId) async {
    return _allCourses.where((c) => c.author.contains('Tariq') || c.author.contains('Dr. Usman')).toList();
  }

  @override
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      return _allCourses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return _allCourses.first;
    }
  }

  @override
  Future<bool> enrollInCourse(String courseId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _allCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _allCourses[index] = _allCourses[index].copyWith(progress: 0.05);
    }
    return true;
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newCourse = course.copyWith(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      enrolledCount: 0,
      rating: 5.0,
      imagePath: course.imagePath.isEmpty ? AppAssets.course1 : course.imagePath,
    );
    _allCourses.insert(0, newCourse);
    return newCourse;
  }

  @override
  Future<bool> updateLessonProgress({
    required String courseId,
    required String lessonId,
    required bool isCompleted,
  }) async {
    return true;
  }
}

class MockQuizRepository implements QuizRepository {
  final List<QuizModel> _quizzes = [
    QuizModel(
      id: 'q1',
      title: 'Current Affairs Weekly Challenge 2024',
      category: 'Current Affairs',
      isAiGenerated: true,
      totalQuestions: 4,
      durationMinutes: 10,
      score: null,
      questions: [
        QuizQuestionModel(
          id: 'q1_1',
          questionText: 'Which country recently joined the SCO (Shanghai Cooperation Organisation) as a full member in 2024?',
          options: ['Belarus', 'Armenia', 'Azerbaijan', 'Mongolia'],
          correctOptionIndex: 0,
          explanation: 'Belarus officially became the 10th full member state of the Shanghai Cooperation Organisation during the Astana Summit in July 2024.',
        ),
        QuizQuestionModel(
          id: 'q1_2',
          questionText: 'What is the primary objective of Pakistan Special Investment Facilitation Council (SIFC)?',
          options: ['Tax collection enforcement', 'Single-window foreign direct investment in key sectors', 'Border security regulation', 'Higher education scholarship distribution'],
          correctOptionIndex: 1,
          explanation: 'SIFC was established as a civil-military hybrid decision-making body to fast-track investments in Agriculture, IT, Mines & Minerals, and Energy.',
        ),
        QuizQuestionModel(
          id: 'q1_3',
          questionText: 'The Karakoram Highway (N-35) connects Pakistan with which region of China?',
          options: ['Tibet Autonomous Region', 'Xinjiang Uyghur Autonomous Region', 'Sichuan Province', 'Yunnan Province'],
          correctOptionIndex: 1,
          explanation: 'The Karakoram Highway crosses the Khunjerab Pass at 4,693 meters into the Xinjiang Uyghur Autonomous Region of China.',
        ),
        QuizQuestionModel(
          id: 'q1_4',
          questionText: 'Under the 1973 Constitution of Pakistan, which amendment restored parliamentary supremacy from a semi-presidential system?',
          options: ['17th Amendment', '18th Amendment', '19th Amendment', '21st Amendment'],
          correctOptionIndex: 1,
          explanation: 'The 18th Constitutional Amendment passed in April 2010 removed the presidential power to dissolve the National Assembly under Article 58(2)(b) and devolved powers to provinces.',
        ),
      ],
    ),
    QuizModel(
      id: 'q2',
      title: 'English Grammar & Vocabulary Assessment',
      category: 'English',
      isAiGenerated: false,
      totalQuestions: 3,
      durationMinutes: 10,
      score: '2/3',
      questions: [
        QuizQuestionModel(
          id: 'q2_1',
          questionText: 'Choose the correct synonym for the word "EPHEMERAL":',
          options: ['Eternal', 'Transitory', 'Resolute', 'Pungent'],
          correctOptionIndex: 1,
          explanation: '"Ephemeral" means lasting for a very short time. "Transitory" is the closest synonym.',
        ),
        QuizQuestionModel(
          id: 'q2_2',
          questionText: 'Identify the sentence with correct subject-verb agreement:',
          options: [
            'Either the teacher or the students has arrived.',
            'Neither the director nor his assistants were present.',
            'The jury were unanimous in its verdict.',
            'Ten miles are a long distance to walk.'
          ],
          correctOptionIndex: 1,
          explanation: 'When subjects are connected by "neither... nor", the verb agrees with the closer subject ("assistants" -> "were").',
        ),
        QuizQuestionModel(
          id: 'q2_3',
          questionText: 'What is the passive form of: "The committee will announce the exam results tomorrow."?',
          options: [
            'The exam results will be announced by the committee tomorrow.',
            'The exam results shall announce tomorrow by the committee.',
            'The exam results are being announced tomorrow.',
            'The committee was announcing the exam results tomorrow.'
          ],
          correctOptionIndex: 0,
          explanation: 'Future simple active ("will announce") transforms to "will be + past participle" ("will be announced").',
        ),
      ],
    ),
  ];

  @override
  Future<List<QuizModel>> getAiQuizzes() async {
    return _quizzes.where((q) => q.isAiGenerated).toList();
  }

  @override
  Future<List<QuizModel>> getCourseQuizzes() async {
    return _quizzes.where((q) => !q.isAiGenerated).toList();
  }

  @override
  Future<List<QuizModel>> getTeacherQuizzes(String teacherId) async {
    return _quizzes;
  }

  @override
  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      return _quizzes.firstWhere((q) => q.id == quizId);
    } catch (_) {
      return _quizzes.first;
    }
  }

  @override
  Future<QuizModel> generateAiQuiz({
    required String topic,
    required String difficulty,
    required int questionCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final newQuiz = QuizModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI Practice Test: $topic',
      category: topic,
      isAiGenerated: true,
      totalQuestions: 4,
      durationMinutes: 10,
      questions: _quizzes.first.questions,
    );
    _quizzes.insert(0, newQuiz);
    return newQuiz;
  }

  @override
  Future<QuizSubmissionResultModel> submitQuiz({
    required String quizId,
    required Map<int, int> userAnswers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final quiz = await getQuizById(quizId) ?? _quizzes.first;
    int calculatedScore = 0;

    for (int i = 0; i < quiz.questions.length; i++) {
      final selected = userAnswers[i];
      if (selected != null && selected == quiz.questions[i].correctOptionIndex) {
        calculatedScore++;
      }
    }

    return QuizSubmissionResultModel(
      quizId: quiz.id,
      quizTitle: quiz.title,
      score: calculatedScore,
      totalQuestions: quiz.questions.isNotEmpty ? quiz.questions.length : quiz.totalQuestions,
      userAnswers: userAnswers,
      questions: quiz.questions,
    );
  }

  @override
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newQuiz = quiz.copyWith(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
    );
    _quizzes.insert(0, newQuiz);
    return newQuiz;
  }
}

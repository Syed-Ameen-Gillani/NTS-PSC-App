class LearningPreferences {
  const LearningPreferences({
    this.categories = const [],
    this.interests = const [],
    this.skills = const [],
    this.completed = false,
  });

  final List<String> categories;
  final List<String> interests;
  final List<String> skills;
  final bool completed;

  static const defaultSkills = [
    'Communication',
    'Critical Thinking',
    'Problem Solving',
    'Time Management',
    'Writing',
    'Computer Literacy',
  ];

  factory LearningPreferences.fromJson(Map<String, dynamic> row) {
    final categories = List<String>.from(row['categories'] as List);
    final interests = List<String>.from(row['interests'] as List);
    // Older offline preference snapshots may still use Pedagogy as a category.
    if (categories.remove('Pedagogy')) {
      categories.add('Education');
      interests.removeWhere(legacyPedagogyInterests.contains);
      interests.add('Pedagogy');
    }
    return LearningPreferences(
      categories: clean(categories),
      interests: clean(interests),
      skills: List<String>.from(row['skills'] as List),
      completed: row['completed_at'] != null,
    );
  }

  static const legacyPedagogyInterests = [
    'Learning Theories',
    'Teaching Methods',
    'Educational Psychology',
    'Classroom Management',
    'Assessment & Evaluation',
  ];

  static const interestOptions = {
    'Education': [
      'Pedagogy',
      'Teaching',
      'English',
      'Mathematics',
      'Science',
      'Kashmir Studies',
      'History',
      'Computer Science',
    ],
    'Competitions': [
      'General Knowledge',
      'Current Affairs',
      'Debating',
      'Writing',
      'Problem Solving',
    ],
    'Competitive Exams': [
      'CSS',
      'PMS',
      'FPSC',
      'NTS',
      'AJK PSC',
      'PPSC',
      'SPSC',
      'KPPSC',
      'BPSC',
    ],
  };

  static List<String> suggestedSkills(Iterable<String> interests) {
    const options = {
      'Pedagogy': [
        'Lesson Planning',
        'Classroom Management',
        'Assessment Design',
      ],
      'Teaching': ['Lesson Planning', 'Classroom Management'],
      'English': ['Grammar', 'Reading Comprehension', 'Writing'],
      'Mathematics': ['Numerical Reasoning', 'Problem Solving'],
      'Science': ['Scientific Reasoning', 'General Science'],
      'Kashmir Studies': ['Kashmir History', 'Geography'],
      'History': ['Historical Analysis', 'Research'],
      'Computer Science': ['Computer Literacy', 'Programming'],
      'General Knowledge': ['General Knowledge', 'Critical Thinking'],
      'Current Affairs': ['Current Affairs', 'Analysis'],
      'Debating': ['Public Speaking', 'Critical Thinking'],
      'Writing': ['Essay Writing', 'Grammar'],
      'Problem Solving': ['Logical Reasoning', 'Numerical Reasoning'],
    };
    return {
      for (final interest in interests)
        ...(options[interest] ??
            const [
              'Verbal Reasoning',
              'Quantitative Aptitude',
              'General Knowledge',
            ]),
    }.toList();
  }

  static List<String> clean(Iterable<String> values) {
    final seen = <String>{};
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && seen.add(value.toLowerCase()))
        .toList();
  }

  void validate() {
    if (categories.isEmpty ||
        categories.any((value) => !interestOptions.containsKey(value))) {
      throw const FormatException('Choose at least one category.');
    }
    final allowed = {
      for (final category in categories) ...interestOptions[category]!,
    };
    if (interests.isEmpty ||
        interests.any((value) => !allowed.contains(value))) {
      throw const FormatException(
        'Choose at least one interest from your categories.',
      );
    }
    if (skills.length > 30 ||
        skills.any((value) => value.trim().isEmpty || value.length > 60)) {
      throw const FormatException(
        'Add up to 30 skills, with at most 60 characters each.',
      );
    }
  }
}

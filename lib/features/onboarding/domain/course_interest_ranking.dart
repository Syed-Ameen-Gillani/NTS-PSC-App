import 'package:nts_psc_app/core/models/app_models.dart';
import 'learning_preferences.dart';

/// Uses the saved survey for both dashboard ordering and catalog RPC weights.
class CourseInterestRanking {
  CourseInterestRanking(this.preferences);
  final LearningPreferences preferences;

  static const _aliases = {
    'Pedagogy': ['Teaching', 'Education'],
    'English': ['Grammar', 'Reading Comprehension', 'Essay Writing'],
    'Mathematics': ['Math', 'Numerical Reasoning', 'Quantitative Aptitude'],
    'Science': ['General Science', 'Everyday Science'],
    'Computer Science': ['Computing', 'Programming', 'Computer Literacy'],
    'Debating': ['Debate', 'Public Speaking'],
    'Problem Solving': ['Logical Reasoning', 'Analytical Reasoning'],
  };

  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static List<String> topicTerms(String topic) {
    final interests = LearningPreferences.interestOptions.values
        .expand((items) => items)
        .toSet();
    return {
      topic,
      ...?LearningPreferences.interestOptions[topic],
      for (final interest
          in LearningPreferences.interestOptions[topic] ??
              const <String>[]) ...[
        ...?_aliases[interest],
        ...LearningPreferences.suggestedSkills([interest]),
      ],
      ...?_aliases[topic],
      if (interests.contains(topic) &&
          !LearningPreferences.interestOptions['Competitive Exams']!.contains(
            topic,
          ))
        ...LearningPreferences.suggestedSkills([topic]),
      for (final interest in interests)
        if (LearningPreferences.suggestedSkills([
          interest,
        ]).contains(topic)) ...[
          interest,
          ...?_aliases[interest],
        ],
    }.map(normalize).where((term) => term.isNotEmpty).toList();
  }

  late final Map<String, int> weights = _weights();

  Map<String, int> _weights() {
    final result = <String, int>{};
    void add(String value, int weight) {
      for (final term in topicTerms(value)) {
        if ((result[term] ?? 0) < weight) result[term] = weight;
      }
    }

    for (final category in preferences.categories) {
      add(category, 1);
    }
    for (final interest in preferences.interests) {
      add(interest, 4);
    }
    for (final skill in preferences.skills) {
      add(skill, 2);
    }
    return result;
  }

  int score(String text) {
    final haystack = ' ${normalize(text)} ';
    return weights.entries
        .where((entry) => haystack.contains(' ${entry.key} '))
        .fold(0, (total, entry) => total + entry.value);
  }

  List<Map<String, Object>> get terms => [
    for (final entry in weights.entries)
      {'term': entry.key, 'weight': entry.value},
  ];

  List<String> topics(List<CategoryModel> categories) {
    int directPriority(String topic) {
      if (preferences.interests.contains(topic)) return 2;
      if (preferences.skills.contains(topic)) return 1;
      return 0;
    }

    final options = {
      for (final category in categories) category.name,
      ...LearningPreferences.interestOptions.keys,
      ...LearningPreferences.interestOptions.values.expand((items) => items),
      ...LearningPreferences.defaultSkills,
      ...LearningPreferences.suggestedSkills(
        LearningPreferences.interestOptions.values.expand((items) => items),
      ),
      ...preferences.skills,
    }.toList();
    final indexed = options.asMap().entries.toList()
      ..sort((a, b) {
        final relevance = score(b.value).compareTo(score(a.value));
        if (relevance != 0) return relevance;
        final direct = directPriority(
          b.value,
        ).compareTo(directPriority(a.value));
        return direct == 0 ? a.key.compareTo(b.key) : direct;
      });
    return ['All', ...indexed.map((entry) => entry.value)];
  }

  String initialTopic(List<CategoryModel> categories) {
    final options = topics(categories).skip(1);
    final selectedInterests = options.where(preferences.interests.contains);
    if (selectedInterests.isNotEmpty) return selectedInterests.first;
    return options.isNotEmpty && score(options.first) > 0
        ? options.first
        : 'All';
  }

  bool matches(CourseModel course, String topic) {
    if (topic == 'All') return true;
    final text =
        ' ${normalize('${course.category} ${course.title} ${course.description}')} ';
    return topicTerms(topic).any((term) => text.contains(' $term '));
  }
}

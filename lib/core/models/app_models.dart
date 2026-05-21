class CourseModel {
  final String id;
  final String title;
  final String author;
  final double rating;
  final String price;
  final String imagePath;
  final bool isFeatured;
  final double? progress;

  CourseModel({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    required this.price,
    required this.imagePath,
    this.isFeatured = false,
    this.progress,
  });
}

class CategoryModel {
  final String id;
  final String name;
  final int courseCount;
  final String iconType;

  CategoryModel({
    required this.id,
    required this.name,
    required this.courseCount,
    required this.iconType,
  });
}

class TeacherModel {
  final String id;
  final String name;
  final String subject;
  final String imagePath;

  TeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.imagePath,
  });
}

class QuizModel {
  final String id;
  final String title;
  final String category;
  final bool isAiGenerated;
  final int totalQuestions;
  final String? score; // e.g. '16/20' or null if not attempted
  
  QuizModel({
    required this.id,
    required this.title,
    required this.category,
    this.isAiGenerated = false,
    required this.totalQuestions,
    this.score,
  });
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String imagePath;
  final bool isPremium;
  final int courses;
  final int quizzes;
  final int avgScore;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.imagePath,
    required this.isPremium,
    required this.courses,
    required this.quizzes,
    required this.avgScore,
  });
}

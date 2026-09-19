import 'user_role.dart';

class LessonModel {
  final String id;
  final String title;
  final int durationMinutes;
  final String videoUrl;
  final String notes;
  final bool isCompleted;
  final bool isLocked;

  LessonModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    this.videoUrl = '',
    this.notes = '',
    this.isCompleted = false,
    this.isLocked = false,
  });

  LessonModel copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    String? videoUrl,
    String? notes,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      videoUrl: videoUrl ?? this.videoUrl,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class CourseModuleModel {
  final String id;
  final String title;
  final List<LessonModel> lessons;

  CourseModuleModel({
    required this.id,
    required this.title,
    this.lessons = const [],
  });
}

class CourseModel {
  final String id;
  final String title;
  final String author;
  final double rating;
  final String price;
  final String imagePath;
  final bool isFeatured;
  final double? progress;
  final String description;
  final String instructorId;
  final String category;
  final int enrolledCount;
  final bool isPublished;
  final List<CourseModuleModel> modules;

  CourseModel({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    required this.price,
    required this.imagePath,
    this.isFeatured = false,
    this.progress,
    this.description = '',
    this.instructorId = '',
    this.category = 'General',
    this.enrolledCount = 120,
    this.isPublished = true,
    this.modules = const [],
  });

  CourseModel copyWith({
    String? id,
    String? title,
    String? author,
    double? rating,
    String? price,
    String? imagePath,
    bool? isFeatured,
    double? progress,
    String? description,
    String? instructorId,
    String? category,
    int? enrolledCount,
    bool? isPublished,
    List<CourseModuleModel>? modules,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      isFeatured: isFeatured ?? this.isFeatured,
      progress: progress ?? this.progress,
      description: description ?? this.description,
      instructorId: instructorId ?? this.instructorId,
      category: category ?? this.category,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isPublished: isPublished ?? this.isPublished,
      modules: modules ?? this.modules,
    );
  }
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
  final String qualification;
  final double rating;
  final int studentCount;

  TeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.imagePath,
    this.qualification = 'Master in Subject',
    this.rating = 4.8,
    this.studentCount = 2400,
  });
}

class QuizQuestionModel {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class QuizModel {
  final String id;
  final String title;
  final String category;
  final bool isAiGenerated;
  final int totalQuestions;
  final String? score; // e.g. '16/20' or null if not attempted
  final int durationMinutes;
  final int passingScore;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    required this.category,
    this.isAiGenerated = false,
    required this.totalQuestions,
    this.score,
    this.durationMinutes = 15,
    this.passingScore = 60,
    this.questions = const [],
  });

  QuizModel copyWith({
    String? id,
    String? title,
    String? category,
    bool? isAiGenerated,
    int? totalQuestions,
    String? score,
    int? durationMinutes,
    int? passingScore,
    List<QuizQuestionModel>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      score: score ?? this.score,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      passingScore: passingScore ?? this.passingScore,
      questions: questions ?? this.questions,
    );
  }
}

class QuizSubmissionResultModel {
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final Map<int, int> userAnswers; // questionIndex -> selectedOptionIndex
  final List<QuizQuestionModel> questions;

  QuizSubmissionResultModel({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    required this.questions,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;
  bool get isPassed => percentage >= 60.0;
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
  final UserRole role;
  final String? subject;
  final String? qualification;
  final String? bio;
  final double totalEarnings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.imagePath,
    required this.isPremium,
    required this.courses,
    required this.quizzes,
    required this.avgScore,
    this.role = UserRole.student,
    this.subject,
    this.qualification,
    this.bio,
    this.totalEarnings = 0.0,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? imagePath,
    bool? isPremium,
    int? courses,
    int? quizzes,
    int? avgScore,
    UserRole? role,
    String? subject,
    String? qualification,
    String? bio,
    double? totalEarnings,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      isPremium: isPremium ?? this.isPremium,
      courses: courses ?? this.courses,
      quizzes: quizzes ?? this.quizzes,
      avgScore: avgScore ?? this.avgScore,
      role: role ?? this.role,
      subject: subject ?? this.subject,
      qualification: qualification ?? this.qualification,
      bio: bio ?? this.bio,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }
}

class TeacherStatsModel {
  final int totalStudents;
  final int activeCourses;
  final int totalQuizzes;
  final double avgRating;
  final String totalEarnings;

  TeacherStatsModel({
    required this.totalStudents,
    required this.activeCourses,
    required this.totalQuizzes,
    required this.avgRating,
    required this.totalEarnings,
  });
}

class StudentDoubtModel {
  final String id;
  final String studentName;
  final String studentAvatar;
  final String courseTitle;
  final String lessonTitle;
  final String question;
  final String? answer;
  final bool isResolved;
  final String createdAt;

  StudentDoubtModel({
    required this.id,
    required this.studentName,
    required this.studentAvatar,
    required this.courseTitle,
    required this.lessonTitle,
    required this.question,
    this.answer,
    this.isResolved = false,
    required this.createdAt,
  });

  StudentDoubtModel copyWith({
    String? id,
    String? studentName,
    String? studentAvatar,
    String? courseTitle,
    String? lessonTitle,
    String? question,
    String? answer,
    bool? isResolved,
    String? createdAt,
  }) {
    return StudentDoubtModel(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      courseTitle: courseTitle ?? this.courseTitle,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveSessionModel {
  final String id;
  final String title;
  final String courseTitle;
  final String scheduledDate;
  final String scheduledTime;
  final int durationMinutes;
  final String meetingUrl;
  final String description;
  final bool isLive;
  final bool isCompleted;

  LiveSessionModel({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.meetingUrl,
    required this.description,
    this.isLive = false,
    this.isCompleted = false,
  });
}

class StudentQuizResultModel {
  final String quizTitle;
  final int score;
  final int totalMarks;
  final bool passed;
  final String date;

  StudentQuizResultModel({
    required this.quizTitle,
    required this.score,
    this.totalMarks = 100,
    required this.passed,
    required this.date,
  });
}

class StudentRosterModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String courseTitle;
  final String enrolledAt;
  final double progress;
  final int averageQuizScore;
  final String status; // 'On Track', 'Needs Attention', 'Completed'
  final String lastActive;
  final int completedLessons;
  final int totalLessons;
  final List<StudentQuizResultModel> quizBreakdown;
  final DateTime? lastNudgedAt;

  StudentRosterModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.courseTitle,
    required this.enrolledAt,
    required this.progress,
    required this.averageQuizScore,
    this.status = 'On Track',
    this.lastActive = '1 day ago',
    this.completedLessons = 12,
    this.totalLessons = 20,
    this.quizBreakdown = const [],
    this.lastNudgedAt,
  });

  StudentRosterModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? courseTitle,
    String? enrolledAt,
    double? progress,
    int? averageQuizScore,
    String? status,
    String? lastActive,
    int? completedLessons,
    int? totalLessons,
    List<StudentQuizResultModel>? quizBreakdown,
    DateTime? lastNudgedAt,
  }) {
    return StudentRosterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      courseTitle: courseTitle ?? this.courseTitle,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      progress: progress ?? this.progress,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons ?? this.totalLessons,
      quizBreakdown: quizBreakdown ?? this.quizBreakdown,
      lastNudgedAt: lastNudgedAt ?? this.lastNudgedAt,
    );
  }
}

class PayoutRecordModel {
  final String id;
  final String transactionId;
  final String amount;
  final String method;
  final String accountNumber;
  final String date;
  final String status; // 'Completed', 'Processing', 'Failed'

  PayoutRecordModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.accountNumber,
    required this.date,
    required this.status,
  });
}

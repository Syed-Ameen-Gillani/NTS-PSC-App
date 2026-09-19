class CourseReviewModel {
  final String id;
  final String courseId;
  final String studentName;
  final String studentAvatar;
  final double rating;
  final String date;
  final String comment;
  final int helpfulCount;
  final bool userLiked;
  final bool isVerified;
  final String? instructorReply;
  final String? instructorReplyDate;

  const CourseReviewModel({
    required this.id,
    required this.courseId,
    required this.studentName,
    required this.studentAvatar,
    required this.rating,
    required this.date,
    required this.comment,
    this.helpfulCount = 0,
    this.userLiked = false,
    this.isVerified = true,
    this.instructorReply,
    this.instructorReplyDate,
  });

  CourseReviewModel copyWith({
    String? id,
    String? courseId,
    String? studentName,
    String? studentAvatar,
    double? rating,
    String? date,
    String? comment,
    int? helpfulCount,
    bool? userLiked,
    bool? isVerified,
    String? instructorReply,
    String? instructorReplyDate,
  }) {
    return CourseReviewModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      userLiked: userLiked ?? this.userLiked,
      isVerified: isVerified ?? this.isVerified,
      instructorReply: instructorReply ?? this.instructorReply,
      instructorReplyDate: instructorReplyDate ?? this.instructorReplyDate,
    );
  }
}

class RatingDistributionModel {
  final double averageRating;
  final int totalReviews;
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStars;

  const RatingDistributionModel({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStars,
    required this.fourStars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStars,
  });

  double get fiveStarRatio => totalReviews > 0 ? fiveStars / totalReviews : 0.0;
  double get fourStarRatio => totalReviews > 0 ? fourStars / totalReviews : 0.0;
  double get threeStarRatio => totalReviews > 0 ? threeStars / totalReviews : 0.0;
  double get twoStarRatio => totalReviews > 0 ? twoStars / totalReviews : 0.0;
  double get oneStarRatio => totalReviews > 0 ? oneStars / totalReviews : 0.0;
}

class CourseResourceModel {
  final String id;
  final String courseId;
  final String moduleTitle;
  final String title;
  final String fileType; // 'PDF', 'SLIDES', 'DOC'
  final String fileSize;
  final String downloadUrl;
  final bool isDownloaded;

  const CourseResourceModel({
    required this.id,
    required this.courseId,
    required this.moduleTitle,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.downloadUrl,
    this.isDownloaded = false,
  });

  CourseResourceModel copyWith({
    String? id,
    String? courseId,
    String? moduleTitle,
    String? title,
    String? fileType,
    String? fileSize,
    String? downloadUrl,
    bool? isDownloaded,
  }) {
    return CourseResourceModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      title: title ?? this.title,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class CourseAnnouncementModel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String instructorName;
  final String title;
  final String message;
  final String timestamp;
  final bool isUrgent;

  const CourseAnnouncementModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.instructorName,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isUrgent = false,
  });
}

class QuizItemAnalysisModel {
  final String questionId;
  final int questionNumber;
  final String questionText;
  final double correctPercentage; // e.g. 0.42 = 42%
  final int totalAttempts;
  final String commonDistractor;
  final String teacherRecommendation;

  const QuizItemAnalysisModel({
    required this.questionId,
    required this.questionNumber,
    required this.questionText,
    required this.correctPercentage,
    required this.totalAttempts,
    required this.commonDistractor,
    required this.teacherRecommendation,
  });

  bool get isTricky => correctPercentage < 0.55;
}

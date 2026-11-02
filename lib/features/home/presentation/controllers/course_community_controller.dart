import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/course_community_models.dart';
import 'package:nts_psc_app/core/networks/mock_community_data.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

class CourseCommunityState {
  final List<CourseReviewModel> reviews;
  final List<CourseResourceModel> resources;
  final List<CourseAnnouncementModel> announcements;
  final List<QuizItemAnalysisModel> itemAnalysis;
  final bool isSubmittingReview;
  final bool isBroadcasting;

  const CourseCommunityState({
    this.reviews = const [],
    this.resources = const [],
    this.announcements = const [],
    this.itemAnalysis = const [],
    this.isSubmittingReview = false,
    this.isBroadcasting = false,
  });

  RatingDistributionModel get ratingDistribution =>
      RatingDistributionModel.fromReviews(reviews);

  CourseCommunityState copyWith({
    List<CourseReviewModel>? reviews,
    List<CourseResourceModel>? resources,
    List<CourseAnnouncementModel>? announcements,
    List<QuizItemAnalysisModel>? itemAnalysis,
    bool? isSubmittingReview,
    bool? isBroadcasting,
  }) {
    return CourseCommunityState(
      reviews: reviews ?? this.reviews,
      resources: resources ?? this.resources,
      announcements: announcements ?? this.announcements,
      itemAnalysis: itemAnalysis ?? this.itemAnalysis,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
    );
  }
}

class CourseCommunityController extends Notifier<CourseCommunityState> {
  void _requireMockMode() {
    if (AppConfig.isSupabaseEnabled) {
      throw StateError('Community actions are not available yet.');
    }
  }

  @override
  CourseCommunityState build() {
    if (AppConfig.isSupabaseEnabled) return const CourseCommunityState();
    return CourseCommunityState(
      reviews: MockCommunityData.getInitialReviews(),
      resources: MockCommunityData.getInitialResources(),
      announcements: MockCommunityData.getInitialAnnouncements(),
      itemAnalysis: MockCommunityData.getQuizItemAnalysis(),
    );
  }

  void submitReview({
    required String courseId,
    required String studentName,
    required double rating,
    required String comment,
  }) {
    _requireMockMode();
    final newReview = CourseReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      studentName: studentName.trim().isEmpty
          ? 'Enrolled Candidate'
          : studentName,
      studentAvatar: 'assets/images/user1.png',
      rating: rating,
      date: 'Just now',
      comment: comment,
      helpfulCount: 0,
      userLiked: false,
      isVerified: true,
    );

    state = state.copyWith(reviews: [newReview, ...state.reviews]);
  }

  void toggleHelpful(String reviewId) {
    _requireMockMode();
    state = state.copyWith(
      reviews: state.reviews.map((rev) {
        if (rev.id == reviewId) {
          final isLiked = !rev.userLiked;
          return rev.copyWith(
            userLiked: isLiked,
            helpfulCount: isLiked ? rev.helpfulCount + 1 : rev.helpfulCount - 1,
          );
        }
        return rev;
      }).toList(),
    );
  }

  void replyAsInstructor({
    required String reviewId,
    required String replyText,
  }) {
    _requireMockMode();
    state = state.copyWith(
      reviews: state.reviews.map((rev) {
        if (rev.id == reviewId) {
          return rev.copyWith(
            instructorReply: replyText,
            instructorReplyDate: 'Just now',
          );
        }
        return rev;
      }).toList(),
    );
  }

  void toggleResourceDownload(String resourceId) {
    _requireMockMode();
    state = state.copyWith(
      resources: state.resources.map((res) {
        if (res.id == resourceId) {
          return res.copyWith(isDownloaded: !res.isDownloaded);
        }
        return res;
      }).toList(),
    );
  }

  void addResource({
    required String courseId,
    required String moduleTitle,
    required String title,
    required String fileType,
    required String fileSize,
  }) {
    _requireMockMode();
    final newRes = CourseResourceModel(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      moduleTitle: moduleTitle,
      title: title,
      fileType: fileType,
      fileSize: fileSize,
      downloadUrl: 'https://example.com/$title',
      isDownloaded: false,
    );

    state = state.copyWith(resources: [newRes, ...state.resources]);
  }

  void broadcastAnnouncement({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String title,
    required String message,
    required bool isUrgent,
  }) {
    _requireMockMode();
    final newAnn = CourseAnnouncementModel(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      courseTitle: courseTitle,
      instructorName: instructorName,
      title: title,
      message: message,
      timestamp: 'Just now',
      isUrgent: isUrgent,
    );

    state = state.copyWith(announcements: [newAnn, ...state.announcements]);
  }
}

final courseCommunityProvider =
    NotifierProvider<CourseCommunityController, CourseCommunityState>(
      CourseCommunityController.new,
    );

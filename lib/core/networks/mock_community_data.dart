import 'package:nts_psc_app/core/models/course_community_models.dart';

class MockCommunityData {
  static List<CourseReviewModel> getInitialReviews() {
    return [
      const CourseReviewModel(
        id: 'rev_1',
        courseId: 'c1',
        studentName: 'Hamza Farooq',
        studentAvatar: 'assets/images/user1.png',
        rating: 5.0,
        date: '3 days ago',
        comment:
            'Sir Tariq covers the Customs Act 1969 with surgical clarity. The past paper drills helped me score 84/100 on my recent mock. Highly recommended for FPSC aspirants!',
        helpfulCount: 28,
        userLiked: true,
        isVerified: true,
        instructorReply:
            'Thank you Hamza! Consistency in revising Chapter 4 & Chapter 10 is crucial for the final exam. Keep up the high scores!',
        instructorReplyDate: '2 days ago',
      ),
      const CourseReviewModel(
        id: 'rev_2',
        courseId: 'c1',
        studentName: 'Zainab Bibi',
        studentAvatar: 'assets/images/user2.png',
        rating: 5.0,
        date: '1 week ago',
        comment:
            'The syllabus breakdown and video quality are top tier. I was struggling with Everyday Science, but the conceptual explanations simplified everything.',
        helpfulCount: 15,
        userLiked: false,
        isVerified: true,
      ),
      const CourseReviewModel(
        id: 'rev_3',
        courseId: 'c1',
        studentName: 'Usman Ali',
        studentAvatar: 'assets/images/user3.png',
        rating: 4.0,
        date: '2 weeks ago',
        comment:
            'Great course overall! The quizzes are challenging and closely mimic actual FPSC patterns. Would love more PDF summaries for quick revision on the go.',
        helpfulCount: 9,
        userLiked: false,
        isVerified: true,
        instructorReply:
            'Noted Usman! I have just uploaded comprehensive PDF handouts in the Resources section for you all.',
        instructorReplyDate: '1 week ago',
      ),
      const CourseReviewModel(
        id: 'rev_4',
        courseId: 'c1',
        studentName: 'Ayesha Siddiqui',
        studentAvatar: 'assets/images/user1.png',
        rating: 5.0,
        date: '3 weeks ago',
        comment:
            'Cleared my initial screening test with 78 marks after following this course roadmap. Thank you Sir Tariq and NTS-PSC team!',
        helpfulCount: 42,
        userLiked: false,
        isVerified: true,
      ),
    ];
  }

  static RatingDistributionModel getRatingDistribution(List<CourseReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const RatingDistributionModel(
        averageRating: 4.9,
        totalReviews: 124,
        fiveStars: 105,
        fourStars: 14,
        threeStars: 3,
        twoStars: 1,
        oneStars: 1,
      );
    }

    int five = 0, four = 0, three = 0, two = 0, one = 0;
    double sum = 0;
    for (final r in reviews) {
      sum += r.rating;
      if (r.rating >= 4.5) {
        five++;
      } else if (r.rating >= 3.5) four++;
      else if (r.rating >= 2.5) three++;
      else if (r.rating >= 1.5) two++;
      else one++;
    }

    return RatingDistributionModel(
      averageRating: double.parse((sum / reviews.length).toStringAsFixed(1)),
      totalReviews: reviews.length,
      fiveStars: five,
      fourStars: four,
      threeStars: three,
      twoStars: two,
      oneStars: one,
    );
  }

  static List<CourseResourceModel> getInitialResources() {
    return [
      const CourseResourceModel(
        id: 'res_1',
        courseId: 'c1',
        moduleTitle: 'Module 1: Customs Act 1969',
        title: 'Customs Act 1969 Official Gazette (Amended up to 2026)',
        fileType: 'PDF',
        fileSize: '4.2 MB',
        downloadUrl: 'https://example.com/customs_act_2026.pdf',
        isDownloaded: true,
      ),
      const CourseResourceModel(
        id: 'res_2',
        courseId: 'c1',
        moduleTitle: 'Module 1: Customs Act 1969',
        title: 'High-Frequency Sections Cheat Sheet (Sec 1 to Sec 223)',
        fileType: 'PDF',
        fileSize: '1.8 MB',
        downloadUrl: 'https://example.com/customs_cheat_sheet.pdf',
      ),
      const CourseResourceModel(
        id: 'res_3',
        courseId: 'c1',
        moduleTitle: 'Module 2: General Knowledge & Pakistan Affairs',
        title: 'FPSC Solved Past Papers (2018–2025 Compilation)',
        fileType: 'PDF',
        fileSize: '8.5 MB',
        downloadUrl: 'https://example.com/fpsc_past_papers_solved.pdf',
      ),
      const CourseResourceModel(
        id: 'res_4',
        courseId: 'c1',
        moduleTitle: 'Module 3: Everyday Science',
        title: 'Everyday Science Rapid Revision Presentation Slides',
        fileType: 'SLIDES',
        fileSize: '5.1 MB',
        downloadUrl: 'https://example.com/everyday_science_slides.pdf',
      ),
    ];
  }

  static List<CourseAnnouncementModel> getInitialAnnouncements() {
    return [
      const CourseAnnouncementModel(
        id: 'ann_1',
        courseId: 'c1',
        courseTitle: 'FPSC Inspector Customs & Intelligence Officer',
        instructorName: 'Sir Tariq',
        title: '📢 Live Marathon Revision Session Scheduled for Sunday!',
        message:
            'Dear aspirants, we will host a 2-hour live session this Sunday at 7:00 PM to dissect the latest FPSC paper pattern and solve 100 high-probability MCQs together. Bring your questions!',
        timestamp: 'Yesterday at 4:30 PM',
        isUrgent: true,
      ),
      const CourseAnnouncementModel(
        id: 'ann_2',
        courseId: 'c1',
        courseTitle: 'FPSC Inspector Customs & Intelligence Officer',
        instructorName: 'Sir Tariq',
        title: '📄 New Handouts Added to Module 2',
        message:
            'I have uploaded the 2021–2025 Solved Past Papers compilation to the Resources tab. Make sure to download and review Section 3 before attempting Mock Quiz 2.',
        timestamp: '3 days ago',
        isUrgent: false,
      ),
    ];
  }

  static List<QuizItemAnalysisModel> getQuizItemAnalysis() {
    return [
      const QuizItemAnalysisModel(
        questionId: 'q_item_1',
        questionNumber: 1,
        questionText: 'Under Section 2 of Customs Act 1969, who is authorized as the adjudicating officer?',
        correctPercentage: 0.88,
        totalAttempts: 142,
        commonDistractor: 'Superintendent of Customs',
        teacherRecommendation: 'Cohort understands officer hierarchy well.',
      ),
      const QuizItemAnalysisModel(
        questionId: 'q_item_2',
        questionNumber: 2,
        questionText: 'What is the maximum penalty for smuggling under Chapter XVI of the Act?',
        correctPercentage: 0.42,
        totalAttempts: 142,
        commonDistractor: 'Fine up to twice the goods value',
        teacherRecommendation: '⚠️ 58% of students missed this. Review Section 156 penalty brackets in next lecture.',
      ),
      const QuizItemAnalysisModel(
        questionId: 'q_item_3',
        questionNumber: 3,
        questionText: 'Which constitutional article establishes the Federal Public Service Commission?',
        correctPercentage: 0.91,
        totalAttempts: 142,
        commonDistractor: 'Article 212',
        teacherRecommendation: 'Solid candidate retention on constitutional articles.',
      ),
      const QuizItemAnalysisModel(
        questionId: 'q_item_4',
        questionNumber: 4,
        questionText: 'In everyday science, which atmospheric layer contains the ozone shield?',
        correctPercentage: 0.51,
        totalAttempts: 142,
        commonDistractor: 'Troposphere',
        teacherRecommendation: '⚠️ Common confusion between Stratosphere and Troposphere. Re-emphasize atmospheric zones.',
      ),
    ];
  }
}

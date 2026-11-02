import 'package:nts_psc_app/core/models/app_models.dart';

class MockTeacherData {
  static List<StudentDoubtModel> get initialDoubts => [
    StudentDoubtModel(
      id: 'd1',
      studentName: 'Hamza Tariq',
      studentAvatar: 'assets/images/teacher1.png',
      courseTitle: 'FPSC Inspector Customs 2026 Batch',
      lessonTitle: 'Lesson 2: Import & Export Clearance',
      question:
          'Sir, what is the exact difference between Bill of Entry for Home Consumption and Bill of Entry for Warehousing under Section 79 of the Customs Act?',
      answer: null,
      isResolved: false,
      createdAt: '25 mins ago',
    ),
    StudentDoubtModel(
      id: 'd2',
      studentName: 'Ayesha Siddiqa',
      studentAvatar: 'assets/images/teacher1.png',
      courseTitle: 'AJK PSC General Recruitment Masterclass',
      lessonTitle: 'Lesson 1: Kashmir Studies & Treaty of Amritsar',
      question:
          'In the 1846 Treaty of Amritsar, how much amount was paid by Gulab Singh to the British government according to recent exam keys?',
      answer:
          'Gulab Singh paid 75 Lakh Nanakshahi Rupees (7.5 million) to the East India Company under Article 3 of the Treaty.',
      isResolved: true,
      createdAt: '2 hours ago',
    ),
    StudentDoubtModel(
      id: 'd3',
      studentName: 'Bilal Hassan',
      studentAvatar: 'assets/images/teacher1.png',
      courseTitle: 'Everyday Science & General Ability',
      lessonTitle: 'Lesson 3: Atmospheric Layers & Ozone',
      question:
          'Which atmospheric layer contains the maximum concentration of Ozone: Stratosphere or Mesosphere?',
      answer:
          'Ozone is concentrated primarily in the lower portion of the Stratosphere from approximately 15 to 35 kilometers above Earth.',
      isResolved: true,
      createdAt: '1 day ago',
    ),
  ];

  static List<LiveSessionModel> get initialLiveSessions => [
    LiveSessionModel(
      id: 'live_1',
      title: 'FPSC Customs Act 1969: High-Yield Past Papers Review',
      courseTitle: 'FPSC Inspector Customs 2026 Batch',
      scheduledDate: 'Today, 8:00 PM',
      scheduledTime: '8:00 PM - 9:30 PM',
      durationMinutes: 90,
      meetingUrl: 'https://meet.google.com/nts-fpsc-live',
      description:
          'Live interactive masterclass solving past 10 years FPSC screening questions with live doubt clearance.',
      isLive: true,
      isCompleted: false,
    ),
    LiveSessionModel(
      id: 'live_2',
      title: 'AJK PSC Lecturer Exam Strategy & Time Management',
      courseTitle: 'AJK PSC General Recruitment Masterclass',
      scheduledDate: 'Tomorrow, 6:00 PM',
      scheduledTime: '6:00 PM - 7:15 PM',
      durationMinutes: 75,
      meetingUrl: 'https://meet.google.com/ajk-psc-live',
      description:
          'Strategic roadmap on tackling 100 MCQs in 90 minutes without negative marking penalty.',
      isLive: false,
      isCompleted: false,
    ),
    LiveSessionModel(
      id: 'live_3',
      title: 'Everyday Science: Environmental Studies Core Concepts',
      courseTitle: 'Everyday Science & General Ability',
      scheduledDate: '18 Sep 2026',
      scheduledTime: '7:00 PM - 8:30 PM',
      durationMinutes: 90,
      meetingUrl: 'https://meet.google.com/science-archive',
      description:
          'Recording and annotated lecture slides available in the course repository.',
      isLive: false,
      isCompleted: true,
    ),
  ];

  static List<StudentRosterModel> get initialStudents => [
    StudentRosterModel(
      id: 'st_1',
      name: 'Hamza Tariq',
      email: 'hamza.tariq@gmail.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'FPSC Inspector Customs 2026 Batch',
      enrolledAt: '12 Sep 2026',
      progress: 0.85,
      averageQuizScore: 92,
      status: 'On Track',
      lastActive: '45 mins ago',
      completedLessons: 17,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Customs Act 1969 Basics',
          score: 94,
          passed: true,
          date: '14 Sep 2026',
        ),
        StudentQuizResultModel(
          quizTitle: 'Import & Tariff Valuation',
          score: 90,
          passed: true,
          date: '16 Sep 2026',
        ),
      ],
    ),
    StudentRosterModel(
      id: 'st_2',
      name: 'Ayesha Siddiqa',
      email: 'ayesha.s@outlook.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'AJK PSC General Recruitment Masterclass',
      enrolledAt: '08 Sep 2026',
      progress: 0.70,
      averageQuizScore: 88,
      status: 'On Track',
      lastActive: '2 hours ago',
      completedLessons: 14,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Kashmir Studies & Treaties',
          score: 90,
          passed: true,
          date: '12 Sep 2026',
        ),
        StudentQuizResultModel(
          quizTitle: 'General Knowledge & Current Affairs',
          score: 86,
          passed: true,
          date: '15 Sep 2026',
        ),
      ],
    ),
    StudentRosterModel(
      id: 'st_3',
      name: 'Bilal Hassan',
      email: 'bilal.hassan@yahoo.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'Everyday Science & General Ability',
      enrolledAt: '01 Sep 2026',
      progress: 1.0,
      averageQuizScore: 96,
      status: 'Completed',
      lastActive: 'Yesterday',
      completedLessons: 20,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Atmospheric Physics & Layers',
          score: 98,
          passed: true,
          date: '10 Sep 2026',
        ),
        StudentQuizResultModel(
          quizTitle: 'Biological Sciences & Human Body',
          score: 94,
          passed: true,
          date: '14 Sep 2026',
        ),
      ],
    ),
    StudentRosterModel(
      id: 'st_4',
      name: 'Zainab Fatima',
      email: 'zainab.f@gmail.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'FPSC Inspector Customs 2026 Batch',
      enrolledAt: '15 Sep 2026',
      progress: 0.25,
      averageQuizScore: 48,
      status: 'Needs Attention',
      lastActive: '5 days ago',
      completedLessons: 5,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Customs Act 1969 Basics',
          score: 48,
          passed: false,
          date: '16 Sep 2026',
        ),
      ],
    ),
    StudentRosterModel(
      id: 'st_5',
      name: 'Usman Ali Khan',
      email: 'usman.ak@gmail.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'CSS Screening & Current Affairs',
      enrolledAt: '05 Sep 2026',
      progress: 0.60,
      averageQuizScore: 84,
      status: 'On Track',
      lastActive: '1 day ago',
      completedLessons: 12,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Pakistan Foreign Policy 2025-26',
          score: 84,
          passed: true,
          date: '11 Sep 2026',
        ),
      ],
    ),
    StudentRosterModel(
      id: 'st_6',
      name: 'Maryam Noor',
      email: 'maryam.noor@gmail.com',
      avatar: 'assets/images/teacher1.png',
      courseTitle: 'FPSC Inspector Customs 2026 Batch',
      enrolledAt: '10 Sep 2026',
      progress: 0.30,
      averageQuizScore: 52,
      status: 'Needs Attention',
      lastActive: '4 days ago',
      completedLessons: 6,
      totalLessons: 20,
      quizBreakdown: [
        StudentQuizResultModel(
          quizTitle: 'Customs Act 1969 Basics',
          score: 52,
          passed: false,
          date: '13 Sep 2026',
        ),
      ],
    ),
  ];
}

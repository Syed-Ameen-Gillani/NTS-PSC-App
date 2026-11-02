class RecentEnrollmentModel {
  const RecentEnrollmentModel({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.enrolledAt,
  });

  final String id;
  final String studentName;
  final String courseTitle;
  final DateTime enrolledAt;
}

class TeacherLearnerEnrollment {
  const TeacherLearnerEnrollment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    required this.status,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseTitle;
  final DateTime enrolledAt;
  final String status;
}

class TeacherDashboardOverview {
  const TeacherDashboardOverview({
    this.totalStudents = 0,
    this.activeCourses = 0,
    this.recentEnrollments = const [],
  });

  final int totalStudents;
  final int activeCourses;
  final List<RecentEnrollmentModel> recentEnrollments;
}

class TeacherPayoutModel {
  const TeacherPayoutModel({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.method,
    required this.accountMask,
    required this.status,
    required this.requestedAt,
    this.providerReference,
    this.processedAt,
  });

  final String id;
  final int amountMinor;
  final String currency;
  final String method;
  final String accountMask;
  final String status;
  final String? providerReference;
  final DateTime requestedAt;
  final DateTime? processedAt;
}

class TeacherFinancialOverview {
  const TeacherFinancialOverview({
    this.currency = 'PKR',
    this.grossSalesMinor = 0,
    this.platformFeeMinor = 0,
    this.netEarningsMinor = 0,
    this.availableBalanceMinor = 0,
    this.pendingBalanceMinor = 0,
    this.totalWithdrawnMinor = 0,
    this.payouts = const [],
  });

  final String currency;
  final int grossSalesMinor;
  final int platformFeeMinor;
  final int netEarningsMinor;
  final int availableBalanceMinor;
  final int pendingBalanceMinor;
  final int totalWithdrawnMinor;
  final List<TeacherPayoutModel> payouts;

  String formatMinor(int amountMinor) {
    final whole = amountMinor ~/ 100;
    final grouped = whole.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return currency == 'PKR' ? 'Rs $grouped' : '$currency $grouped';
  }
}

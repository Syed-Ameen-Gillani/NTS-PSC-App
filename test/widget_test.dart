import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/features/home/presentation/pages/course_detail_screen.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/features/home/presentation/pages/home_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_students_screen.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  testWidgets('App renders and initializes with WelcomeRoleScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify role selection buttons exist on launch screen
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
  });

  test('UserRole enum parses correctly', () {
    expect(UserRole.fromString('teacher'), UserRole.teacher);
    expect(UserRole.fromString('instructor'), UserRole.teacher);
    expect(UserRole.fromString('student'), UserRole.student);
    expect(UserRole.fromString('guest'), UserRole.guest);
    expect(UserRole.fromString(null), UserRole.student);
  });

  test(
    'MockCourseRepository returns full courses with modules and lessons',
    () async {
      final repo = MockCourseRepository();
      final featured = await repo.getFeaturedCourses();
      expect(featured.isNotEmpty, true);
      expect(featured.first.modules.isNotEmpty, true);
      expect(featured.first.modules.first.lessons.isNotEmpty, true);
    },
  );

  test('MockQuizRepository correctly evaluates MCQ submissions', () async {
    final repo = MockQuizRepository();
    final quizzes = await repo.getCourseQuizzes();
    expect(quizzes.isNotEmpty, true);

    final quiz = quizzes.first;
    // Answer all questions correctly
    final userAnswers = <int, int>{};
    for (int i = 0; i < quiz.questions.length; i++) {
      userAnswers[i] = quiz.questions[i].correctOptionIndex;
    }

    final result = await repo.submitQuiz(
      quizId: quiz.id,
      userAnswers: userAnswers,
    );
    expect(result.score, quiz.questions.length);
  });

  test(
    'TeacherController correctly handles complete teacher studio operations',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial load
      final stateAsync = await container.read(teacherControllerProvider.future);
      expect(stateAsync.courses.isNotEmpty, true);
      expect(stateAsync.doubts.isNotEmpty, true);
      expect(stateAsync.liveSessions.isNotEmpty, true);
      expect(stateAsync.students.isNotEmpty, true);
      expect(stateAsync.financialOverview.payouts, isEmpty);

      final controller = container.read(teacherControllerProvider.notifier);

      // 1. Add Module
      final targetCourse = stateAsync.courses.first;
      await controller.addModule(targetCourse.id, 'New Test Module');
      var updated = container.read(teacherControllerProvider).value!;
      final courseAfterMod = updated.courses.firstWhere(
        (c) => c.id == targetCourse.id,
      );
      expect(
        courseAfterMod.modules.any((m) => m.title == 'New Test Module'),
        true,
      );

      // 2. Add Lesson
      final newMod = courseAfterMod.modules.firstWhere(
        (m) => m.title == 'New Test Module',
      );
      await controller.addLesson(
        targetCourse.id,
        newMod.id,
        LessonModel(id: 'test_l1', title: 'Test Lesson 1', durationMinutes: 15),
      );
      updated = container.read(teacherControllerProvider).value!;
      final courseAfterLesson = updated.courses.firstWhere(
        (c) => c.id == targetCourse.id,
      );
      final modAfterLesson = courseAfterLesson.modules.firstWhere(
        (m) => m.id == newMod.id,
      );
      expect(
        modAfterLesson.lessons.any((l) => l.title == 'Test Lesson 1'),
        true,
      );

      // 3. Toggle Publish
      // Publishing changes keeps the existing course available.
      await controller.togglePublishCourse(targetCourse.id);
      updated = container.read(teacherControllerProvider).value!;
      expect(
        updated.courses.firstWhere((c) => c.id == targetCourse.id).isPublished,
        isTrue,
      );

      // 4. Answer Doubt
      final targetDoubt = updated.doubts.firstWhere((d) => !d.isResolved);
      await controller.answerDoubt(targetDoubt.id, 'Expert Explanation');
      updated = container.read(teacherControllerProvider).value!;
      final resolvedDoubt = updated.doubts.firstWhere(
        (d) => d.id == targetDoubt.id,
      );
      expect(resolvedDoubt.isResolved, true);
      expect(resolvedDoubt.answer, 'Expert Explanation');

      // 5. Schedule Live Session
      await controller.scheduleLiveSession(
        LiveSessionModel(
          id: 'live_test',
          title: 'Masterclass Live',
          courseTitle: targetCourse.title,
          scheduledDate: 'Tomorrow 5 PM',
          scheduledTime: '5 PM',
          durationMinutes: 60,
          meetingUrl: 'https://meet.google.com/test',
          description: 'Test description',
        ),
      );
      updated = container.read(teacherControllerProvider).value!;
      expect(
        updated.liveSessions.any((s) => s.title == 'Masterclass Live'),
        true,
      );

      // Financial values are backend-owned and cannot be fabricated by clients.
      expect(updated.financialOverview.availableBalanceMinor, 0);
      expect(updated.financialOverview.payouts, isEmpty);
    },
  );

  test(
    'AuthController strictly separates Student and Teacher roles upon login/signup',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(authControllerProvider.notifier);

      // 1. Student Login
      final studentLoginSuccess = await authController.login(
        'student@test.com',
        'password123',
        UserRole.student,
      );
      expect(studentLoginSuccess, true);
      var authState = container.read(authControllerProvider).value!;
      expect(authState.isAuthenticated, true);
      expect(authState.selectedRole, UserRole.student);
      expect(authState.user?.role, UserRole.student);

      // 2. Teacher Login
      final teacherLoginSuccess = await authController.login(
        'teacher@test.com',
        'password123',
        UserRole.teacher,
      );
      expect(teacherLoginSuccess, true);
      authState = container.read(authControllerProvider).value!;
      expect(authState.isAuthenticated, true);
      expect(authState.selectedRole, UserRole.teacher);
      expect(authState.user?.role, UserRole.teacher);

      // 3. Teacher Signup
      final teacherSignupSuccess = await authController.signup(
        name: 'Professor Ali',
        email: 'ali@educora.com',
        password: 'password123',
        role: UserRole.teacher,
        subject: 'Pakistan Affairs',
        qualification: 'M.Phil Political Science',
        bio: '10+ years teaching CSS/FPSC candidates.',
      );
      expect(teacherSignupSuccess, true);
      authState = container.read(authControllerProvider).value!;
      expect(authState.isAuthenticated, false);
      expect(authState.selectedRole, UserRole.teacher);
      expect(authState.user, isNull);
    },
  );

  testWidgets(
    'CourseDetailScreen adapts for Teacher (Manage Curriculum) vs Student (Enroll Now)',
    (WidgetTester tester) async {
      final testCourse = CourseModel(
        id: 'c1',
        title: 'AJK PSC General Recruitment Masterclass',
        author: 'Sir Tariq',
        rating: 4.8,
        price: 'Rs 2,000',
        imagePath: 'assets/images/course1.jpg',
        category: 'AJK PSC',
        instructorId: 't1',
      );

      // 1. Render as Teacher
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _MockTeacherAuthController(),
            ),
          ],
          child: MaterialApp(home: CourseDetailScreen(course: testCourse)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Curriculum'), findsOneWidget);
      expect(find.text('Instructor Studio'), findsOneWidget);
      expect(find.text('Enroll Now'), findsNothing);
    },
  );

  testWidgets('Teacher student preview is read-only', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = CourseModel(
      id: 'preview-course',
      title: 'Preview course',
      author: 'Sir Tariq',
      rating: 0,
      price: 'Free',
      imagePath: 'assets/images/course1.jpg',
      instructorId: 't1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockStudentAuthController(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: CourseDetailScreen(course: course)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final learnerFooter = tester.getRect(find.text('Enroll Now'));
    final learnerTabs = tester.getRect(find.text('Overview'));
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockTeacherAuthController(),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: CourseDetailScreen(
              course: course,
              viewMode: CourseViewMode.learnerPreview,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student preview'), findsNothing);
    expect(find.text('Manage Curriculum'), findsNothing);
    expect(find.text('Tuition Fee'), findsOneWidget);
    expect(find.text('Enroll Now'), findsOneWidget);
    expect(tester.getRect(find.text('Enroll Now')), learnerFooter);
    expect(tester.getRect(find.text('Overview')), learnerTabs);
    expect(find.byTooltip('Learner Analytics'), findsNothing);
    expect(
      find
          .ancestor(
            of: find.text('Enroll Now'),
            matching: find.byType(IgnorePointer),
          )
          .evaluate()
          .map((element) => (element.widget as IgnorePointer).ignoring),
      contains(true),
    );
  });

  testWidgets('Teacher cannot manage another instructor course', (
    WidgetTester tester,
  ) async {
    final course = CourseModel(
      id: 'other-course',
      title: 'Another instructor course',
      author: 'Another instructor',
      rating: 0,
      price: 'Free',
      imagePath: 'assets/images/course1.jpg',
      instructorId: 'different-teacher',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _MockTeacherAuthController(),
          ),
        ],
        child: MaterialApp(home: CourseDetailScreen(course: course)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage Curriculum'), findsNothing);
    expect(find.byTooltip('Learner Analytics'), findsNothing);
  });

  testWidgets(
    'TeacherStudentsScreen displays Coursera cohort insights and allows student diagnostics',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ScreenUtilInit(
            designSize: Size(375, 812),
            child: MaterialApp(home: TeacherStudentsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and insights
      expect(find.text('Learner Analytics & Roster'), findsOneWidget);
      expect(find.text('Cohort Performance Overview'), findsOneWidget);
      expect(find.text('Coursera Insights'), findsOneWidget);
      expect(find.text('Needs Support'), findsOneWidget);

      // Scroll to Hamza Tariq if below fold
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final studentFinder = find.text('Hamza Tariq');
      expect(studentFinder, findsOneWidget);
      await tester.tap(studentFinder);
      await tester.pumpAndSettle();

      // Verify Coursera-style diagnostics sheet is displayed
      expect(find.text('Learner Diagnostics'), findsOneWidget);
      expect(find.text('Coursera-Style Performance Report'), findsOneWidget);
      expect(find.text('Send Study Nudge'), findsOneWidget);
    },
  );

  testWidgets(
    'Student role displays correct student UI and personal learning data',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: ScreenUtilInit(
            designSize: Size(375, 812),
            child: MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify student-centric features
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Interactive Masterclasses'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('New Courses'), findsOneWidget);
      expect(find.text('Teacher Dashboard'), findsNothing);

      final ajkFilter = find.descendant(
        of: find.byType(CategoryFilterChips),
        matching: find.text('AJK PSC'),
      );
      await tester.scrollUntilVisible(
        ajkFilter,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(ajkFilter);
      await tester.pump();
      expect(find.text('No courses available'), findsOneWidget);
      expect(
        find.text('There are no published AJK PSC courses yet.'),
        findsOneWidget,
      );
    },
  );

  test(
    'CourseCommunityController handles reviews, helpful votes, instructor replies, handouts, and broadcasts',
    () {
      final container = ProviderContainer();
      final controller = container.read(courseCommunityProvider.notifier);

      // Initial state
      expect(container.read(courseCommunityProvider).reviews.isNotEmpty, true);
      expect(
        container.read(courseCommunityProvider).resources.isNotEmpty,
        true,
      );
      expect(
        container.read(courseCommunityProvider).announcements.isNotEmpty,
        true,
      );
      expect(
        container.read(courseCommunityProvider).itemAnalysis.isNotEmpty,
        true,
      );

      // 1. Submit review
      final initialCount = container
          .read(courseCommunityProvider)
          .reviews
          .length;
      controller.submitReview(
        courseId: 'c1',
        studentName: 'Test Student',
        rating: 5.0,
        comment: 'Outstanding breakdown of past papers!',
      );
      expect(
        container.read(courseCommunityProvider).reviews.length,
        initialCount + 1,
      );
      expect(
        container.read(courseCommunityProvider).reviews.first.studentName,
        'Test Student',
      );

      // 2. Toggle helpful
      final reviewId = container.read(courseCommunityProvider).reviews.first.id;
      controller.toggleHelpful(reviewId);
      expect(
        container.read(courseCommunityProvider).reviews.first.helpfulCount,
        1,
      );
      expect(
        container.read(courseCommunityProvider).reviews.first.userLiked,
        true,
      );

      // 3. Instructor reply
      controller.replyAsInstructor(
        reviewId: reviewId,
        replyText: 'Glad it helped you prepare!',
      );
      expect(
        container.read(courseCommunityProvider).reviews.first.instructorReply,
        'Glad it helped you prepare!',
      );

      // 4. Download handout toggle
      final resId = container.read(courseCommunityProvider).resources.first.id;
      final initialDownloaded = container
          .read(courseCommunityProvider)
          .resources
          .first
          .isDownloaded;
      controller.toggleResourceDownload(resId);
      expect(
        container.read(courseCommunityProvider).resources.first.isDownloaded,
        !initialDownloaded,
      );

      // 5. Broadcast announcement
      final annCount = container
          .read(courseCommunityProvider)
          .announcements
          .length;
      controller.broadcastAnnouncement(
        courseId: 'c1',
        courseTitle: 'Customs Inspector',
        instructorName: 'Sir Tariq',
        title: 'Exam Alert',
        message: 'Revise Module 2 tonight!',
        isUrgent: true,
      );
      expect(
        container.read(courseCommunityProvider).announcements.length,
        annCount + 1,
      );
      expect(
        container.read(courseCommunityProvider).announcements.first.isUrgent,
        true,
      );
    },
  );

  testWidgets(
    'CourseDetailScreen displays 4 tabs including Reviews and opens Coursera-parity features',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: Size(375, 812),
            child: MaterialApp(
              home: CourseDetailScreen(
                course: CourseModel(
                  id: 'c1',
                  title: 'Learning fixture',
                  author: 'Teacher',
                  rating: 0,
                  price: 'Free',
                  imagePath: 'assets/images/course1.jpg',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 4 tabs exist
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Syllabus'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('Instructor'), findsOneWidget);

      // Verify Overview Coursera action banners
      expect(find.text('Course Handouts & Past Papers'), findsOneWidget);
      expect(find.text('Verified Certificate of Completion'), findsNothing);

      // Tap Reviews tab
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();

      // Verify Reviews tab contents
      expect(find.text('Write a Verified Review'), findsOneWidget);
      expect(find.textContaining('Student Reviews'), findsOneWidget);
    },
  );
}

class _MockTeacherAuthController extends AuthController {
  @override
  FutureOr<AuthState> build() {
    return AuthState(
      user: UserModel(
        id: 't1',
        name: 'Sir Tariq',
        email: 'tariq@test.com',
        role: UserRole.teacher,
        imagePath: 'assets/images/teacher1.png',
        isPremium: true,
        courses: 4,
        quizzes: 12,
        avgScore: 85,
      ),
      selectedRole: UserRole.teacher,
      isAuthenticated: true,
    );
  }
}

class _MockStudentAuthController extends AuthController {
  @override
  FutureOr<AuthState> build() => AuthState(
    user: UserModel(
      id: 'student-1',
      name: 'Student',
      email: 'student@test.com',
      role: UserRole.student,
      imagePath: '',
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
    ),
    selectedRole: UserRole.student,
    isAuthenticated: true,
  );
}

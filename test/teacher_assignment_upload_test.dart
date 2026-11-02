import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_create_assignment_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

class _TeacherAuth extends AuthController {
  @override
  AuthState build() => AuthState(selectedRole: UserRole.teacher);
}

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = true);
  tearDown(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('live assignment form offers file attachment', (tester) async {
    final course = CourseModel(
      id: 'course-1',
      title: 'Pakistan Affairs',
      author: 'Teacher',
      rating: 0,
      price: 'Free',
      imagePath: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(_TeacherAuth.new)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: TeacherCreateAssignmentScreen(course: course)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Files (Optional)'), findsOneWidget);
    expect(find.text('Attach documents, images, or video'), findsOneWidget);

    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is CustomTextFormField &&
          widget.hintText == 'e.g. Customs Act case study',
    );
    final titleFocus = tester
        .widget<EditableText>(
          find.descendant(of: titleField, matching: find.byType(EditableText)),
        )
        .focusNode;
    await tester.tap(titleField);
    await tester.pump();
    expect(titleFocus.hasFocus, isTrue);
    await tester.tap(find.text('Assignment Title'));
    await tester.pump();
    expect(titleFocus.hasFocus, isFalse);
  });
}

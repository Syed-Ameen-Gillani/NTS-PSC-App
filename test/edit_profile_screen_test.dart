import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/pages/edit_profile_screen.dart';

UserModel _user(UserRole role) => UserModel(
  id: '${role.name}-1',
  name: role == UserRole.teacher ? 'Ayesha Khan' : 'Ali Raza',
  email: '${role.name}@example.com',
  imagePath: AppAssets.teacher1,
  isPremium: false,
  courses: 0,
  quizzes: 0,
  avgScore: 0,
  role: role,
  subject: role == UserRole.teacher ? 'Pakistan Affairs' : null,
);

class _AuthController extends AuthController {
  _AuthController(this.user);
  final UserModel user;

  @override
  FutureOr<AuthState> build() =>
      AuthState(user: user, selectedRole: user.role, isAuthenticated: true);
}

class _ProfileController extends ProfileController {
  _ProfileController(this.user, {this.saveStarted, this.releaseSave});
  final UserModel user;
  final Completer<void>? saveStarted;
  final Completer<void>? releaseSave;

  @override
  FutureOr<UserModel> build() => user;

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String location,
    Uint8List? avatarBytes,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    saveStarted?.complete();
    await releaseSave?.future;
    throw StateError('Test save failure');
  }
}

Widget _app(
  UserModel user, {
  Completer<void>? saveStarted,
  Completer<void>? releaseSave,
}) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(() => _AuthController(user)),
    profileControllerProvider.overrideWith(
      () => _ProfileController(
        user,
        saveStarted: saveStarted,
        releaseSave: releaseSave,
      ),
    ),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: const EditProfileScreen(),
    ),
  ),
);

void main() {
  for (final role in [UserRole.student, UserRole.teacher]) {
    testWidgets('${role.name} cannot edit email and can change photo', (
      tester,
    ) async {
      final user = _user(role);
      await tester.pumpWidget(_app(user));
      await tester.pumpAndSettle();

      final emailField = tester.widget<EditableText>(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditableText && widget.controller.text == user.email,
        ),
      );
      expect(emailField.readOnly, isTrue);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      if (role == UserRole.teacher) {
        expect(find.text('TEACHING DETAILS'), findsOneWidget);
      }
    });
  }

  testWidgets('profile Next skips the locked email field', (tester) async {
    await tester.pumpWidget(_app(_user(UserRole.student)));
    await tester.pumpAndSettle();

    final name = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == 'Ali Raza',
    );
    await tester.tap(name);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final phone = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.keyboardType == TextInputType.phone,
    );
    expect(tester.widget<EditableText>(phone).focusNode.hasFocus, isTrue);
  });

  testWidgets('saving blocks all actions and back navigation', (tester) async {
    final started = Completer<void>();
    final release = Completer<void>();
    await tester.pumpWidget(
      _app(_user(UserRole.student), saveStarted: started, releaseSave: release),
    );
    await tester.pumpAndSettle();
    final initialBarrierCount = find.byType(ModalBarrier).evaluate().length;

    await tester.tap(find.text('Save Changes'));
    await started.future;
    await tester.pump();

    expect(
      find.byType(ModalBarrier).evaluate().length,
      initialBarrierCount + 1,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AbsorbPointer && widget.absorbing,
      ),
      findsWidgets,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton).first).onPressed,
      isNull,
    );

    release.complete();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(ModalBarrier).evaluate().length, initialBarrierCount);
  });
}

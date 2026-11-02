import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/auth_repository.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  for (final role in [UserRole.student, UserRole.teacher]) {
    test('$role registration clears the session and requires login', () async {
      final repository = _RegistrationRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final controller = container.read(authControllerProvider.notifier);

      expect(
        await controller.signup(
          name: 'New User',
          email: 'new@example.com',
          password: 'password123',
          role: role,
        ),
        true,
      );
      final state = container.read(authControllerProvider).requireValue;
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
      expect(state.selectedRole, role);
      expect(repository.signOutCount, 1);
      expect(await repository.getCurrentUser(), isNull);

      expect(
        await controller.login('new@example.com', 'password123', role),
        true,
      );
      expect(
        container.read(authControllerProvider).requireValue.isAuthenticated,
        true,
      );
      expect(
        container.read(authControllerProvider).requireValue.user?.role,
        role,
      );
    });
  }
}

class _RegistrationRepository implements AuthRepository {
  UserModel? user;
  int signOutCount = 0;

  UserModel _user(UserRole role) => UserModel(
    id: 'new-user',
    name: 'New User',
    email: 'new@example.com',
    imagePath: '',
    isPremium: false,
    courses: 0,
    quizzes: 0,
    avgScore: 0,
    role: role,
  );

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  }) async => user = _user(role);

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async => user = _user(role);

  @override
  Future<void> signOut() async {
    signOutCount++;
    user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

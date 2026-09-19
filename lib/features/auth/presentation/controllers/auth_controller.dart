import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

class AuthState {
  final UserModel? user;
  final UserRole selectedRole;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.selectedRole = UserRole.student,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    UserRole? selectedRole,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      selectedRole: selectedRole ?? this.selectedRole,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final current = await repo.getCurrentUser();
    return AuthState(
      user: current,
      selectedRole: current?.role ?? UserRole.student,
      isAuthenticated: current != null,
    );
  }

  void selectRole(UserRole role) {
    final current = state.value ?? AuthState();
    state = AsyncValue.data(current.copyWith(selectedRole: role));
  }

  /// Logs in a user with their email, password and role
  Future<bool> login(String email, String password, [UserRole? role]) async {
    final targetRole = role ?? state.value?.selectedRole ?? UserRole.student;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(
        email: email,
        password: password,
        role: targetRole,
      );
      state = AsyncValue.data(AuthState(
        user: user,
        selectedRole: targetRole,
        isAuthenticated: true,
      ));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Registers a user (Student or Teacher)
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
        subject: subject,
        qualification: qualification,
        bio: bio,
      );
      state = AsyncValue.data(AuthState(
        user: user,
        selectedRole: role,
        isAuthenticated: true,
      ));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Password reset
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordReset(email);
      final current = state.value ?? AuthState();
      state = AsyncValue.data(current);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Log out
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = AsyncValue.data(AuthState(
      user: null,
      selectedRole: UserRole.student,
      isAuthenticated: false,
    ));
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

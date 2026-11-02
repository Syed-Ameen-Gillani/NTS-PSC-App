import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/notifications/data/push_registration.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';

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
    if (AppConfig.isSupabaseEnabled) {
      final subscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            (data) {
              if (data.event == AuthChangeEvent.signedOut) {
                AppConfig.restoredRole = null;
                state = AsyncValue.data(AuthState());
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              // A transient token-refresh failure should not crash the app.
            },
          );
      ref.onDispose(subscription.cancel);
    }
    final repo = ref.read(authRepositoryProvider);
    final current = await repo.getCurrentUser();
    if (AppConfig.isSupabaseEnabled) AppConfig.restoredRole = current?.role;
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

  Future<void> updateProfile(UserModel user, {Uint8List? avatarBytes}) async {
    final updated = await ref
        .read(authRepositoryProvider)
        .updateProfile(user, avatarBytes: avatarBytes);
    final current = state.value ?? AuthState();
    state = AsyncValue.data(current.copyWith(user: updated));
  }

  /// Logs in a user with their email, password and role
  Future<bool> login(String email, String password, [UserRole? role]) async {
    AuthIntegrations.awaitingOAuth = false;
    final targetRole = role ?? state.value?.selectedRole ?? UserRole.student;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(
        email: email,
        password: password,
        role: targetRole,
      );
      if (AppConfig.isSupabaseEnabled) AppConfig.restoredRole = user.role;
      state = AsyncValue.data(
        AuthState(user: user, selectedRole: targetRole, isAuthenticated: true),
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Creates an account, then requires an explicit sign-in.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    AuthIntegrations.awaitingOAuth = false;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
        subject: subject,
        qualification: qualification,
        bio: bio,
      );
      // Supabase can create a session when email confirmation is disabled.
      await repo.signOut();
      if (AppConfig.isSupabaseEnabled) AppConfig.restoredRole = null;
      state = AsyncValue.data(AuthState(selectedRole: role));
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
    try {
      await PushRegistration.unregister();
    } catch (_) {
      // Do not trap the user in a session when the network is unavailable.
    }
    await LocalNotificationService.instance.cancelAll();
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    if (AppConfig.isSupabaseEnabled) AppConfig.restoredRole = null;
    state = AsyncValue.data(
      AuthState(
        user: null,
        selectedRole: UserRole.student,
        isAuthenticated: false,
      ),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  () {
    return AuthController();
  },
);

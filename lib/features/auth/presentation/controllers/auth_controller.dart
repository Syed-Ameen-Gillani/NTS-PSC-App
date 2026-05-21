import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Simulates a login API call
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
    });
    return !state.hasError;
  }

  /// Simulates a signup API call
  Future<bool> signup(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
    });
    return !state.hasError;
  }

  /// Simulates sending a password reset email
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
    });
    return !state.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

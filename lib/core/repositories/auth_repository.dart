import 'dart:typed_data';

import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateProfile(UserModel user, {Uint8List? avatarBytes});
}

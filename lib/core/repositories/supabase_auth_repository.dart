import 'dart:typed_data';

import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/repositories/auth_repository.dart';
import 'package:nts_psc_app/core/utils/image_upload_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart';
import 'package:uuid/uuid.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw StateError('Sign-in did not return a user.');
    final profile = await _loadProfile(user);
    if (profile.role != role) {
      await _client.auth.signOut();
      throw StateError(
        'This account is registered as a ${profile.role.label}.',
      );
    }
    return profile;
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    if (role == UserRole.guest) {
      throw ArgumentError.value(role, 'role', 'Guests cannot create accounts.');
    }
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'display_name': name.trim(),
        'requested_role': role.name,
        if (subject != null) 'subject': subject.trim(),
        if (qualification != null) 'qualification': qualification.trim(),
        if (bio != null) 'bio': bio.trim(),
      },
    );
    final user = response.user;
    if (user == null || response.session == null) {
      throw StateError(
        'Sign-up requires immediate sign-in. Disable Confirm email in Supabase Auth settings.',
      );
    }
    return _loadProfile(user);
  }

  @override
  Future<void> sendPasswordReset(String email) => _client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: authRedirectUrl);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadProfile(user);
  }

  @override
  Future<UserModel> updateProfile(
    UserModel user, {
    Uint8List? avatarBytes,
  }) async {
    final current = _client.auth.currentUser;
    if (current == null || current.id != user.id) {
      throw StateError('Sign in again to edit your profile.');
    }

    final existing = await _client
        .from('profiles')
        .select('avatar_path')
        .eq('id', current.id)
        .single();
    final oldAvatarPath = existing['avatar_path'] as String?;
    String? newAvatarPath;

    if (avatarBytes != null) {
      final mime = await ImageUploadValidator.validate(avatarBytes);
      final extension = mime == 'image/jpeg' ? 'jpg' : mime.split('/').last;
      newAvatarPath = '${current.id}/${const Uuid().v4()}.$extension';
      await _client.storage
          .from('profile-avatars')
          .uploadBinary(
            newAvatarPath,
            avatarBytes,
            fileOptions: FileOptions(contentType: mime),
          );
    }

    try {
      await _client
          .from('profiles')
          .update({
            'display_name': user.name.trim(),
            'phone': user.phone?.trim(),
            'location': user.location?.trim(),
            'subject': user.subject?.trim(),
            'qualification': user.qualification?.trim(),
            'bio': user.bio?.trim(),
            if (newAvatarPath != null) 'avatar_path': newAvatarPath,
          })
          .eq('id', current.id);
    } catch (_) {
      if (newAvatarPath != null) {
        await _removeAvatarQuietly(newAvatarPath);
      }
      rethrow;
    }

    if (newAvatarPath != null && oldAvatarPath != null) {
      await _removeAvatarQuietly(oldAvatarPath);
    }
    return _loadProfile(_client.auth.currentUser ?? current);
  }

  Future<void> _removeAvatarQuietly(String path) async {
    try {
      await _client.storage.from('profile-avatars').remove([path]);
    } catch (_) {
      // The saved profile remains valid; orphan cleanup can safely run later.
    }
  }

  Future<UserModel> _loadProfile(User user) async {
    final row = await _client
        .from('profiles')
        .select(
          'id, display_name, role, avatar_path, subject, qualification, bio, phone, location',
        )
        .eq('id', user.id)
        .single();
    return UserModel(
      id: row['id'] as String,
      name: row['display_name'] as String,
      email: user.email ?? '',
      imagePath: _avatarUrl(row['avatar_path'] as String?),
      isPremium: false,
      courses: 0,
      quizzes: 0,
      avgScore: 0,
      role: UserRole.fromString(row['role'] as String?),
      subject: row['subject'] as String?,
      qualification: row['qualification'] as String?,
      bio: row['bio'] as String?,
      phone: row['phone'] as String?,
      location: row['location'] as String?,
    );
  }

  String _avatarUrl(String? path) {
    if (path == null || path.isEmpty) return AppAssets.teacher1;
    return _client.storage.from('profile-avatars').getPublicUrl(path);
  }
}

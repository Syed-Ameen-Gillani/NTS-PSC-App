import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class ProfileController extends AsyncNotifier<UserModel> {
  @override
  FutureOr<UserModel> build() async {
    final authState = AppConfig.isSupabaseEnabled
        ? await ref.watch(authControllerProvider.future)
        : ref.watch(authControllerProvider).value;
    final authUser = authState?.user;
    if (authUser != null) {
      return authUser;
    }
    if (AppConfig.isSupabaseEnabled) {
      throw StateError('Sign in to view your profile.');
    }
    if (authState?.selectedRole == UserRole.teacher) {
      return UserModel(
        id: 'teacher_1',
        name: 'Sir Tariq Mahmood',
        email: 'tariq.mahmood@example.com',
        imagePath: AppAssets.teacher1,
        isPremium: false,
        courses: 4,
        quizzes: 12,
        avgScore: 88,
        role: UserRole.teacher,
        subject: 'Pakistan Affairs & GK Specialist',
        qualification: 'M.Phil Political Science / Former Civil Servant',
      );
    }
    return UserModel(
      id: '1',
      name: 'Ahmed Ali',
      email: 'ahmed.ali@example.com',
      imagePath: AppAssets.teacher1,
      isPremium: true,
      courses: 4,
      quizzes: 12,
      avgScore: 85,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String location,
    Uint8List? avatarBytes,
    String? subject,
    String? qualification,
    String? bio,
  }) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(
      name: name,
      phone: phone,
      location: location,
      subject: subject,
      qualification: qualification,
      bio: bio,
    );
    if (ref.read(authControllerProvider).value?.user != null) {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(updated, avatarBytes: avatarBytes);
      state = AsyncValue.data(ref.read(authControllerProvider).value!.user!);
      return;
    }
    state = AsyncValue.data(updated);
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserModel>(() {
      return ProfileController();
    });

final editProfileSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final pendingProfilePhotoProvider = StateProvider.autoDispose
    .family<Uint8List?, String>((ref, userId) => null);

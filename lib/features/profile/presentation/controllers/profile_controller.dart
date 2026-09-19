import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

class ProfileController extends AsyncNotifier<UserModel> {
  @override
  FutureOr<UserModel> build() async {
    final authUser = ref.watch(authControllerProvider).value?.user;
    if (authUser != null) {
      return authUser;
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

  void updateProfile({String? name, String? email, String? imagePath}) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(UserModel(
        id: current.id,
        name: name ?? current.name,
        email: email ?? current.email,
        imagePath: imagePath ?? current.imagePath,
        isPremium: current.isPremium,
        courses: current.courses,
        quizzes: current.quizzes,
        avgScore: current.avgScore,
        role: current.role,
      ));
    }
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserModel>(() {
  return ProfileController();
});

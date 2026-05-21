import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class ProfileController extends AsyncNotifier<UserModel> {
  @override
  FutureOr<UserModel> build() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return UserModel(
      id: '1',
      name: 'Ahmed Ali',
      email: 'ahmed.ali@example.com',
      imagePath: AppAssets.teacher1, // Using teacher1 as a dummy profile picture
      isPremium: true,
      courses: 4,
      quizzes: 12,
      avgScore: 85,
    );
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserModel>(() {
  return ProfileController();
});

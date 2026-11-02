import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' show ClientException;
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_auth_repository.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/data/course_download_ledger.dart';
import 'package:nts_psc_app/features/learn/data/offline_reading_store.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_activity_sync.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/core/theme/system_navigation_bar_style.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/notifications/data/push_registration.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_navigation_controller.dart';
import 'package:nts_psc_app/features/auth/data/auth_integrations.dart'
    as integrations;
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart'
    as authentication;
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/user_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadPublicConfig();
  AppConfig.validate();
  await initializeNotificationBootstrap();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  if (!kIsWeb) {
    await FileDownloader().start(autoCleanDatabase: true);
    await OfflineLessonLibrary.purgeOtherUsers(
      Supabase.instance.client.auth.currentUser?.id,
    );
    await CourseDownloadLedger().purgeOtherUsers(
      Supabase.instance.client.auth.currentUser?.id,
    );
    await OfflineReadingStore(
      Supabase.instance.client,
    ).purgeOtherUsers(Supabase.instance.client.auth.currentUser?.id);
    final offlineLibrary = OfflineLessonLibrary(
      LessonMediaRepository(Supabase.instance.client),
    );
    unawaited(offlineLibrary.syncAnswers());
    Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(offlineLibrary.syncAnswers());
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut ||
          event.event == AuthChangeEvent.signedIn) {
        OfflineLessonLibrary.purgeOtherUsers(event.session?.user.id);
        CourseDownloadLedger().purgeOtherUsers(event.session?.user.id);
        OfflineReadingStore(
          Supabase.instance.client,
        ).purgeOtherUsers(event.session?.user.id);
        if (event.session != null) unawaited(offlineLibrary.syncAnswers());
      }
    });
  }
  if (Supabase.instance.client.auth.currentUser != null) {
    try {
      AppConfig.restoredRole = (await SupabaseAuthRepository(
        Supabase.instance.client,
      ).getCurrentUser().timeout(const Duration(seconds: 15)))?.role;
    } on SocketException {
      await _openOfflineDownloads();
    } on ClientException {
      await _openOfflineDownloads();
    } on TimeoutException {
      await _openOfflineDownloads();
    } catch (_) {
      AppConfig.restoredRole = null;
    }
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _openOfflineDownloads() async {
  AppConfig.restoredRole = null;
  if (kIsWeb) return;
  final library = OfflineLessonLibrary(
    LessonMediaRepository(Supabase.instance.client),
  );
  final owner = Supabase.instance.client.auth.currentUser?.id;
  final hasReadings =
      owner != null &&
      (await OfflineReadingStore(
        Supabase.instance.client,
      ).list(owner)).isNotEmpty;
  if ((await library.listDownloads()).isNotEmpty || hasReadings) {
    appRouter.goNamed(AppRoute.offlineDownloads.name);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushRegistrationProvider);
    ref.watch(notificationLifecycleProvider);
    ref.watch(notificationNavigationProvider);
    ref.watch(learningActivitySyncProvider);
    ref.listen(integrations.authCallbackProvider, (previous, next) async {
      final event = next.value?.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        integrations.AuthIntegrations.recoveringPassword = true;
        appRouter.goNamed(AppRoute.resetPassword.name);
      } else if (event == AuthChangeEvent.signedIn &&
          integrations.AuthIntegrations.awaitingOAuth) {
        integrations.AuthIntegrations.awaitingOAuth = false;
        ref.invalidate(authentication.authControllerProvider);
        try {
          final state = await ref.read(
            authentication.authControllerProvider.future,
          );
          if (!context.mounted) return;
          appRouter.goNamed(
            state.user?.role == UserRole.teacher
                ? AppRoute.teacherMain.name
                : AppRoute.main.name,
          );
        } catch (_) {
          if (context.mounted) appRouter.goNamed(AppRoute.login.name);
        }
      }
    });
    final size = MediaQuery.sizeOf(context);
    final scale = math
        .min(size.width / 375, size.height / 812)
        .clamp(0.85, 1.2);
    final designSize = Size(size.width / scale, size.height / scale);
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scrollBehavior: keyboardDismissScrollBehavior,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemNavigationBarStyle(
              Theme.of(context).scaffoldBackgroundColor,
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
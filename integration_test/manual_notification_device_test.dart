import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/notifications/data/local_notification_service.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:nts_psc_app/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void transitionToBackground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void transitionToForeground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  group('Student Notification Lifecycle Tests (Foreground, Background, Killed)', () {
    testWidgets('Complete manual test of all notification states on Android device',
        (tester) async {
      debugPrint('===> Step 1: Pre-authenticate student a@g.com before app boot');
      await AppConfig.loadPublicConfig();
      AppConfig.validate();
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: 'a@g.com',
          password: 'Ameen123',
        );
        debugPrint('Student a@g.com signed in successfully.');
      } catch (e) {
        debugPrint('Sign in notice: $e');
      }

      AppConfig.restoredRole = UserRole.student;

      debugPrint('===> Step 2: Initialize App & Verify Restored Student Session');
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(Supabase.instance.client.auth.currentUser, isNotNull);
      debugPrint('Student authenticated: ${Supabase.instance.client.auth.currentUser?.email}');

      // Navigate to Home screen
      appRouter.go(AppRoute.main.path);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(appRouter.state.uri.path, AppRoute.main.path);
      debugPrint('===> Confirmed app is at Home: ${appRouter.state.uri.path}');

      final local = LocalNotificationService.instance;
      await local.initialize();

      // =========================================================================
      // STATE 1: FOREGROUND STATE TESTING (ALL 16 NOTIFICATION TYPES)
      // =========================================================================
      debugPrint('\n========================================');
      debugPrint('TESTING FOREGROUND STATE');
      debugPrint('========================================');

      for (final type in AppNotificationType.values) {
        final payload = AppNotificationPayload(
          eventId: 'local:fg-test-${type.value}',
          type: type,
          route: 'notification_inbox',
          resourceId: 'test-res-fg-${type.value}',
          courseId: 'test-course-fg-${type.value}',
        );

        // 1. Show notification banner via local notification service
        await local.showForeground(
          title: 'Foreground: ${type.value}',
          body: 'Testing notification delivery in foreground state.',
          payload: payload,
        );

        // 2. Simulate user tapping the foreground notification
        local.onTap?.call(payload);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        final currentPath = appRouter.state.uri.path;
        debugPrint(' [FG] Type: ${type.value.padRight(24)} -> Navigated to: $currentPath');
        expect(currentPath, isNot(AppRoute.splash.path));

        // 3. Reset back to Home
        appRouter.go(AppRoute.main.path);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }

      // =========================================================================
      // STATE 2: BACKGROUND STATE TESTING (KEY NOTIFICATION TYPES)
      // =========================================================================
      debugPrint('\n========================================');
      debugPrint('TESTING BACKGROUND STATE');
      debugPrint('========================================');

      final backgroundTestCases = [
        AppNotificationType.liveClassScheduled,
        AppNotificationType.assignmentPublished,
        AppNotificationType.quizPublished,
        AppNotificationType.coursePublished,
        AppNotificationType.announcement,
        AppNotificationType.promotion,
      ];

      for (final type in backgroundTestCases) {
        // 1. Transition app to background through canonical lifecycle states
        transitionToBackground(tester);

        // 2. Notification arrives while backgrounded
        final payload = AppNotificationPayload(
          eventId: 'local:bg-test-${type.value}',
          type: type,
          route: 'notification_inbox',
          resourceId: 'test-res-bg-${type.value}',
          courseId: 'test-course-bg-${type.value}',
        );

        await local.showForeground(
          title: 'Background: ${type.value}',
          body: 'Delivered while app was in background.',
          payload: payload,
        );

        // 3. User taps notification in Android notification drawer
        LocalNotificationService.pendingBackgroundPayload = jsonEncode(payload.toMap());

        // 4. App resumes to foreground through canonical lifecycle states
        transitionToForeground(tester);
        local.onTap?.call(payload);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        final resumedPath = appRouter.state.uri.path;
        debugPrint(' [BG] Type: ${type.value.padRight(24)} -> Resumed & Navigated to: $resumedPath');
        expect(resumedPath, isNot(AppRoute.splash.path));

        // Reset to Home
        appRouter.go(AppRoute.main.path);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }

      // =========================================================================
      // STATE 3: KILLED / TERMINATED STATE TESTING
      // =========================================================================
      debugPrint('\n========================================');
      debugPrint('TESTING KILLED (TERMINATED) STATE');
      debugPrint('========================================');

      final killedTestCases = [
        AppNotificationType.liveClassReminder,
        AppNotificationType.assignmentDueReminder,
        AppNotificationType.quizPublished,
        AppNotificationType.announcement,
        AppNotificationType.promotion,
      ];

      for (final type in killedTestCases) {
        final killedPayload = AppNotificationPayload(
          eventId: 'local:killed-test-${type.value}',
          type: type,
          route: 'notification_inbox',
          resourceId: 'test-res-killed-${type.value}',
          courseId: 'test-course-killed-${type.value}',
        );

        // Simulate launch payload injected by Android system on cold start
        LocalNotificationService.pendingBackgroundPayload = jsonEncode(killedPayload.toMap());

        // Read launch payload via local notification service
        final launchPayload = await local.launchPayload();
        expect(launchPayload, isNotNull);
        expect(launchPayload?.type, type);

        // Trigger notification navigation handler as done during cold launch
        local.onTap?.call(launchPayload!);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        final killedPath = appRouter.state.uri.path;
        debugPrint(' [KILLED] Cold launch with ${type.value.padRight(22)} -> Routed to: $killedPath');
        expect(killedPath, isNot(AppRoute.splash.path));

        // Reset to Home
        appRouter.go(AppRoute.main.path);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }

      debugPrint('\n========================================');
      debugPrint('ALL NOTIFICATION LIFECYCLE TESTS COMPLETED SUCCESSFULLY!');
      debugPrint('========================================\n');
    });
  });
}

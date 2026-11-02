# Integration Configuration

## Current switches

Google OAuth, Supabase, and push support are production defaults. Apple OAuth remains disabled until its provider credentials are complete through `APPLE_AUTH_ENABLED`.
`PUSH_ENABLED` defaults to true and is retained only as an emergency build-time kill switch (`--dart-define=PUSH_ENABLED=false`).
Do not pass the private `.env` file to Flutter. Do not create fake provider keys or commit service accounts.
Live classes use course-scoped external HTTPS links; PayFast and store release are deferred.

## Password recovery: steps to configure

1. Open Supabase project Authentication > URL Configuration. Add the exact redirect `com.ntspsc.app://auth-callback/` to Redirect URLs. The app's Android intent filter and iOS URL scheme use this value.
2. The mobile-only deployment currently uses `com.ntspsc.app://auth-callback/` as Site URL. When an actual HTTPS site is available, it can become the default while retaining the mobile callback in Redirect URLs. The mobile reset request passes its redirect explicitly.
3. Under Authentication > Email/SMTP settings, configure a real SMTP host, port, username, password, verified sender email and sender name. Keep credentials in Supabase, not the app. Until then the hosted default email service may restrict recipients/delivery.
4. Keep the reset-password email template's confirmation link intact so Supabase validates the token before redirecting to the app.
5. On the Android emulator, create/use a test account. Choose Forgot password, request the email, and open its recovery link on the same device/app installation that requested it (PKCE verifier is local).
6. The `passwordRecovery` auth event opens Reset password. Enter matching passwords (minimum eight characters). A successful update signs out; sign in with the new password.
7. Verify old password rejection, expired/reused links, cancellation, missing session, warm/cold app links, offline failure and retry. Cold-start recovery must be included in device acceptance, not assumed from unit tests.

Provider callback URL (Google/Apple dashboards):
`https://rgpeouxesbemysmwbzmu.supabase.co/auth/v1/callback`
This differs from the app redirect above: provider -> Supabase -> app.

## Google

- Status (user-confirmed 2026-10-12): Google Cloud OAuth and the Supabase Google provider are configured. Preserve the existing client ID/secret and callback configuration. Runtime Android verification remains pending.
- Redirect fix (hosted settings verified 2026-10-25): the provider was enabled with a client ID and secret, but Site URL was still `http://localhost:3000` and Redirect URLs was empty. Set both the mobile Site URL and exact allowed redirect to `com.ntspsc.app://auth-callback/`. Readback confirmed the change and preserved provider credentials. The local Supabase config now mirrors the mobile redirect. Restart Google sign-in from the app after closing the old localhost tab; no app rebuild is needed for this hosted configuration change. A complete user-consent round trip still requires device verification.
- Create/configure a Google OAuth web client for Supabase's browser-based OAuth flow, OAuth consent screen/test users, and the Supabase callback URI above.
- Enable Google in Supabase Authentication > Providers with client ID and secret. The secret belongs only in Supabase.
- Google OAuth no longer requires a Dart define. Test success, denied consent, browser cancellation, already-linked account and cold start.
- This implementation uses browser OAuth, not native Google sign-in. Android native client/SHA configuration is needed only if switching to the native SDK.
- Existing profiles keep their persisted role. New social accounts currently inherit the database's student default. Teacher email signup remains available; social teacher role-onboarding is still part of the account lifecycle phase and must not silently change existing roles.

## Apple

- Requires an Apple Developer account. APNs alone does not enable Apple sign-in.
- Configure App ID/Sign in with Apple, associated Service ID, verified domain and the Supabase return URL. Configure the Apple provider signing credentials in Supabase.
- The current implementation uses browser OAuth. Follow Apple's client-secret renewal requirements and keep signing keys outside source control.
- Build for iOS with `APPLE_AUTH_ENABLED=true` only after provider setup. The Apple button remains iOS-only. Verify private relay email and returning users; never require Apple to resend a full name.
- Review bundle identifier, provisioning, URL scheme and signing on macOS. An Android test or Windows analyzer cannot verify an iOS build.
- Installed Firebase plugins require iOS 15.0. Project/framework deployment targets now match, and a CocoaPods Podfile is included. Run `flutter pub get` and `pod install` on macOS before the first Xcode build. This raises the previously declared iOS 12 minimum.

## FCM client

1. Current project: `nts-psc-mobile`. Android and iOS registrations use `com.ntspsc.app`.
2. FlutterFire generated `lib/firebase_options.dart`; Android has the Google Services plugin and ignored `android/app/google-services.json`. The client initializes from generated `DefaultFirebaseOptions`. Re-run FlutterFire only when app registration or platforms change.
3. Status (verified 2026-10-14): FCM HTTP v1 is enabled and `FCM_SERVICE_ACCOUNT_JSON` is installed as a Supabase Edge Function secret. Keep the downloaded JSON outside the repository and rotate it if it is ever exposed.
4. Status (verified 2026-10-14): one `NOTIFICATION_WORKER_SECRET` is synchronized between Edge Function Secrets and Supabase Vault. Two notification cron jobs are active and the latest worker invocation returned HTTP 200. Never store or display the value in source control or logs.
5. iOS source configuration is ready: background remote notifications are declared, the development APNs entitlement is attached to Runner build configurations, foreground presentation/taps/cold starts are handled, and FCM waits for an APNs token. When the Apple Developer account is available, enable Push Notifications and Background Modes > Remote notifications for the App ID, upload an APNs authentication key to Firebase, and regenerate provisioning profiles. Xcode may replace the development entitlement with the distribution value during archive signing.
6. On authenticated mobile sessions with push preferences enabled, permission is requested contextually, the token is registered through an owner-authorized RPC, refreshes are persisted, and logout revokes the device and clears local notifications. Denied users are directed to OS settings. iOS provisional authorization is supported by the permission API.
7. The app handles foreground display, background and terminated taps, delayed auth-aware navigation, inaccessible resources, malformed/expired payloads, unread badge counts, notification grouping, and persisted local live-class reminders. Android has separate learning, reminder, and quiet-update channels.
8. Runtime acceptance is still required on a physical Android device and, after APNs setup, a physical iPhone. Windows static analysis and an Android APK build do not certify APNs delivery or iOS signing.

## FCM server and scheduler

- `FCM_SERVICE_ACCOUNT_JSON` is stored only as a Supabase Edge Function secret. Never place it in Flutter assets.
- `NOTIFICATION_WORKER_SECRET` is stored in Edge Function secrets and Supabase Vault. The checked-in scheduler reads it at execution time; the value is not embedded in SQL.
- Deploy `send-push` with gateway JWT verification disabled because its own worker-secret authorization protects invocation. No user-facing unauthenticated send endpoint exists.
- Trusted scheduler: POST `/functions/v1/send-push` every minute with `Authorization: Bearer <worker secret>` from secret storage. Do not embed it in a client or checked-in cron SQL.
- Course announcements, live-class lifecycle events, assignment publication/due/submission/review, quiz publication, and lesson publication create durable in-app notifications and queue eligible pushes. The worker rechecks current authorization, resource state, and preferences at send time. Meeting URLs and private content are never included in payloads.
- The worker uses FCM HTTP v1, bounded claims, a retry lease and exponential delay, removes invalid device tokens, and stores per-device delivery receipts to avoid resending successful deliveries during a partial retry. Collapse IDs remain a second display-level duplicate guard.
- Absent/invalid credentials return errors, never success. Five-attempt failures need operator monitoring; production scheduler/telemetry configuration remains a release gate.

## Deferred release checklist

PayFast credentials/contracts, store listings, support/privacy/terms approval, staging isolation, production monitoring and backup/restore drills remain deferred. Android testing uses the installed Pixel 5 emulator; obtain macOS/iOS runtime access before promising iOS release readiness.

## Primary references

- [Supabase mobile deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter)
- [Supabase OAuth API](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
- [Google provider](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Apple provider](https://supabase.com/docs/guides/auth/social-login/auth-apple?platform=flutter)
- [Firebase Flutter setup and APNs/token requirements](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [FCM HTTP v1 server authorization](https://firebase.google.com/docs/cloud-messaging/send/v1-api)

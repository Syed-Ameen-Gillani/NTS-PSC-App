import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase initializes and issues an FCM registration token',
      (tester) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    expect(Firebase.app().options.projectId, 'nts-psc-mobile');
    final token = await FirebaseMessaging.instance.getToken();
    expect(token, isNotNull);
    expect(token, isNotEmpty);
  });
}

import 'dart:async';

import 'package:nts_psc_app/core/networks/supabase_client.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.isSupabaseEnabled = false;
  await testMain();
}

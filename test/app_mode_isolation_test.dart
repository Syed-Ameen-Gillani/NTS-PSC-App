import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

void main() {
  test('production is Supabase-only while tests retain isolated fixtures', () {
    expect(AppConfig.usesSupabaseInProduction, isTrue);
    expect(AppConfig.isSupabaseEnabled, isFalse);
  });
}

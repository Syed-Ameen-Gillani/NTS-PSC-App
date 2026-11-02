import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/assignments/data/mock_assignment_repository.dart';
import 'package:nts_psc_app/features/assignments/data/supabase_assignment_repository.dart';
import 'package:nts_psc_app/features/assignments/domain/repositories/assignment_repository.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>(
  (ref) => AppConfig.isSupabaseEnabled
      ? SupabaseAssignmentRepository(Supabase.instance.client)
      : MockAssignmentRepository(),
);

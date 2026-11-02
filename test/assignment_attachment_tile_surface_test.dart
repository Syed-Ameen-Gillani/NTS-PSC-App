import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_attachment_tile.dart';

void main() {
  testWidgets('tappable attachment renders inside a decorated review card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                border: Border.all(color: AppColors.grey300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const AssignmentAttachmentTile(
                attachment: AssignmentAttachmentModel(
                  name: 'Lesson notes.pdf',
                  sizeBytes: 1024,
                  path: 'course/lesson-notes.pdf',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Lesson notes.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

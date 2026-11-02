import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/assignments/data/assignment_draft_store.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';

void main() {
  const user = '11111111-1111-4111-8111-111111111111';
  const other = '22222222-2222-4222-8222-222222222222';
  const assignment = '33333333-3333-4333-8333-333333333333';
  late Directory root;
  late AssignmentDraftStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('assignment-draft-');
    store = AssignmentDraftStore(directory: () async => root);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test('text and attachment survive restart and stay account scoped', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    await store.write(
      user,
      assignment,
      AssignmentDraft('My response', [
        AssignmentAttachmentModel(
          name: 'answer.pdf',
          sizeBytes: bytes.length,
          bytes: bytes,
        ),
      ]),
    );
    final restored = await AssignmentDraftStore(
      directory: () async => root,
    ).read(user, assignment);
    expect(restored?.response, 'My response');
    expect(restored?.attachments.single.bytes, bytes);
    expect(await store.read(other, assignment), isNull);
    await store.clear(user, assignment);
    expect(await store.read(user, assignment), isNull);
  });
  test('malformed identifiers cannot escape app storage', () async {
    await expectLater(store.read('../other', assignment), throwsArgumentError);
  });
  test(
    'serialized changes leave the last response and remove old files',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await Future.wait([
        store.write(
          user,
          assignment,
          AssignmentDraft('First', [
            AssignmentAttachmentModel(
              name: 'file.txt',
              sizeBytes: 3,
              bytes: bytes,
            ),
          ]),
        ),
        store.write(user, assignment, const AssignmentDraft('Last', [])),
      ]);
      expect((await store.read(user, assignment))?.response, 'Last');
      final folder = Directory(
        '${root.path}/assignment-drafts/$user/$assignment',
      );
      expect((await folder.list().toList()).length, 1);
    },
  );
}

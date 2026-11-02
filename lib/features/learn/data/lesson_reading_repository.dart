import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_evidence_repository.dart';
import 'offline_reading_store.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';

typedef ReadingKey = ({String lessonId, String? materialId});
final savedLessonReadingProvider = FutureProvider.autoDispose
    .family<ReadingDocument, ReadingKey>((ref, key) async {
      final owner = ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      if (owner == null) throw StateError('Sign in to open saved readings.');
      return _savedReading(ref, key, owner);
    });

final lessonReadingProvider = FutureProvider.autoDispose
    .family<ReadingDocument, ReadingKey>(retry: (count, error) => null, (
      ref,
      key,
    ) async {
      ref.watch(authControllerProvider.select((s) => s.value?.user?.id));
      final client = Supabase.instance.client;
      final repository = ref.read(learningEvidenceRepositoryProvider);
      final owner = repository.user;
      if (owner == null) throw StateError('Sign in to read this lesson.');
      developer.log(
        'Opening reading: lesson=${key.lessonId}, '
        'material=${key.materialId ?? 'lesson-notes'}.',
        name: 'CBOA.Reading',
      );
      try {
        final outcome = await repository.outcome(key.lessonId);
        final items = (outcome['activities'] as List).cast<Map>();
        developer.log(
          'Learning outcome loaded with ${items.length} activities.',
          name: 'CBOA.Reading',
        );
        final activity = items
            .where(
              (a) => key.materialId == null
                  ? a['kind'] == 'reading'
                  : a['material_id'] == key.materialId,
            )
            .firstOrNull;
        if (activity == null) {
          throw StateError('This reading is no longer available.');
        }
        developer.log(
          'Matched activity ${activity['id']} (${activity['kind']}); '
          'prepared=${activity['preparation_required'] != true}.',
          name: 'CBOA.Reading',
        );
        Map<String, dynamic>? prepared;
        String text;
        if (key.materialId != null) {
          final response = await client.functions
              .invoke(
                'prepare-lesson-reading',
                body: {'materialId': key.materialId},
              )
              .timeout(LearningEvidenceRepository.requestTimeout);
          developer.log(
            'Reading preparation returned HTTP ${response.status}.',
            name: 'CBOA.Reading',
          );
          prepared = Map<String, dynamic>.from(response.data as Map);
          text = prepared['text'] as String? ?? '';
          developer.log(
            'Prepared material: pdf=${prepared['pdf'] == true}, '
            'units=${prepared['units']}, textChars=${text.length}, '
            'hasSignedSource=${(prepared['url'] as String?)?.isNotEmpty == true}.',
            name: 'CBOA.Reading',
          );
        } else {
          final row = await client
              .from('lessons')
              .select('notes')
              .eq('id', key.lessonId)
              .single();
          text = row['notes'] as String? ?? '';
        }
        var version = activity['version'] as String?;
        if (version == null) {
          final refreshed = await repository.outcome(key.lessonId);
          version =
              (refreshed['activities'] as List)
                      .cast<Map>()
                      .where((item) => item['id'] == activity['id'])
                      .firstOrNull?['version']
                  as String?;
        }
        if (repository.user != owner) throw StateError('Account changed.');
        final ticket = await repository.session(
          key.lessonId,
          activity['id'] as String,
          expectedVersion: version,
        );
        if (repository.user != owner) throw StateError('Account changed.');
        developer.log(
          'Reading session ready: activity=${ticket['activity_id']}, '
          'kind=${ticket['kind']}, units=${ticket['units']}.',
          name: 'CBOA.Reading',
        );
        return ReadingDocument(
          ticket: ticket,
          owner: owner,
          text: text,
          pdfUrl: prepared?['pdf'] == true ? prepared!['url'] as String : null,
        );
      } on SocketException catch (error, stackTrace) {
        _logReadingFallback(error, stackTrace);
        return _savedReading(ref, key, owner);
      } on TimeoutException catch (error, stackTrace) {
        _logReadingFallback(error, stackTrace);
        return _savedReading(ref, key, owner);
      } on ClientException catch (error, stackTrace) {
        _logReadingFallback(error, stackTrace);
        return _savedReading(ref, key, owner);
      } catch (error, stackTrace) {
        developer.log(
          'Reading setup failed before the viewer opened.',
          name: 'CBOA.Reading',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });

void _logReadingFallback(Object error, StackTrace stackTrace) {
  developer.log(
    'Online reading failed; checking the private offline copy.',
    name: 'CBOA.Reading',
    error: error,
    stackTrace: stackTrace,
  );
}

Future<ReadingDocument> _savedReading(
  Ref ref,
  ReadingKey key,
  String owner,
) async {
  final saved = await ref
      .read(offlineReadingStoreProvider)
      .read(owner: owner, lessonId: key.lessonId, materialId: key.materialId);
  if (saved == null) {
    developer.log(
      'No matching offline reading is available.',
      name: 'CBOA.Reading',
    );
    throw StateError('Reconnect to open this reading.');
  }
  developer.log(
    'Using saved reading: lesson=${key.lessonId}, '
    'material=${key.materialId ?? 'lesson-notes'}, '
    'hasPdf=${saved.pdfPath?.isNotEmpty == true}.',
    name: 'CBOA.Reading',
  );
  return ReadingDocument(
    ticket: saved.ticket,
    owner: owner,
    text: saved.text,
    pdfPath: saved.pdfPath,
    isOffline: true,
  );
}

class ReadingDocument {
  ReadingDocument({
    required this.ticket,
    required this.owner,
    required this.text,
    this.pdfUrl,
    this.pdfPath,
    this.isOffline = false,
  });
  final Map<String, dynamic> ticket;
  final String owner;
  final String text;
  final String? pdfUrl;
  final String? pdfPath;
  final bool isOffline;
  late final List<String> pages = _pages();
  List<String> _pages() {
    final words = text.trim().split(RegExp(r'\s+'));
    return [
      for (var i = 0; i < words.length; i += 80)
        words.skip(i).take(80).join(' '),
    ];
  }
}

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/utils/image_upload_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final courseCoverRepositoryProvider = Provider<CourseCoverRepository>(
  (ref) => CourseCoverRepository(Supabase.instance.client),
);

class CourseCoverRepository {
  CourseCoverRepository(this.client);
  final SupabaseClient client;
  static const maxBytes = ImageUploadValidator.maxBytes;

  static Future<String> validateImage(Uint8List bytes) =>
      ImageUploadValidator.validate(bytes);

  Future<String> upload(String courseId, Uint8List bytes) async {
    final mime = await validateImage(bytes);
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in again to upload a cover.');
    final current = await client
        .from('courses')
        .select('image_path, pending_image_path, status')
        .eq('id', courseId)
        .eq('instructor_id', userId)
        .single();
    final extension = mime == 'image/jpeg' ? 'jpg' : mime.split('/').last;
    final path = '$userId/$courseId/${const Uuid().v4()}.$extension';
    final bucket = client.storage.from('course-thumbnails');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mime),
    );
    // A timeout can happen after commit. Keep the new object for safe retry/recovery.
    final isPublished = current['status'] == 'published';
    await client
        .from('courses')
        .update({isPublished ? 'pending_image_path' : 'image_path': path})
        .eq('id', courseId)
        .eq('instructor_id', userId)
        .select('id')
        .single();
    final old = isPublished
        ? current['pending_image_path'] as String?
        : current['image_path'] as String?;
    if (old != null && old.startsWith('$userId/$courseId/')) {
      try {
        await bucket.remove([old]);
      } catch (_) {
        // The new cover is saved; unreferenced old artwork can be swept later.
      }
    }
    return bucket.getPublicUrl(path);
  }
}

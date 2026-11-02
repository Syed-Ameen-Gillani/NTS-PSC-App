import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/course_certificate_repository.dart';
import 'package:url_launcher/url_launcher.dart';

final certificateLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

final certificateOpenProvider = NotifierProvider.autoDispose
    .family<CertificateOpenController, bool, String>(
      CertificateOpenController.new,
    );

class CertificateOpenController extends Notifier<bool> {
  CertificateOpenController(this.courseId);
  final String courseId;
  @override
  bool build() => false;

  Future<void> open() async {
    if (state) return;
    final owner = ref.read(authControllerProvider).value?.user?.id;
    if (owner == null) throw StateError('Sign in required');
    state = true;
    try {
      // Refresh an expiring URL without replacing the page with a loading view.
      final certificate = await ref
          .read(courseCertificateRepositoryProvider)
          .prepare(courseId);
      if (!ref.mounted ||
          ref.read(authControllerProvider).value?.user?.id != owner) {
        throw StateError('Account changed');
      }
      if (!await ref.read(certificateLauncherProvider)(certificate.url)) {
        throw StateError('No PDF viewer');
      }
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

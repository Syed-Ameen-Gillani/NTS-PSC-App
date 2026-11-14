import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class VideoFullscreenScreen extends StatefulWidget {
  const VideoFullscreenScreen({super.key, required this.session});
  final VideoPlayerSession session;
  @override
  State<VideoFullscreenScreen> createState() => _VideoFullscreenScreenState();
}

/// A native decoder is recreated by the restored lesson beneath this route.
class RestoredInlineVideo extends StatefulWidget {
  const RestoredInlineVideo({super.key});

  @override
  State<RestoredInlineVideo> createState() => _RestoredInlineVideoState();
}

class _RestoredInlineVideoState extends State<RestoredInlineVideo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoute.main.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: AppColors.videoBackground);
}

class _VideoFullscreenScreenState extends State<VideoFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    VideoPlayerSession.enterFullscreen(widget.session.controller);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    VideoPlayerSession.leaveFullscreen(widget.session.controller);
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: AppColors.videoBackground,
    body: SafeArea(
      child: ProfessionalVideoPlayer(
        controller: widget.session.controller,
        title: widget.session.title,
        segments: widget.session.segments,
        fullscreen: true,
      ),
    ),
  );
}

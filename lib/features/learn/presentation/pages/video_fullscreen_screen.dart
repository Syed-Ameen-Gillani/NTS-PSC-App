import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class VideoFullscreenScreen extends StatefulWidget {
  const VideoFullscreenScreen({super.key, required this.session});
  final VideoPlayerSession session;
  @override
  State<VideoFullscreenScreen> createState() => _VideoFullscreenScreenState();
}

class _VideoFullscreenScreenState extends State<VideoFullscreenScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
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

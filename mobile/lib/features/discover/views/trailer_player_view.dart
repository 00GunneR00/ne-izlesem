import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_theme.dart';

/// Full-screen trailer playback, opened by explicit tap from the reels feed.
/// Kept isolated from any swipeable/scrollable ancestor so the embedded
/// WebView never competes with a PageView's drag gesture.
class TrailerPlayerView extends StatefulWidget {
  final String videoId;
  final String title;

  const TrailerPlayerView({super.key, required this.videoId, required this.title});

  @override
  State<TrailerPlayerView> createState() => _TrailerPlayerViewState();
}

class _TrailerPlayerViewState extends State<TrailerPlayerView> {
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: true,
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.primary,
        title: Text(widget.title, style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
      ),
      body: Center(
        child: YoutubePlayer(controller: _controller),
      ),
    );
  }
}

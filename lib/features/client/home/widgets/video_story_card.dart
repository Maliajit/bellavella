import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../models/story_model.dart';
import '../../../../core/router/route_names.dart';

class VideoStoryCard extends StatefulWidget {
  final Story story;
  final List<Story> totalStories;
  final int index;
  final double width;
  final double height;

  const VideoStoryCard({
    super.key,
    required this.story,
    required this.totalStories,
    required this.index,
    this.width = 180,
    this.height = 300,
  });

  @override
  State<VideoStoryCard> createState() => _VideoStoryCardState();
}

class _VideoStoryCardState extends State<VideoStoryCard> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.story.videoUrl));
    try {
      await _videoController.initialize();
      _videoController.setVolume(0.0);
      _videoController.setLooping(true);
      _videoController.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing preview: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'storyViewer',
          extra: {
            'stories': widget.totalStories,
            'initialIndex': widget.index,
          },
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              else if (widget.story.thumbnail != null)
                Image.network(widget.story.thumbnail!, fit: BoxFit.cover)
              else
                const Center(child: CircularProgressIndicator(color: Colors.white70)),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Title overlay
              if (widget.story.title != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    widget.story.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Pause Icon overlay (mimics preview vibe)
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white54,
                  size: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

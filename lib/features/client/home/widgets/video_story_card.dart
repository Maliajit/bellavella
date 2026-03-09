import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/story_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';

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
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializePlayer() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.story.videoUrl));
    
    try {
      await _videoController!.initialize();
      if (!mounted) return;
      
      _videoController!.setVolume(0.0);
      _videoController!.setLooping(true);
      _videoController!.play();
      
      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Error initializing preview: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _disposePlayer() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('story_card_${widget.index}_${widget.story.videoUrl}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.6) {
          _initializePlayer();
        } else if (visibilityInfo.visibleFraction == 0) {
          _disposePlayer();
        }
      },
      child: GestureDetector(
        onTap: () {
          context.pushNamed(
            AppRoutes.clientStoryViewerName,
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
                if (_isInitialized && _videoController != null)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                else if (widget.story.thumbnail != null)
                  AppNetworkImage(
                    url: widget.story.thumbnail,
                    fit: BoxFit.cover,
                  )
                else
                  const ColoredBox(color: Colors.black54),
                
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
  
                // Play Icon overlay
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
      ),
    );
  }
}

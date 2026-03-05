import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../models/story_model.dart';
import '../widgets/story_progress_bar.dart';
import '../../../../core/theme/app_theme.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  bool _isMuted = true;
  bool _isPaused = false;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeVideoPlayer(_currentIndex);
  }

  void _initializeVideoPlayer(int index) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.stories[index].videoUrl));
    
    await _videoController!.initialize();
    _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    _videoController!.play();
    _videoController!.addListener(_videoListener);
    
    if (mounted) setState(() {});
  }

  void _videoListener() {
    if (_videoController == null || !mounted) return;

    setState(() {
      _currentProgress = _videoController!.value.position.inMilliseconds /
          _videoController!.value.duration.inMilliseconds;
    });

    if (_videoController!.value.position >= _videoController!.value.duration) {
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          _videoController?.pause();
          setState(() => _isPaused = true);
        },
        onLongPressEnd: (_) {
          _videoController?.play();
          setState(() => _isPaused = false);
        },
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 100) {
            _previousStory(); // Swipe down
          } else if (details.primaryVelocity! < -100) {
            _nextStory(); // Swipe up
          }
        },
        child: Stack(
          children: [
            // Video Player
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _currentProgress = 0.0;
                });
                _initializeVideoPlayer(index);
              },
              itemBuilder: (context, index) {
                if (_currentIndex == index && _videoController != null && _videoController!.value.isInitialized) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),

            // Overlays
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars
                  StoryProgressBar(
                    totalSegments: widget.stories.length,
                    currentIndex: _currentIndex,
                    currentProgress: _currentProgress,
                  ),

                  // Top Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sound Control
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isMuted = !_isMuted;
                              _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
                            });
                          },
                        ),

                        // Close Button
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Metadata overlay (Title/Category)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.stories[_currentIndex].title != null)
                    Text(
                      widget.stories[_currentIndex].title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.stories[_currentIndex].serviceCategory != null)
                    Text(
                      widget.stories[_currentIndex].serviceCategory!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

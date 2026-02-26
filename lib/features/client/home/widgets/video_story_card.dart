import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoStoryCard extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double width;
  final double height;

  const VideoStoryCard({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.width = 180,
    this.height = 300,
  });

  @override
  State<VideoStoryCard> createState() => _VideoStoryCardState();
}

class _VideoStoryCardState extends State<VideoStoryCard> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _initializationError = null;
    });

    try {
      if (widget.videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        final assetPath = widget.videoUrl.startsWith('assets/')
            ? widget.videoUrl
            : 'assets/videos/${widget.videoUrl}';
        _videoController = VideoPlayerController.asset(assetPath);
      }

      await _videoController.initialize();
      _videoController.setVolume(0.0); // Ensure muted by default
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _videoController.value.aspectRatio,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorState(errorMessage);
        },
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      // On Web, sometimes asset() fails but networkUrl() with the relative path works
      if (!widget.videoUrl.startsWith('http')) {
        try {
          final relativePath = widget.videoUrl.startsWith('assets/')
              ? widget.videoUrl
              : 'assets/videos/${widget.videoUrl}';
          _videoController = VideoPlayerController.networkUrl(Uri.parse(relativePath));
          await _videoController.initialize();
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            aspectRatio: _videoController.value.aspectRatio,
            autoInitialize: true,
          );
          setState(() {
            _isInitialized = true;
          });
          return;
        } catch (e2) {
          debugPrint('Web Fallback also failed: $e2');
        }
      }
      
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 40),
            const SizedBox(height: 10),
            Text(
              'Playback Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            TextButton(
              onPressed: _initializePlayer,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: !_isInitialized && widget.thumbnailUrl != null
            ? DecorationImage(
                image: NetworkImage(widget.thumbnailUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (_isInitialized && _chewieController != null)
              Chewie(controller: _chewieController!)
            else if (_initializationError != null)
              _buildErrorState(_initializationError!)
            else
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Icon(
                _isInitialized && _videoController.value.isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../models/home_models.dart';

class HomeImageBanner extends StatefulWidget {
  final HomeBanner banner;
  final VoidCallback? onTap;
  final double height;

  const HomeImageBanner({
    super.key,
    required this.banner,
    this.onTap,
    this.height = 160,
  });

  @override
  State<HomeImageBanner> createState() => _HomeImageBannerState();
}

class _HomeImageBannerState extends State<HomeImageBanner> {
  VideoPlayerController? _controller;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomeImageBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.mediaUrl != widget.banner.mediaUrl ||
        oldWidget.banner.mediaType != widget.banner.mediaType) {
      _disposeController();
      _hasVideoError = false;
      _initializeVideoIfNeeded();
    }
  }

  Future<void> _initializeVideoIfNeeded() async {
    if (!widget.banner.isVideo || widget.banner.mediaUrl.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.banner.mediaUrl),
    );

    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize();
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _hasVideoError = true);
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = widget.banner.title.trim();
    final trimmedSubtitle = (widget.banner.subtitle ?? '').trim();
    final hasOverlayText = trimmedTitle.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMedia(),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Text overlay
              if (hasOverlayText)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trimmedTitle.isNotEmpty)
                        Text(
                          trimmedTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (trimmedSubtitle.isNotEmpty)
                        Text(
                          trimmedSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              if (widget.banner.isVideo)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final controller = _controller;
    if (widget.banner.isVideo &&
        !_hasVideoError &&
        controller != null &&
        controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    return AppNetworkImage(
      url: widget.banner.imageUrl.isNotEmpty
          ? widget.banner.imageUrl
          : widget.banner.mediaUrl,
      width: double.infinity,
      height: widget.height,
      fit: BoxFit.cover,
    );
  }
}

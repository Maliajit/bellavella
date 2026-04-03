import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../models/home_models.dart';

class HomeHeroBanner extends StatefulWidget {
  final List<HomeBanner> banners;
  final void Function(HomeBanner banner)? onBannerTap;
  const HomeHeroBanner({super.key, required this.banners, this.onBannerTap});

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  static const double _heroHeight = 150;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: _heroHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (!mounted) {
                return;
              }
              setState(() => _currentIndex = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final trimmedTitle = banner.title.trim();
              final trimmedSubtitle = banner.subtitle?.trim() ?? '';
              final hasOverlayText = trimmedTitle.isNotEmpty;
              return GestureDetector(
                onTap: () => widget.onBannerTap?.call(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _HeroBannerMedia(
                          banner: banner,
                          height: _heroHeight,
                          isActive: index == _currentIndex,
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.37),
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
                                Text(
                                  trimmedTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (trimmedSubtitle.isNotEmpty)
                                  Text(
                                    trimmedSubtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (banner.isVideo)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeroBannerMedia extends StatefulWidget {
  final HomeBanner banner;
  final double height;
  final bool isActive;

  const _HeroBannerMedia({
    required this.banner,
    required this.height,
    required this.isActive,
  });

  @override
  State<_HeroBannerMedia> createState() => _HeroBannerMediaState();
}

class _HeroBannerMediaState extends State<_HeroBannerMedia> {
  VideoPlayerController? _controller;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _HeroBannerMedia oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.banner.mediaUrl != widget.banner.mediaUrl ||
        oldWidget.banner.mediaType != widget.banner.mediaType) {
      _disposeController();
      _hasVideoError = false;
      _initializeVideoIfNeeded();
      return;
    }

    _syncPlayback();
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

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _controller = controller);
      _syncPlayback();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _hasVideoError = true);
      }
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
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

import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class ServiceFlowBannerCarousel extends StatefulWidget {
  final List<ContextBanner> banners;
  final double height;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final bool showOverlay;
  final bool compact;

  const ServiceFlowBannerCarousel({
    super.key,
    required this.banners,
    required this.height,
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.showOverlay = true,
    this.compact = false,
  });

  @override
  State<ServiceFlowBannerCarousel> createState() =>
      _ServiceFlowBannerCarouselState();
}

class _ServiceFlowBannerCarouselState extends State<ServiceFlowBannerCarousel> {
  static const Duration _imageSlideDuration = Duration(seconds: 4);

  late final PageController _controller;
  Timer? _imageTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleCurrentBanner();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServiceFlowBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners != widget.banners) {
      _currentIndex = 0;
      _scheduleCurrentBanner();
    }
  }

  void _scheduleCurrentBanner() {
    _imageTimer?.cancel();

    if (widget.banners.length <= 1 || _currentIndex >= widget.banners.length) {
      return;
    }

    final currentBanner = widget.banners[_currentIndex];
    if (currentBanner.isVideo) {
      return;
    }

    _imageTimer = Timer(_imageSlideDuration, _goToNextBanner);
  }

  void _goToNextBanner() {
    if (!mounted || widget.banners.length <= 1) {
      return;
    }

    final nextIndex = (_currentIndex + 1) % widget.banners.length;
    if (!_controller.hasClients) {
      setState(() => _currentIndex = nextIndex);
      _scheduleCurrentBanner();
      return;
    }

    _controller
        .animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        )
        .catchError((_) {});
  }

  void _handlePageChanged(int index) {
    if (!mounted) {
      return;
    }

    setState(() => _currentIndex = index);
    _scheduleCurrentBanner();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, index) => _BannerFrame(
                  banner: widget.banners[index],
                  showOverlay: widget.showOverlay,
                  compact: widget.compact,
                  isActive: index == _currentIndex,
                  onVideoComplete: () {
                    if (_currentIndex == index) {
                      _goToNextBanner();
                    }
                  },
                ),
              ),
            ),
          ),
          if (widget.banners.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerFrame extends StatelessWidget {
  final ContextBanner banner;
  final bool showOverlay;
  final bool compact;
  final bool isActive;
  final VoidCallback? onVideoComplete;

  const _BannerFrame({
    required this.banner,
    required this.showOverlay,
    required this.compact,
    required this.isActive,
    this.onVideoComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: banner.isVideo
              ? _VideoBannerPlayer(
                  banner: banner,
                  isActive: isActive,
                  onComplete: onVideoComplete,
                )
              : Image.network(
                  banner.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _BannerPlaceholder(compact: compact),
                ),
        ),
        if (showOverlay)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.68),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
        if (showOverlay)
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner.title.isNotEmpty)
                  Text(
                    banner.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 18 : 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if ((banner.subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle!.trim(),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: compact ? 12 : 14,
                      height: 1.35,
                    ),
                  ),
                ],
                if ((banner.buttonText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      banner.buttonText!.trim(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _VideoBannerPlayer extends StatefulWidget {
  final ContextBanner banner;
  final bool isActive;
  final VoidCallback? onComplete;

  const _VideoBannerPlayer({
    required this.banner,
    required this.isActive,
    this.onComplete,
  });

  @override
  State<_VideoBannerPlayer> createState() => _VideoBannerPlayerState();
}

class _VideoBannerPlayerState extends State<_VideoBannerPlayer> {
  VideoPlayerController? _controller;
  VoidCallback? _videoListener;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.banner.mediaUrl.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.banner.mediaUrl),
    );

    await controller.setLooping(false);
    await controller.setVolume(0);
    await controller.initialize();
    _attachVideoListener(controller);

    if (widget.isActive) {
      await controller.play();
    }

    if (!mounted) {
      _detachVideoListener(controller);
      await controller.dispose();
      return;
    }

    setState(() => _controller = controller);
  }

  @override
  void didUpdateWidget(covariant _VideoBannerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (widget.isActive && !oldWidget.isActive) {
      if (_completionSent) {
        _completionSent = false;
        unawaited(controller.seekTo(Duration.zero));
      }
      unawaited(controller.play());
    } else if (!widget.isActive && oldWidget.isActive) {
      unawaited(controller.pause());
    }
  }

  void _attachVideoListener(VideoPlayerController controller) {
    _videoListener = () {
      final value = controller.value;
      if (!value.isInitialized || !widget.isActive || _completionSent) {
        return;
      }

      final duration = value.duration;
      final position = value.position;
      if (duration == Duration.zero) {
        return;
      }

      if (position >= duration - const Duration(milliseconds: 250)) {
        _completionSent = true;
        widget.onComplete?.call();
      }
    };

    controller.addListener(_videoListener!);
  }

  void _detachVideoListener(VideoPlayerController? controller) {
    if (controller != null && _videoListener != null) {
      controller.removeListener(_videoListener!);
    }
    _videoListener = null;
  }

  @override
  void dispose() {
    _detachVideoListener(_controller);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if ((widget.banner.thumbnailUrl ?? '').isNotEmpty) {
        return Image.network(
          widget.banner.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _BannerPlaceholder(),
        );
      }
      return const _BannerPlaceholder();
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  final bool compact;

  const _BannerPlaceholder({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD6DE), Color(0xFFFFEEF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: compact ? 32 : 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A reusable network image widget with built-in:
/// - Skeleton loading placeholder (no layout jump)
/// - Local asset fallback on error
/// - Graceful null URL handling
///
/// Usage:
///   AppNetworkImage(url: imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover)
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = _buildImage();

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildImage() {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      // Skeleton shown while loading — no layout jump because size is constrained
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _skeleton();
      },
      // Local asset shown on error — UI stays stable
      errorBuilder: (context, error, stackTrace) {
        return _placeholder();
      },
    );
  }

  Widget _skeleton() {
    return SizedBox(
      width: width,
      height: height,
      child: const _ShimmerBox(),
    );
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/placeholder.png',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF0F0F0),
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Simple shimmer/skeleton box for loading state
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(_animation.value),
        ),
      ),
    );
  }
}

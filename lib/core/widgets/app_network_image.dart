import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// A reusable network image widget with built-in:
/// - Skeleton loading placeholder (no layout jump)
/// - Local asset fallback on error
/// - Graceful null URL handling
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
    final image = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
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
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _skeleton();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _skeleton();
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _skeleton() {
    return SizedBox(
      width: width,
      height: height,
      child: const SkeletonBox(),
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
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

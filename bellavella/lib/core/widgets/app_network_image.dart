import 'package:bellavella/core/widgets/skeleton_box.dart';
import 'package:bellavella/core/config/app_config.dart';
import 'package:bellavella/core/utils/media_url.dart';
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

  String _resolvedUrl() {
    if (url == null || url!.isEmpty) return '';
    var u = resolveMediaUrl(url);
    if (u.isEmpty) return '';
    
    // In local development, the backend might return URLs with its own local IP
    // like 192.168.1.x or 127.0.0.1 from the .env APP_URL. We need to replace
    // these with the AppConfig.origin to ensure the emulator/web app can reach them.
    if (u.startsWith('http')) {
      final uri = Uri.tryParse(u);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host.startsWith('192.168.') || uri.host == '10.0.2.2')) {
        final originUri = Uri.parse(AppConfig.origin);
        u = uri.replace(
          scheme: originUri.scheme,
          host: originUri.host,
          port: originUri.port,
        ).toString();
      }
    }
    
    return u;
  }

  Widget _buildImage() {
    final effectiveUrl = _resolvedUrl();
    if (effectiveUrl.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
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
        errorBuilder: (context, error, stackTrace) => Container(
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

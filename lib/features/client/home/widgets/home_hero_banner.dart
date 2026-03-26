import 'package:flutter/material.dart';
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
                        // Background image with fallback
                        AppNetworkImage(
                          url: banner.imageUrl,
                          width: double.infinity,
                          height: _heroHeight,
                          fit: BoxFit.cover,
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

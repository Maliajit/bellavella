import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/permission_handler_util.dart';
import '../../../core/utils/location_util.dart';
import '../../../core/utils/toast_util.dart';
import 'package:bellavella/features/client/home/controllers/home_provider.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import 'models/home_models.dart';
import 'models/story_model.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/active_booking_banner.dart';
import 'widgets/home_service_grid.dart';
import 'widgets/home_service_carousel.dart';
import 'widgets/home_image_banner.dart';
import 'widgets/home_story_section.dart';
import 'widgets/home_testimonials_section.dart';
import 'widgets/home_trending_packages_section.dart';
import 'widgets/home_download_app_section.dart';
import 'widgets/home_screen_skeleton.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late ConfettiController _confettiController;
  bool _hasPlayedLoadedConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await PermissionHandlerUtil.requestAllPermissions(context);

    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.showLoginSuccess();

    final homeProvider = context.read<HomeProvider>();
    if (LocationUtil.hasLocation()) {
      homeProvider.setLocation(
        LocationUtil.currentAddress!,
        LocationUtil.currentSubAddress!,
      );
    } else {
      homeProvider.determinePosition();
    }

    await homeProvider.fetchHomepageData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Navigates based on the target_page route key returned from backend.
  void _navigateToTarget(BuildContext context, String? targetPage) {
    if (targetPage == null || targetPage == 'none' || targetPage.isEmpty)
      return;

    final routes = {
      'home': '/home',
      'services': '/services',
      'packages': '/packages',
      'about': '/about',
      'contact': '/contact',
      'professionals': '/professionals',
      'offers': '/offers',
    };

    final route = routes[targetPage];
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final showInitialSkeleton =
        homeProvider.isLoading && homeProvider.sections.isEmpty;
    final shouldShowLoadedContent =
        !showInitialSkeleton && homeProvider.errorMessage == null;
    final categorySection = _findFirstSection(homeProvider.sections, (section) {
      return section.type == 'category_carousel';
    });
    final serviceSection = _findFirstSection(homeProvider.sections, (section) {
      return section.type == 'service_carousel' || section.type == 'service_grid';
    });
    final skeletonServiceCount = _normalizedSkeletonCount(
      categorySection?.items.length,
      fallback: 4,
    );
    final skeletonMostBookedCount = _normalizedSkeletonCount(
      serviceSection?.items.length,
      fallback: 2,
      max: 5,
    );

    if (shouldShowLoadedContent &&
        !_hasPlayedLoadedConfetti &&
        homeProvider.sections.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasPlayedLoadedConfetti) {
          return;
        }
        _confettiController.play();
        _hasPlayedLoadedConfetti = true;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: showInitialSkeleton
                ? HomeScreenSkeleton(
                    serviceCount: skeletonServiceCount,
                    mostBookedCount: skeletonMostBookedCount,
                  )
                : homeProvider.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          homeProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => homeProvider.fetchHomepageData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeHeader(
                          locationAddress: homeProvider.locationAddress,
                          locationSubAddress: homeProvider.locationSubAddress,
                          onLocationTap: () => homeProvider.determinePosition(),
                        ),
                        const SizedBox(height: 20),

                        // Dynamic sections from backend
                        ...homeProvider.sections.map((section) {
                          Widget sectionWidget = const SizedBox.shrink();

                          switch (section.type) {
                            case 'hero_banner':
                              final banners = section.items
                                  .map<HomeBanner>(
                                    (i) => HomeBanner.fromJson(
                                      i as Map<String, dynamic>,
                                    ),
                                  )
                                  .where((b) => b.imageUrl.isNotEmpty)
                                  .toList();
                              if (banners.isNotEmpty) {
                                sectionWidget = HomeHeroBanner(
                                  banners: banners,
                                  onBannerTap: (banner) => _navigateToTarget(
                                    context,
                                    banner.targetPage,
                                  ),
                                );
                              }
                              break;

                            case 'category_carousel':
                              final categories = section.items
                                  .map<HomeCategory>(
                                    (i) => HomeCategory.fromJson(
                                      i as Map<String, dynamic>,
                                    ),
                                  )
                                  .toList();
                              if (categories.isNotEmpty) {
                                sectionWidget = HomeServiceGrid(
                                  categories: categories,
                                  onViewAll: () {},
                                );
                              }
                              break;

                            case 'service_carousel':
                            case 'service_grid':
                              final services = section.items
                                  .map<HomeService>(
                                    (i) => HomeService.fromJson(
                                      i as Map<String, dynamic>,
                                    ),
                                  )
                                  .toList();
                              if (services.isNotEmpty) {
                                sectionWidget = HomeServiceCarousel(
                                  title: section.title,
                                  subtitle: section.subtitle ?? '',
                                  services: services,
                                  onAdd: (service) {
                                    context.read<CartProvider>().addItem(
                                      service,
                                      categoryName: section.title,
                                    );
                                    // Use global toast utility for Add to Cart message
                                    ToastUtil.showAddToCartToast(
                                      context,
                                      service.title,
                                    );
                                  },
                                );
                              }
                              break;

                            case 'video_stories':
                              final stories = section.items
                                  .map((i) {
                                    final map = i as Map<String, dynamic>;
                                    return Story(
                                      videoUrl: map['url'] ?? '',
                                      thumbnail: map['thumbnail'] ?? '',
                                      title: map['title'] ?? '',
                                      serviceCategory: map['subtitle'] ?? '',
                                    );
                                  })
                                  .where((s) => s.videoUrl.isNotEmpty)
                                  .toList();
                              if (stories.isNotEmpty) {
                                sectionWidget = HomeStorySection(
                                  stories: stories,
                                  title: section.title,
                                  subtitle:
                                      section.subtitle ??
                                      'Real lives, real impact',
                                );
                              }
                              break;

                            case 'image_banner':
                              if (section.items.isNotEmpty) {
                                final img =
                                    section.items.first as Map<String, dynamic>;
                                final banner = HomeBanner.fromJson(img);
                                if (banner.imageUrl.isNotEmpty) {
                                  sectionWidget = HomeImageBanner(
                                    title: banner.title.isNotEmpty
                                        ? banner.title
                                        : section.title,
                                    subtitle:
                                        banner.subtitle ??
                                        section.subtitle ??
                                        '',
                                    image: banner.imageUrl,
                                    onTap: () => _navigateToTarget(
                                      context,
                                      banner.targetPage,
                                    ),
                                  );
                                }
                              }
                              break;

                            case 'active_booking':
                              sectionWidget = const ActiveBookingBanner();
                              break;

                            case 'testimonials':
                              sectionWidget = HomeTestimonialsSection(
                                title: section.title,
                                subtitle: section.subtitle,
                                items: section.items,
                              );
                              break;

                            case 'trending_packages':
                              sectionWidget = HomeTrendingPackagesSection(
                                title: section.title,
                                subtitle: section.subtitle,
                                items: section.items,
                              );
                              break;

                            case 'download_app':
                              sectionWidget = HomeDownloadAppSection(
                                title: section.title,
                                subtitle: section.subtitle,
                                items: section.items,
                                btnText: section.btnText,
                                btnLink: section.btnLink,
                              );
                              break;
                          }

                          if (sectionWidget is SizedBox &&
                              sectionWidget.height == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: sectionWidget,
                          );
                        }),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
          if (shouldShowLoadedContent)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  AppTheme.primaryColor,
                ],
                createParticlePath: drawStar,
              ),
            ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  int _normalizedSkeletonCount(
    int? rawCount, {
    required int fallback,
    int min = 1,
    int max = 6,
  }) {
    final value = rawCount ?? fallback;
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  HomeSection? _findFirstSection(
    List<HomeSection> sections,
    bool Function(HomeSection section) matcher,
  ) {
    for (final section in sections) {
      if (matcher(section)) {
        return section;
      }
    }
    return null;
  }
}

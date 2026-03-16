import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/widgets/app_network_image.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/client/services/widgets/category_screen_skeleton.dart';

class ClientCategoryScreen extends StatefulWidget {
  final String categorySlug;
  const ClientCategoryScreen({super.key, required this.categorySlug});

  @override
  State<ClientCategoryScreen> createState() => _ClientCategoryScreenState();
}

class _ClientCategoryScreenState extends State<ClientCategoryScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSlider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchCategoryScreenData(widget.categorySlug);
    });
  }

  void _startAutoSlider() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final sp = context.read<ServiceProvider>();
        final bannersCount = sp.categoryPageData?.sliderBanners.length ?? 0;
        if (bannersCount > 1) {
          int nextPage = _bannerController.page!.toInt() + 1;
          if (nextPage >= bannersCount) nextPage = 0;
          _bannerController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/client/home'),
        ),
        title: const Text(
          'Category',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, sp, _) {
          if (sp.isLoading && sp.categoryPageData == null) {
            return const CategoryScreenSkeleton(
              categoryCount: 4,
              carouselCount: 2,
            );
          }
          if (sp.error != null) {
            return Center(child: Text('Error: ${sp.error}'));
          }
          final data = sp.categoryPageData;
          if (data == null) {
            return const Center(child: Text('No data found'));
          }

          return RefreshIndicator(
            onRefresh: () => sp.fetchCategoryScreenData(widget.categorySlug),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTagline(),
                  if (data.sliderBanners.isNotEmpty) _buildBannerSlider(data.sliderBanners),
                  
                  // Dynamic Sections
                  ...data.sections.map((section) => _buildSection(section)),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(CategorySection section) {
    switch (section.type) {
      case 'grid':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLookingFor(),
            _buildServiceTypesGrid(section.items.cast<CategoryMinimal>()),
            const SizedBox(height: 30),
          ],
        );
      case 'instagram':
        return Column(
          children: [
            _buildInstagramCategoryCard(context),
            const SizedBox(height: 30),
          ],
        );
      case 'carousel':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(section.title, section.subtitle ?? ''),
            _buildMostBookedServices(section.items.cast<DetailedService>()),
            const SizedBox(height: 30),
          ],
        );
      case 'horizontal_list':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(section.title, section.subtitle ?? ''),
            _buildHorizontalScroll(section.items.cast<DetailedService>()),
            const SizedBox(height: 30),
          ],
        );
      case 'banner':
        if (section.items.isNotEmpty) {
          return Column(
            children: [
              _buildSingleBanner(section.items.first as CategoryBanner),
              const SizedBox(height: 30),
            ],
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTagline() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        'Beauty & Wellness at your Convenience',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBannerSlider(List<CategoryBanner> banners) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: const AssetImage('assets/images/placeholder.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: banner.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(15),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (banner.subtitle != null)
                            Text(
                              banner.subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerPage == index ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLookingFor() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        'What are you looking for?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _buildServiceTypesGrid(List<CategoryMinimal> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.4,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          
          return InkWell(
            onTap: () {
              final node = cat.toHierarchyNode();
              context.pushNamed(
                AppRoutes.clientServiceHierarchyName,
                pathParameters: {'nodeKey': node.routeKey},
                extra: {
                  'seedNode': node.toRouteData(),
                  'breadcrumbs': const [],
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.slug.contains('salon') ? Icons.face_retouching_natural : 
                    cat.slug.contains('spa') ? Icons.spa : 
                    cat.slug.contains('hair') ? Icons.content_cut : 
                    Icons.auto_awesome, 
                    color: AppTheme.primaryColor, 
                    size: 30
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMostBookedServices(List<DetailedService> items) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final node = item.toHierarchyNode();
          return InkWell(
            onTap: () => context.pushNamed(
              AppRoutes.clientServiceHierarchyName,
              pathParameters: {'nodeKey': node.routeKey},
              extra: {
                'seedNode': node.toRouteData(),
                'breadcrumbs': const [],
              },
            ),
            child: Container(
              width: 185,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AppNetworkImage(
                      url: item.image,
                      height: 185,
                      width: 185,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.black, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${item.ratingAvg} (${item.reviewCount})',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalScroll(List<DetailedService> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final node = item.toHierarchyNode();
          return InkWell(
            onTap: () => context.pushNamed(
              AppRoutes.clientServiceHierarchyName,
              pathParameters: {'nodeKey': node.routeKey},
              extra: {
                'seedNode': node.toRouteData(),
                'breadcrumbs': const [],
              },
            ),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: item.image != null
                          ? AppNetworkImage(
                              url: item.image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(color: Colors.grey.shade200),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleBanner(CategoryBanner banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: banner.imageUrl,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(15),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (banner.subtitle != null)
                  Text(
                    banner.subtitle!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramCategoryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse('https://www.instagram.com/bellavella_salon');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF833AB4), // Purple
                Color(0xFFFD1D1D), // Red
                Color(0xFFFCB045), // Orange
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE1306C).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See Our Real Work ',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Follow us on Instagram',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Follow',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE1306C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

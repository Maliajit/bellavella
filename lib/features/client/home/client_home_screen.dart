import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/permission_handler_util.dart';
import '../../../core/utils/location_util.dart';

import 'controllers/home_provider.dart';
import 'models/story_model.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_banner.dart';
import 'widgets/active_booking_banner.dart';
import 'widgets/home_service_grid.dart';
import 'widgets/home_service_carousel.dart';
import 'widgets/home_image_banner.dart';
import 'widgets/home_story_section.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Request all necessary permissions
    await PermissionHandlerUtil.requestAllPermissions(context);
    
    // 2. Initialize and trigger test notification
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.showLoginSuccess();

    // 3. Handle location
    final homeProvider = context.read<HomeProvider>();
    if (LocationUtil.hasLocation()) {
      homeProvider.setLocation(
        LocationUtil.currentAddress!, 
        LocationUtil.currentSubAddress!
      );
    } else {
      homeProvider.determinePosition();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    // Prepare stories (mock mapping for now as per current code)
    final List<Story> stories = [
      Story(
        videoUrl: 'assets/videos/videoplayback.mp4',
        thumbnail: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=400',
        title: 'Professional Service',
        serviceCategory: 'Hair Styling',
      ),
      Story(
        videoUrl: 'assets/videos/video2.mp4',
        thumbnail: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400',
        title: 'Luxe Facial',
        serviceCategory: 'Skincare',
      ),
      Story(
        videoUrl: 'assets/videos/video3.mp4',
        thumbnail: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200',
        title: 'Deep Relaxation',
        serviceCategory: 'Massage',
      ),
      Story(
        videoUrl: 'assets/videos/video4.mp4',
        thumbnail: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
        title: 'Bridal Glow',
        serviceCategory: 'Makeup',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    locationAddress: homeProvider.locationAddress,
                    locationSubAddress: homeProvider.locationSubAddress,
                    onLocationTap: () => homeProvider.determinePosition(),
                  ),
                  const SizedBox(height: 20),
                  HomeHeroBanner(banners: homeProvider.banners),
                  const SizedBox(height: 25),
                  const ActiveBookingBanner(),
                  const SizedBox(height: 35),
                  HomeServiceGrid(
                    categories: homeProvider.categories,
                    onViewAll: () {},
                  ),
                  const SizedBox(height: 40),
                  HomeServiceCarousel(
                    title: 'Salon for Women',
                    subtitle: 'Pamper yourself at home',
                    services: homeProvider.womenSalonServices,
                  ),
                  const SizedBox(height: 40),
                  HomeStorySection(stories: stories),
                  const SizedBox(height: 40),
                  const HomeImageBanner(
                    image: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800',
                    title: 'Hygiene Excellence',
                    subtitle: '100% Sanitized kits & safe pros',
                  ),
                  const SizedBox(height: 40),
                  HomeServiceCarousel(
                    title: 'Luxe Massage Therapy',
                    subtitle: 'Relaxation delivered to your doorstep',
                    services: homeProvider.massageServices,
                  ),
                  const SizedBox(height: 40),
                  const HomeImageBanner(
                    image: 'https://img1.wsimg.com/isteam/ip/f7b4722a-c66d-44f3-a479-48c918429406/9A9193D1-219A-45AE-8D21-B2D0AFBF2EED.jpeg/:/cr=t:0%25,l:0%25,w:100%25,h:100%25/rs=w:814,cg:true',
                    title: 'Platinum Insider',
                    subtitle: 'Exclusive benefits for our elite members',
                  ),
                  const SizedBox(height: 40),
                  HomeServiceCarousel(
                    title: 'Advanced Skincare',
                    subtitle: 'Clinical results, spa comfort',
                    services: homeProvider.skincareServices,
                  ),
                  const SizedBox(height: 40),
                  const HomeImageBanner(
                    image: 'https://static.vecteezy.com/system/resources/previews/047/932/342/non_2x/minimalist-presentation-templates-corporate-booklet-use-in-flyer-and-leaflet-marketing-banner-advertising-brochure-annual-business-report-website-slider-white-blue-color-company-profile-vector.jpg',
                    title: 'Invite & Earn ₹500',
                    subtitle: 'Refer a friend and get luxe rewards',
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
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
      path.lineTo(halfWidth + externalRadius * math.cos(step),
          halfWidth + externalRadius * math.sin(step));
      path.lineTo(halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

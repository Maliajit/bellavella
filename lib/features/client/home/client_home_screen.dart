import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/mock_data/mock_data.dart';
import '../../../core/utils/location_util.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/video_story_card.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/permission_handler_util.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late ConfettiController _confettiController;
  
  String _locationAddress = 'Fetching location...';
  String _locationSubAddress = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _banners = [
    {
      'title': 'Perfect Combo',
      'subtitle': 'Haircut & Makeup - ₹1500',
      'image':
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=800',
    },
    {
      'title': 'New Season Sale',
      'subtitle': 'Flat 30% Off on Facials',
      'image':
          'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=800',
    },
    {
      'title': 'Bridal Special',
      'subtitle': 'Book now for Exclusive Glow',
      'image':
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?q=80&w=800',
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Request all necessary permissions (Notifications, Location, etc.)
    await PermissionHandlerUtil.requestAllPermissions(context);
    
    // 2. Initialize and trigger test notification
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.showLoginSuccess();

    // 3. Handle location prioritization
    if (LocationUtil.hasLocation()) {
      if (mounted) {
        setState(() {
          _locationAddress = LocationUtil.currentAddress!;
          _locationSubAddress = LocationUtil.currentSubAddress!;
        });
      }
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            String? mainLoc = place.subLocality;
            if (mainLoc == null || mainLoc.isEmpty || mainLoc == place.locality) {
              mainLoc = place.thoroughfare;
            }
            if (mainLoc == null || mainLoc.isEmpty) {
              mainLoc = place.name;
            }
            _locationAddress = mainLoc ?? place.locality ?? 'Unknown';
            _locationSubAddress = place.locality ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() {
        _locationAddress = 'Set location';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNewHeader(context),
                  const SizedBox(height: 20),
                  _buildHeroBanner(context),
                  const SizedBox(height: 25),
                  _buildActiveBookingBanner(context),
                  const SizedBox(height: 35),
                  _buildServicesSection(context),
                  const SizedBox(height: 40),
                  _buildServiceCarousel(
                    context,
                    title: 'Salon for Women',
                    subtitle: 'Pamper yourself at home',
                    services: _womenSalonServices,
                  ),
                  const SizedBox(height: 40),
                  _buildCelebratingProfessionals(context),
                  const SizedBox(height: 40),
                  _buildImageBanner(
                    context,
                    image: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800',
                    title: 'Hygiene Excellence',
                    subtitle: '100% Sanitized kits & safe pros',
                  ),
                  const SizedBox(height: 40),
                  _buildServiceCarousel(
                    context,
                    title: 'Luxe Massage Therapy',
                    subtitle: 'Relaxation delivered to your doorstep',
                    services: _massageServices,
                  ),
                  const SizedBox(height: 40),
                  _buildImageBanner(
                    context,
                    image: 'https://img1.wsimg.com/isteam/ip/f7b4722a-c66d-44f3-a479-48c918429406/9A9193D1-219A-45AE-8D21-B2D0AFBF2EED.jpeg/:/cr=t:0%25,l:0%25,w:100%25,h:100%25/rs=w:814,cg:true',
                    title: 'Platinum Insider',
                    subtitle: 'Exclusive benefits for our elite members',
                  ),
                  const SizedBox(height: 40),
                  _buildServiceCarousel(
                    context,
                    title: 'Advanced Skincare',
                    subtitle: 'Clinical results, spa comfort',
                    services: _skincareServices,
                  ),
                  const SizedBox(height: 40),
                  _buildImageBanner(
                    context,
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

  /// A custom Path to paint stars for the confetti
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

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
      path.lineTo(halfWidth + externalRadius * Math.cos(step),
          halfWidth + externalRadius * Math.sin(step));
      path.lineTo(halfWidth + internalRadius * Math.cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * Math.sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  Widget _buildNewHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _getGreeting(),
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationAddress,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _locationSubAddress.isEmpty ? 'Tap to change' : _locationSubAddress,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Wallet Balance Chip
            GestureDetector(
              onTap: () => context.push('/client/wallet'),
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '1,250',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cart Button
            Container(
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 22),
                  onPressed: () => context.push('/client/cart'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Typeable Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for 'Home Salon'",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (value) {
                // Future: Handle search navigation
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(banner['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        banner['subtitle']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildActiveBookingBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.push('/client/booking-status'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 55,
                    height: 55,
                    child: CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      backgroundColor: Color(0xFFFCE4EC),
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200',
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Tracker 📍',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Elena is 1.2km away',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '4 min',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final categories = [
      {'name': 'Waxing', 'image': 'https://thumbs.dreamstime.com/b/arm-waxing-beauty-salon-216809376.jpg', 'badge': ''},
      {'name': 'Signature...', 'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200', 'badge': 'New'},
      {'name': 'Facial', 'image': 'https://thumbs.dreamstime.com/b/beautiful-smiling-woman-healthy-smooth-facial-clean-skin-applying-cosmetic-cream-touch-own-face-model-beauty-face-169183142.jpg', 'badge': ''},
      {'name': 'Cleanup', 'image': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?q=80&w=200', 'badge': ''},
      {'name': 'Pedicure', 'image': 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=200', 'badge': ''},
      {'name': 'Threadi...', 'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=200', 'badge': ''},
      {'name': 'Spa Ca...', 'image': 'https://www.shutterstock.com/image-photo/beautiful-young-happy-woman-getting-260nw-2692322845.jpg', 'badge': ''},
      {'name': 'Super S...', 'image': 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?q=80&w=200', 'badge': 'Off'},
      {'name': 'Bridle', 'image': 'https://images.unsplash.com/photo-1594473728867-05ac7ad836d1?q=80&w=400', 'badge': 'Spec'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(cat['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              cat['name']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (cat['badge'] != '')
                          Positioned(
                            top: 8,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cat['badge'] == 'New'
                                    ? const Color(0xFFE91E63)
                                    : const Color(0xFFFF9800),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                cat['badge']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _womenSalonServices = [
    {
      'title': 'Threading',
      'rating': '4.91',
      'reviews': '346K',
      'price': '99',
      'options': '8 options',
      'image': 'https://images.unsplash.com/photo-1519415387722-a1c3bbef716c?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'Full arms & underarms waxing',
      'rating': '4.90',
      'reviews': '133K',
      'price': '599',
      'options': '6 options',
      'image': 'https://cdn.prod.website-files.com/6680826684515a60a2de75f2/66a2853a54f27d4192e28f08_under-arm.webp',
    },
    {
      'title': 'Face & neck de-tan',
      'rating': '4.85',
      'reviews': '89K',
      'price': '249',
      'options': '4 options',
      'image': 'https://lotus-professional.com/cdn/shop/files/face-detan.webp?v=1664367570',
    },
  ];

  final List<Map<String, String>> _massageServices = [
    {
      'title': 'Stress Relief Body Massage',
      'rating': '4.95',
      'reviews': '52K',
      'price': '1,299',
      'options': '3 options',
      'image': 'https://www.shutterstock.com/image-photo/woman-enjoying-professional-body-massage-260nw-2301687789.jpg',
    },
    {
      'title': 'Deep Tissue Therapy',
      'rating': '4.92',
      'reviews': '28K',
      'price': '1,599',
      'options': '2 options',
      'image': 'https://spameraki.com/cdn/shop/products/WebsitePics_27.png?v=1623620680',
    },
  ];

  final List<Map<String, String>> _skincareServices = [
    {
      'title': 'Bridal Glow Facial',
      'rating': '4.98',
      'reviews': '12K',
      'price': '2,499',
      'options': '1 option',
      'image': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=400',
    },
    {
      'title': 'Vitamin C Brightening',
      'rating': '4.89',
      'reviews': '45K',
      'price': '1,899',
      'options': '2 options',
      'image': 'https://images.unsplash.com/photo-1552693673-1bf958298935?q=80&w=400',
    },
  ];

  Widget _buildServiceCarousel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Map<String, String>> services,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF673AB7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            service['image']!,
                            height: 180,
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6BE5C),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Luxe',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service['title']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${service['rating']} (${service['reviews']})',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Starts at',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            Text(
                              '₹${service['price']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  color: Color(0xFF673AB7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              service['options']!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageBanner(
    BuildContext context, {
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebratingProfessionals(BuildContext context) {
    final stories = [
      {
        'video': 'assets/videos/videoplayback.mp4',
        'thumbnail': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=400',
      },
      {
        'video': 'assets/videos/video2.mp4',
        'thumbnail': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400',
      },
      {
        'video': 'assets/videos/video3.mp4',
        'thumbnail': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200',
      },
      {
        'video': 'assets/videos/video4.mp4',
        'thumbnail': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Real lives, real impact',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return VideoStoryCard(
                videoUrl: story['video']!,
                thumbnailUrl: story['thumbnail'],
              );
            },
          ),
        ),
      ],
    );
  }

}

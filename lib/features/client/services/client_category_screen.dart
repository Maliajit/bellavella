import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientCategoryScreen extends StatefulWidget {
  final String categoryName;
  const ClientCategoryScreen({super.key, required this.categoryName});

  @override
  State<ClientCategoryScreen> createState() => _ClientCategoryScreenState();
}

class _ClientCategoryScreenState extends State<ClientCategoryScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;

  final List<Map<String, String>> _banners = [
    {
      'title': 'Salon for Women',
      'subtitle': 'Upto 50% Off on Hair Services',
      'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=800',
    },
    {
      'title': 'Luxury Spa',
      'subtitle': 'Relax and Rejuvenate',
      'image': 'https://static.vecteezy.com/system/resources/previews/046/122/700/non_2x/elegant-spa-setting-with-lit-candles-flowers-towels-smooth-stones-calming-wellness-retreat-for-relaxation-concept-of-luxury-thai-spa-tranquility-self-care-indulgence-banner-space-for-text-photo.jpeg',
    },
  ];

  @override
  void dispose() {
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
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTagline(),
            _buildBannerSlider(),
            _buildLookingFor(),
            _buildServiceTypesGrid(),
            const SizedBox(height: 30),
            _buildInstagramCategoryCard(context), // Option D
            const SizedBox(height: 30),
            _buildSectionHeader('Most Booked Services', 'Aesthetic and reliable'),
            _buildMostBookedServices(_bookedServices),
            const SizedBox(height: 30),
            _buildSectionHeader('Salon for Women', 'Pamper yourself at home'),
            _buildHorizontalScroll(_salonCategories),
            const SizedBox(height: 20),
            _buildSingleBanner(
              'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
              'Special Offer',
              'Flat ₹200 off',
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('Spa for Women', 'Stress and pain relief'),
            _buildHorizontalScroll(_spaCategories),
            const SizedBox(height: 20),
            _buildSingleBanner(
              'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
              'Spa Bliss',
              'Book now',
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('Hair Studio for Women', 'Trendiest styles'),
            _buildHorizontalScroll(_hairCategories),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return const Padding(
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

  Widget _buildBannerSlider() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerPage = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: NetworkImage(banner['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(15),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['title']!,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        banner['subtitle']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
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

  Widget _buildServiceTypesGrid() {
    final types = [
      {'name': 'Salon for\nwomen', 'icon': Icons.face_retouching_natural},
      {'name': 'Spa for\nwomen', 'icon': Icons.spa},
      {'name': 'Hair Studio\nfor women', 'icon': Icons.content_cut},
      {'name': 'Bridle', 'icon': Icons.auto_awesome},
    ];

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
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final typeName = (type['name'] as String).replaceAll('\n', ' ');
          
          return InkWell(
            onTap: () {
              if (typeName.toLowerCase().contains('hair')) {
                context.push('/client/category-detail/$typeName');
              } else {
                context.push('/client/service-types/$typeName');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type['icon'] as IconData, color: AppTheme.primaryColor, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    type['name'] as String,
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

  Widget _buildMostBookedServices(List<Map<String, String>> items) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.push('/client/category-detail/${item['title']}'),
            child: Container(
              width: 185,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      item['image']!,
                      height: 185,
                      width: 185,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title']!,
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
                        '${item['rating'] ?? '4.8'} (${item['reviews'] ?? '100'})',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item['price'] ?? '499'}',
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

  Widget _buildHorizontalScroll(List<Map<String, String>> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.push('/client/category-detail/${item['title']}'),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        item['image']!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item['title']!,
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

  Widget _buildSingleBanner(String imageUrl, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Mock data for internal screen
  final List<Map<String, String>> _bookedServices = [
    {'title': 'Classic Manicure', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400', 'price': '499'},
    {'title': 'Hydra Facial', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400', 'price': '1299'},
    {'title': 'Hair Spa', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400', 'price': '899'},
    {'title': 'Waxing Combo', 'image': 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?q=80&w=400', 'price': '799'},
    {'title': 'Pedicure Deluxe', 'image': 'https://images.unsplash.com/photo-1519415387722-a1c3bbef716c?q=80&w=400', 'price': '699'},
  ];

  final List<Map<String, String>> _salonCategories = [
    {'title': 'Waxing', 'image': 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?q=80&w=400'},
    {'title': 'Cleanup', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'},
    {'title': 'Facial', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'},
    {'title': 'Manicure', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'},
    {'title': 'Pedicure', 'image': 'https://images.unsplash.com/photo-1519415387722-a1c3bbef716c?q=80&w=400'},
    {'title': 'Threading', 'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400'},
    {'title': 'Bleach', 'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=400'},
  ];

  final List<Map<String, String>> _spaCategories = [
    {'title': 'Stress Relief', 'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'},
    {'title': 'Pain Relief', 'image': 'https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?q=80&w=400'},
  ];

  final List<Map<String, String>> _hairCategories = [
    {'title': 'Haircut', 'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=400'},
    {'title': 'Hair Spa', 'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400'},
  ];

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
                color: const Color(0xFFE1306C).withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.9),
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

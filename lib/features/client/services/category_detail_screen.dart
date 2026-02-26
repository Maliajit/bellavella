import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  final List<Map<String, dynamic>> subCategories = [
    {
      'name': 'Waxing',
      'image':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'services': [
        {
          'name': 'Full Body Waxing',
          'price': '1200',
          'desc': 'Complete body waxing for a smooth skin.',
        },
        {'name': 'Arm Waxing', 'price': '400', 'desc': 'Full arms waxing.'},
      ],
    },
    {
      'name': 'Signature facial',
      'image':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'services': [
        {
          'name': 'Glow Signature Facial',
          'price': '1500',
          'desc': 'Our special glow facial.',
        },
      ],
    },
    {
      'name': 'Korean facial',
      'image':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'badge': 'New',
      'heroImage':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'heroTitle': 'Lost the glow?\nRestore it.',
      'heroSubtitle': 'Bio peptides\nNormal to oily skin',
      'services': [
        {
          'name': 'Korean Glass skin facial',
          'price': '2099',
          'image':
              'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          'desc': 'Get the glow you deserve.',
        },
        {
          'name': 'KGlow age-rewind facial',
          'price': '1899',
          'image':
              'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          'desc': 'Firming skin, youth restored.',
        },
        {
          'name': 'Korean Sea-algae Hydra-boost facial',
          'price': '2099',
          'image':
              'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          'desc': 'Intensive hydration.',
        },
      ],
    },
    {
      'name': 'Cleanup',
      'image':
          'https://images.unsplash.com/photo-1616394584738-fc6e612e71b9?q=80&w=100',
      'services': [
        {
          'name': 'Deep Cleanup',
          'price': '600',
          'desc': 'Removing dirt and impurities.',
        },
      ],
    },
    {
      'name': 'Pedicure & manicure',
      'image':
          'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?q=80&w=100',
      'services': [
        {
          'name': 'Spa Pedicure',
          'price': '800',
          'desc': 'Relaxing pedicure with spa treatment.',
        },
      ],
    },
    {
      'name': 'Threading & face wax',
      'image':
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=100',
      'services': [
        {
          'name': 'Eyebrow Threading',
          'price': '50',
          'desc': 'Perfect shape for your brows.',
        },
      ],
    },
    {
      'name': 'Bleach, detan & massage',
      'image':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'services': [
        {
          'name': 'Fruit Bleach',
          'price': '300',
          'desc': 'Natural skin lightening.',
        },
      ],
    },
    {
      'name': 'Super saver packages',
      'image':
          'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      'badge': 'off',
      'services': [
        {
          'name': 'Combo Package 1',
          'price': '2500',
          'desc': 'Waxing + Facial + Cleanup',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var cat in subCategories) {
      _sectionKeys[cat['name']] = GlobalKey();
    }
  }

  void _scrollToSection(String sectionName) {
    final key = _sectionKeys[sectionName];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Salon - ${widget.categoryName}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20),
                _buildSubCategoryGrid(),
                const SizedBox(height: 30),
                // _buildLogoSection(),
                // const SizedBox(height: 20),
                _buildOfferCard(),
                const SizedBox(height: 40),
                ...subCategories
                    .map((cat) => _buildServiceSection(cat))
                    .toList(),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildViewCartButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=600',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfect Combo',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Haircut & Makeup - ₹1500',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final subCat = subCategories[index];
          return InkWell(
            onTap: () => _scrollToSection(subCat['name']!),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(subCat['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (subCat.containsKey('badge'))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: subCat['badge'] == 'New'
                                ? AppTheme.primaryColor
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            subCat['badge']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subCat['name']!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildLogoSection() {
  //   return Column(
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Icon(Icons.spa_outlined, color: AppTheme.primaryColor, size: 24),
  //           const SizedBox(width: 8),
  //           Text(
  //             'BELLA VELLA',
  //             style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         'test',
  //         style: TextStyle(color: Colors.grey[400], fontSize: 12),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildOfferCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7E98),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '25% off upto 200 on Salon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Amazon cash',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '20% OFF',
              style: TextStyle(
                color: Color(0xFFFF7E98),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSubCategory(String name) {
    name = name.toLowerCase();
    if (name.contains('wax')) return Icons.auto_fix_high;
    if (name.contains('facial')) return Icons.face_retouching_natural;
    if (name.contains('cleanup')) return Icons.clean_hands;
    if (name.contains('mani') || name.contains('pedi')) return Icons.spa;
    if (name.contains('thread')) return Icons.content_cut;
    if (name.contains('bleach')) return Icons.shutter_speed;
    if (name.contains('package')) return Icons.card_giftcard;
    return Icons.star_outline;
  }

  Widget _buildServiceSection(Map<String, dynamic> cat) {
    return Column(
      key: _sectionKeys[cat['name']],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: AppTheme.primaryColor, width: 4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIconForSubCategory(cat['name']!),
                color: AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat['name']!,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (cat.containsKey('heroImage')) _buildSubCatHero(cat),
        const SizedBox(height: 10),
        ...(cat['services'] as List)
            .map((service) => _buildServiceItem(service as Map<String, String>))
            .toList(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSubCatHero(Map<String, dynamic> cat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.network(
                cat['heroImage']!,
                fit: BoxFit.cover,
                width: 180,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cat['heroTitle']!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  cat['heroSubtitle']!.split('\n')[0],
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  cat['heroSubtitle']!.split('\n')[1],
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, String> service) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  service['name']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Starts at ₹${service['price']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        minimumSize: const Size(80, 40),
                      ),
                      child: const Text('Add'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => _showServiceDetails(context, service),
                      child: const Text(
                        'View details',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (service.containsKey('image')) ...[
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                service['image']!,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewCartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/client/cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
        label: const Text(
          'View Cart',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  void _showServiceDetails(BuildContext context, Map<String, String> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service.containsKey('image'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                service['image']!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  service['name']!,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFB6C1,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  '₹${service['price']}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Category: ${widget.categoryName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '60 - 90 mins',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Service Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            service['desc'] ??
                                'Professional service using premium products and techniques. Our trained experts ensure you get the best experience with guaranteed results.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'How It Works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStepItem(
                            1,
                            'Book Service',
                            'Select your preferred date and time slot',
                          ),
                          _buildStepItem(
                            2,
                            'Expert Arrival',
                            'Trained professional arrives at your location',
                          ),
                          _buildStepItem(
                            3,
                            'Consultation',
                            'Quick skin/hair analysis and expert consultation',
                          ),
                          _buildStepItem(
                            4,
                            'Service Delivery',
                            'Relax and enjoy the premium service',
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'What\'s Included',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInclusionItem('Premium professional products'),
                          _buildInclusionItem('Disposable kits for hygiene'),
                          _buildInclusionItem('Post-service cleanup'),
                          _buildInclusionItem('Expert recommendations'),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildModalFooter(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepItem(int step, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB6C1),
              shape: BoxShape.circle,
            ),
            child: Text(
              step.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Add to Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

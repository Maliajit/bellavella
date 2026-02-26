import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class ProfessionalKitStoreScreen extends StatefulWidget {
  const ProfessionalKitStoreScreen({super.key});

  @override
  State<ProfessionalKitStoreScreen> createState() => _ProfessionalKitStoreScreenState();
}

class _ProfessionalKitStoreScreenState extends State<ProfessionalKitStoreScreen> {
  int _currentKits = 3; // Mock inventory
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Salon', 'Bridal', 'Hair', 'Waxing'];

  final List<Map<String, dynamic>> _kits = [
    {
      'id': '1',
      'name': 'Glow Signature Kit',
      'category': 'Salon',
      'price': 499,
      'description': 'Essential serums and masks for our signature glow facial.',
      'image': 'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop',
      'icon': '✨',
    },
    {
      'id': '2',
      'name': 'Bridal Excellence Kit',
      'category': 'Bridal',
      'price': 1299,
      'description': 'High-definition makeup and long-stay foundations.',
      'image': 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=600',
      'icon': '👰',
    },
    {
      'id': '3',
      'name': 'Eco-Waxing Essentials',
      'category': 'Waxing',
      'price': 299,
      'description': 'Organic honey wax and biodegradable strips.',
      'image': 'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop',
      'icon': '🍯',
    },
    {
      'id': '4',
      'name': 'Hydra-Hair Spa Kit',
      'category': 'Hair',
      'price': 399,
      'description': 'Deep conditioning serums and steam caps.',
      'image': 'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop',
      'icon': '💆',
    },
    {
      'id': '5',
      'name': 'Korean Glass Skin Kit',
      'category': 'Salon',
      'price': 899,
      'description': 'Premium bio-peptides for restored skin glow.',
      'image': 'https://plus.unsplash.com/premium_photo-1661340702301-53a479f3781f?q=80&w=1486&auto=format&fit=crop',
      'icon': '💎',
    },
  ];

  List<Map<String, dynamic>> get _filteredKits => _selectedCategory == 'All'
      ? _kits
      : _kits.where((k) => k['category'] == _selectedCategory).toList();

  void _buyKit(Map<String, dynamic> kit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Purchase Kit?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('₹${kit['price']} will be deducted from your earnings for the "${kit['name']}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentKits++);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kit Order placed! Your inventory updated to $_currentKits.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildInventoryHero()),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildKitItem(_filteredKits[index]),
                childCount: _filteredKits.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Text('Official Kit Store', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      centerTitle: false,
    );
  }

  Widget _buildInventoryHero() {
    final isMet = _currentKits >= 5;
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isMet ? [Colors.green.shade600, Colors.green.shade400] : [AppTheme.primaryColor, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: (isMet ? Colors.green : Colors.pink).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.inventory_2, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('YOUR INVENTORY', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$_currentKits Official Kits', style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isMet ? Icons.check_circle : Icons.warning_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isMet ? 'Eligible for Go-Live' : 'Need ${5 - _currentKits} more to Go-Live',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
              ),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildKitItem(Map<String, dynamic> kit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(kit['image'], width: 100, height: 100, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(kit['icon'], style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kit['category'].toUpperCase(), style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    Text('₹${kit['price']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(kit['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(kit['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _buyKit(kit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('PURCHASE KIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

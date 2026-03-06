import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart';

class ProfessionalKitStoreScreen extends StatefulWidget {
  const ProfessionalKitStoreScreen({super.key});

  @override
  State<ProfessionalKitStoreScreen> createState() => _ProfessionalKitStoreScreenState();
}

class _ProfessionalKitStoreScreenState extends State<ProfessionalKitStoreScreen> {
  int _currentKits = 0;
  String _selectedCategory = 'All';
  List<KitProductModel> _kits = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<String> get _categories {
    final cats = _kits.map((k) => k.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _fetchKits();
  }

  Future<void> _fetchKits() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await ProfessionalApiService.getKitProducts();
      final stats = await ProfessionalApiService.getDashboardStats();
      
      if (!mounted) return;
      setState(() {
        _kits = products.map((p) => KitProductModel.fromJson(p)).toList();
        _currentKits = stats.kitCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching kits: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<KitProductModel> get _filteredKits => _selectedCategory == 'All'
      ? _kits
      : _kits.where((k) => k.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchKits,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildInventoryHero()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchKits,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_kits.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No kits available at the moment.')),
              )
            else ...[
              SliverToBoxAdapter(child: _buildCategoryFilter()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildKitCard(_filteredKits[index]),
                    childCount: _filteredKits.length,
                  ),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Text(
        'Kit Store',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.black),
      ),
    );
  }

  Widget _buildInventoryHero() {
    final bool isMet = _currentKits >= 5;
    return Container(
      margin: const EdgeInsets.all(20),
      height: 180,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                  Colors.deepPurple.shade400,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.shopping_bag, size: 150, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PERSONAL INVENTORY',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_currentKits Kits',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(isMet ? Icons.verified : Icons.info_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isMet ? 'Operational' : 'Need ${5 - _currentKits} more',
                      style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _categories;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('CATEGORIES', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1)),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final bool isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitCard(KitProductModel kit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 140, // Horizontal fixed height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Image Left
          SizedBox(
            width: 130,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  child: Image.network(kit.image, height: double.infinity, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  ),
                ),
                if (kit.isPremium == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                      child: Text('PRO', style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
          ),
          // Content Right
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(kit.name, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('₹${kit.price.toInt()}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text((kit.category ?? 'General').toUpperCase(), style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(kit.icon ?? '📦', style: const TextStyle(fontSize: 14)),
                      ),
                      SizedBox(
                        height: 36,
                        width: 100, // Fixed width to prevent "infinite width" error in Row
                        child: ElevatedButton(
                          onPressed: (kit.stock > 0) == true ? () => _buyKit(kit) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text((kit.stock > 0) == true ? 'BUY' : 'SOLD', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _buyKit(KitProductModel kit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: 380,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            Text('Confirm Order', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text('This kit will be delivered to your registered address and ₹${kit.price.toInt()} will be deducted from your earnings.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade600, height: 1.5, fontSize: 14)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext); // pop immediately before async
                  try {
                    final res = await ProfessionalApiService.placeKitOrder(kit.id, 1);
                    if (!mounted) return;
                    if (res['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order Placed Successfully!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black,
                        ),
                      );
                      _fetchKits();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('CONFIRM PURCHASE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

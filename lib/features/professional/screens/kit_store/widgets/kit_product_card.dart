import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/professional_models.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class KitProductCard extends StatelessWidget {
  final KitProductModel kit;
  final VoidCallback onBuy;
  final VoidCallback? onViewDetails;

  const KitProductCard({
    super.key,
    required this.kit,
    required this.onBuy,
    this.onViewDetails,
  });

  String get _badge {
    if (kit.stock == 0) return 'OUT OF STOCK';
    if (kit.stock <= 5) return 'LOW STOCK';
    if (kit.isPremium == true) return 'BESTSELLER';
    return 'NEW';
  }

  Color get _badgeColor {
    if (kit.stock == 0) return const Color(0xFFEF4444);
    if (kit.stock <= 5) return const Color(0xFFF59E0B);
    if (kit.isPremium == true) return const Color(0xFF8B5CF6);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final bool inStock = kit.stock > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        kit.image,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('💼', style: TextStyle(fontSize: 36)),
                          ),
                        ),
                      ),
                    ),
                    // PRO badge
                    if (kit.isPremium == true)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge + Category row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _badge,
                              style: GoogleFonts.poppins(
                                color: _badgeColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            (kit.category ?? 'General').toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Kit name
                      Text(
                        kit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      if (kit.description.isNotEmpty)
                        Text(
                          kit.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Price + Actions row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹${kit.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                              height: 1.0,
                            ),
                          ),
                          const Spacer(),
                          // View Details icon
                          GestureDetector(
                            onTap: onViewDetails,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Buy Kit button
                          GestureDetector(
                            onTap: inStock ? onBuy : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: inStock
                                    ? LinearGradient(
                                        colors: [AppTheme.primaryColor, Color(0xFFFF6B9D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: inStock ? null : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: inStock
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                inStock ? 'Buy Kit' : 'Sold Out',
                                style: GoogleFonts.poppins(
                                  color: inStock ? Colors.white : const Color(0xFF9CA3AF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
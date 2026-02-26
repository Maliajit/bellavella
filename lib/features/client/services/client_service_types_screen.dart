import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ClientServiceTypesScreen extends StatelessWidget {
  final String category;
  const ClientServiceTypesScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          category,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Service Type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the perfect experience for your needs',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (category.toLowerCase().contains('salon')) ...[
                _buildCategoryCard(
                  context,
                  title: 'Luxe',
                  tag: 'PREMIUM EXPERIENCE',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'Our most luxurious services for complete rejuvenation.',
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  context,
                  title: 'Prime',
                  tag: 'BEST VALUE',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'High-quality professional services at affordable prices.',
                ),
              ] else if (category.toLowerCase().contains('spa')) ...[
                _buildCategoryCard(
                  context,
                  title: 'Ayurveda',
                  tag: 'TRADITIONAL HEALING',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'Ancient healing traditions for mind and body.',
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  context,
                  title: 'Prime',
                  tag: 'BEST VALUE',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'High-quality professional services at affordable prices.',
                ),
              ] else if (category.toLowerCase().contains('bridle')) ...[
                _buildCategoryCard(
                  context,
                  title: 'Full Bridal',
                  tag: 'COMPLETE EXPERIENCE',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'All-inclusive bridal makeover and rituals.',
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  context,
                  title: 'Pre-Bridal',
                  tag: 'PREPARATION',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'Glow-up sessions leading up to the big day.',
                ),
              ] else ...[
                _buildCategoryCard(
                  context,
                  title: 'Prime',
                  tag: 'PROFESSIONAL',
                  imageUrl: 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                  description: 'Standard professional services.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {
    required String title,
    required String tag,
    required String imageUrl,
    required String description,
  }) {
    return InkWell(
      onTap: () => context.push('/client/category-detail/$title'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

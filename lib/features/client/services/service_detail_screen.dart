import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/mock_data/mock_data.dart';
import '../../../../core/models/data_models.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    // Find service by ID (using mock data)
    final service = mockServices.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => mockServices[0],
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, service),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceSection(service),
                  const SizedBox(height: 24),
                  _buildDescription(context, service),
                  const SizedBox(height: 32),
                  _buildIncludedItems(context, service),
                  const SizedBox(height: 32),
                  _buildAddOns(context),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, service),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Service service) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          service.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildPriceSection(Service service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(service.duration, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        Text(
          '₹${service.price.toInt()}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, Service service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About Service', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          service.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildIncludedItems(BuildContext context, Service service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What\'s Included', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: service.includedItems.map((item) => _buildCheckItem(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildAddOns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Add-ons', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildAddOnItem('Extra hydration mask', '+₹300'),
        _buildAddOnItem('Hand massage', '+₹200'),
      ],
    );
  }

  Widget _buildAddOnItem(String title, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(price, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Service service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: PrimaryButton(
        label: 'Book Now',
        onPressed: () => context.push('/client/booking'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Date & Time'),
            const SizedBox(height: 16),
            _buildDateTimePicker(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Delivery Address'),
            const SizedBox(height: 16),
            _buildAddressUI(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Price Summary'),
            const SizedBox(height: 16),
            _buildPriceSummary(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return Row(
      children: [
        _buildPickerItem(Icons.calendar_today_rounded, '12 Feb, 2026'),
        const SizedBox(width: 12),
        _buildPickerItem(Icons.access_time_rounded, '10:30 AM'),
      ],
    );
  }

  Widget _buildPickerItem(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home Address', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('123, Rose Villa, Sector 5, Mumbai', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Edit')),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          _PriceRow(label: 'Item Total', value: '₹1200'),
          _PriceRow(label: 'Service Fee', value: '₹50'),
          _PriceRow(label: 'Tax (GST)', value: '₹108'),
          Divider(height: 32),
          _PriceRow(label: 'Total Amount', value: '₹1358', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: PrimaryButton(
        label: 'Confirm & Pay',
        onPressed: () => context.push('/client/booking-status'),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

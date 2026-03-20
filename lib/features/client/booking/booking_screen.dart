import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/packages/models/package_models.dart';
import '../../../../core/widgets/base_widgets.dart';

class BookingScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  const BookingScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Date & Time'),
            const SizedBox(height: 16),
            _buildDateTimePicker(
              context,
              _formatBookingDate(bookingData['booking_date']?.toString()),
              bookingData['booking_time'] ?? 'N/A',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Delivery Address'),
            const SizedBox(height: 16),
            _buildAddressUI(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Services'),
            const SizedBox(height: 16),
            _buildServicesList(),
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

  Widget _buildDateTimePicker(BuildContext context, String date, String time) {
    return Row(
      children: [
        _buildPickerItem(Icons.calendar_today_rounded, date),
        const SizedBox(width: 12),
        _buildPickerItem(Icons.access_time_rounded, time),
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
    final address = bookingData['address']?.toString().trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  address != null && address.isNotEmpty
                      ? address
                      : 'Address unavailable',
                  softWrap: true,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    final List<Map<String, String>> services = [];
    if (bookingData['service'] != null) {
      final serviceName =
          bookingData['display_name']?.toString() ??
          bookingData['variant_name']?.toString() ??
          bookingData['service_name']?.toString() ??
          bookingData['service']['name']?.toString() ??
          'Unknown Service';
      final servicePrice =
          bookingData['display_price']?.toString() ??
          bookingData['service']['price']?.toString() ??
          '0';
      services.add({
        'name': serviceName,
        'price': servicePrice,
        'qty': '1',
      });
    } else if (bookingData['package_snapshot'] != null ||
        bookingData['package'] != null) {
      final package = PackageSummary.fromJson(
        Map<String, dynamic>.from(
          (bookingData['package_snapshot'] ?? bookingData['package']) as Map,
        ),
      );
      services.add({
        'name': bookingData['display_name']?.toString() ?? package.title,
        'price': (bookingData['display_price'] ?? package.displayPrice ?? 0)
            .toString(),
        'qty': '1',
      });
    }

    if (services.isEmpty) return const Text('No services found');

    return Column(
      children: services.map((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${service['qty']}x ${service['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '₹${service['price']}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSummary() {
    final double total = _parseAmount(bookingData['total_amount']);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: 'Total Amount',
            value: '₹${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
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
        label: 'View Status',
        onPressed: () => context.push('/client/booking-status/${bookingData['id']}'),
      ),
    );
  }

  String _formatBookingDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return 'N/A';
    }

    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed == null) {
      return rawDate;
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return 0;
    }

    return double.tryParse(value.toString()) ?? 0;
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

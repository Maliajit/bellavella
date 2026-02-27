import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme.dart';

class ProfessionalOrderListScreen extends StatefulWidget {
  const ProfessionalOrderListScreen({super.key});

  @override
  State<ProfessionalOrderListScreen> createState() => _ProfessionalOrderListScreenState();
}

class _ProfessionalOrderListScreenState extends State<ProfessionalOrderListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
  }

  final List<Map<String, dynamic>> _allOrders = [
    {
      'name': 'Rohit Sharma',
      'service': 'Gold Glow Facial',
      'location': 'Pune City Center',
      'time': '18 Aug, 2:30 PM',
      'price': '₹500',
      'status': 'In Progress',
    },
    {
      'name': 'Anita Verma',
      'service': 'Manicure & Pedicure Combo',
      'location': 'Baner, Pune',
      'time': '18 Aug, 4:00 PM',
      'price': '₹700',
      'status': 'Completed',
    },
    {
      'name': 'Mohit Patel',
      'service': 'Full Body Waxing',
      'location': 'Hinjewadi, Pune',
      'time': '18 Aug, 5:30 PM',
      'price': '₹600',
      'status': 'Cancelled',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _allOrders;
    return _allOrders.where((order) => order['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/professional/incoming-request');
          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order Accepted!'), backgroundColor: Colors.green),
            );
          } else if (result == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order Rejected'), backgroundColor: Colors.red),
            );
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_call, color: Colors.white),
        label: const Text('Simulate Request', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Orders',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFilterChips(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(_filteredOrders[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondaryColor.withValues(alpha: 0.3) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () => context.push('/professional/booking-detail/BOOKING123'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['name'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                order['price'],
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order['service'],
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                order['location'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                order['time'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusBgColor(order['status']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order['status'],
                style: TextStyle(
                  color: _getStatusTextColor(order['status']),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange.shade50.withValues(alpha: 0.5);
      case 'Completed':
        return Colors.green.shade50.withValues(alpha: 0.5);
      case 'Cancelled':
        return Colors.red.shade50.withValues(alpha: 0.5);
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange.shade400;
      case 'Completed':
        return Colors.green.shade400;
      case 'Cancelled':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

}

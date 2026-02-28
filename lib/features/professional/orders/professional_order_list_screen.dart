import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import './widgets/segmented_filter_bar.dart';
import './widgets/order_item_card.dart';

class ProfessionalOrderListScreen extends StatefulWidget {
  const ProfessionalOrderListScreen({super.key});

  @override
  State<ProfessionalOrderListScreen> createState() => _ProfessionalOrderListScreenState();
}

class _ProfessionalOrderListScreenState extends State<ProfessionalOrderListScreen> {
  String _selectedFilter = 'All';
  String _sortBy = 'Time';
  final List<String> _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  // Mock Data
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '1',
      'name': 'Rahul Mehta',
      'service': 'Haircut + Beard',
      'status': 'Accepted',
      'time': '2:30 PM',
      'date': 'Today',
      'location': 'Satellite, Ahmedabad',
      'price': '₹499',
    },
    {
      'id': '2',
      'name': 'Sneha Patel',
      'service': 'Classic Facial',
      'status': 'Pending',
      'time': '4:00 PM',
      'date': 'Today',
      'location': 'Bodakdev, Ahmedabad',
      'price': '₹850',
    },
    {
      'id': '3',
      'name': 'Amit Shah',
      'service': 'Full Body Massage',
      'status': 'Upcoming',
      'time': '10:30 AM',
      'date': 'Tomorrow',
      'location': 'Prahlad Nagar, Ahmedabad',
      'price': '₹1,200',
    },
    {
      'id': '4',
      'name': 'Priya Rai',
      'service': 'Manicure & Pedicure',
      'status': 'Completed',
      'time': '11:00 AM',
      'date': 'Yesterday',
      'location': 'Navrangpura, Ahmedabad',
      'price': '₹600',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _orders;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((o) => o['date'] == _selectedFilter || o['status'] == _selectedFilter).toList();
    }
    
    // Sort logic (Mock)
    if (_sortBy == 'Price') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    }
    
    return filtered;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sort by",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _sortOption("Time", Icons.access_time_rounded),
              _sortOption("Earnings", Icons.account_balance_wallet_outlined),
              _sortOption("Status", Icons.info_outline_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _sortOption(String label, IconData icon) {
    final bool isSelected = _sortBy == label;
    return ListTile(
      onTap: () {
        setState(() => _sortBy = label);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_rounded, color: AppTheme.primaryColor) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orders',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Refreshing orders..."),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.black87),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      // ElevatedButton.icon(
                      //   onPressed: () => context.pushNamed(AppRoutes.proIncomingRequestName),
                      //   icon: const Icon(Icons.notifications_active_rounded, size: 16),
                      //   label: const Text("Test Request"),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      //     foregroundColor: AppTheme.primaryColor,
                      //     elevation: 0,
                      //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //   ),
                      // ),
                      // const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sort_rounded, size: 20, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Bar
            SegmentedFilterBar(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterChanged: (value) => setState(() => _selectedFilter = value),
            ),
            
            const SizedBox(height: 16),

            // Orders List or Empty State
            Expanded(
              child: filtered.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return OrderItemCard(
                        order: order,
                        onTap: () => context.pushNamed(
                          AppRoutes.proBookingDetailName,
                          pathParameters: {'id': order['id']},
                        ),
                        onSwipeAction: (isPositive) {
                          final action = isPositive ? "Accepted" : "Rejected";
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Order ${order['id']} $action"),
                              backgroundColor: isPositive ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No orders yet.",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Stay online to receive bookings.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

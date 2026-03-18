import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import './widgets/segmented_filter_bar.dart';
import './widgets/order_item_card.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart' as pro_models;
import '../../../core/models/data_models.dart';

class ProfessionalOrderListScreen extends StatefulWidget {
  const ProfessionalOrderListScreen({super.key});

  @override
  State<ProfessionalOrderListScreen> createState() => _ProfessionalOrderListScreenState();
}

class _ProfessionalOrderListScreenState extends State<ProfessionalOrderListScreen> {
  String _selectedFilter = 'All';
  String _sortBy = 'Time';
  final List<String> _filters = ['All', 'Today', 'Upcoming', 'Completed'];
  
  List<pro_models.ProfessionalBooking> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orders = await ProfessionalApiService.getBookings();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<pro_models.ProfessionalBooking> get _filteredOrders {
    List<pro_models.ProfessionalBooking> filtered = _orders;
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Today') {
        filtered = filtered.where((o) => o.isToday).toList();
      } else if (_selectedFilter == 'Upcoming') {
        filtered = filtered.where((o) => o.isActive).toList();
      } else if (_selectedFilter == 'Completed') {
        filtered = filtered.where((o) => o.status == BookingStatus.completed).toList();
      }
    }
    
    // Sort logic (Dynamic)
    if (_sortBy == 'Earnings') {
      filtered.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
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
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.black87),
                        padding: EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          padding: EdgeInsets.all(8),
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
              child: RefreshIndicator(
                onRefresh: _fetchOrders,
                color: AppTheme.primaryColor,
                child: filtered.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return OrderItemCard(
                          order: {
                            'id': order.id,
                            'name': order.clientName,
                            'service': order.serviceName,
                            'status': order.status == BookingStatus.accepted ? 'Accepted' :
                                      order.status == BookingStatus.inProgress ? 'Ongoing' :
                                      order.status == BookingStatus.completed ? 'Completed' :
                                      order.status == BookingStatus.cancelled ? 'Cancelled' : 'Pending',
                            'time': order.time,
                            'date': order.date,
                            'location': order.address,
                            'price': '₹${order.totalPrice}',
                          },
                          onTap: () => context.pushNamed(
                            AppRoutes.proBookingDetailName,
                            pathParameters: {'id': order.id},
                          ),
                          onSwipeAction: (isPositive) async {
                            if (isPositive) {
                              try {
                                await ProfessionalApiService.acceptBooking(order.id);
                                _fetchOrders();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                        );
                      },
                    ),
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

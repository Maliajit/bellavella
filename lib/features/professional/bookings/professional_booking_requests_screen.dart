import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalBookingRequestsScreen extends StatefulWidget {
  const ProfessionalBookingRequestsScreen({super.key});

  @override
  State<ProfessionalBookingRequestsScreen> createState() => _ProfessionalBookingRequestsScreenState();
}

class _ProfessionalBookingRequestsScreenState extends State<ProfessionalBookingRequestsScreen> {
  List<pro_models.ProfessionalBooking> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final requests = await ProfessionalApiService.getBookingRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
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

  Future<void> _acceptBooking(String id) async {
    try {
      final res = await ProfessionalApiService.acceptBooking(id);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking accepted successfully!')),
        );
        _fetchRequests(); // Refresh list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
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
              ElevatedButton(
                onPressed: _fetchRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Requests')),
      body: _requests.isEmpty
          ? const Center(child: Text('No new requests at the moment'))
          : RefreshIndicator(
              onRefresh: _fetchRequests,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final booking = _requests[index];
                  return _RequestCard(
                    name: booking.clientName,
                    service: booking.serviceName,
                    time: booking.time,
                    price: '₹${booking.totalPrice}',
                    onAccept: () => _acceptBooking(booking.id),
                    onDecline: () {
                      // Implementation for declining could be added if API exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Declined locally')),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final String service;
  final String time;
  final String price;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.name,
    required this.service,
    required this.time,
    required this.price,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Divider(),
          ),
          Text(
            'Service: $service',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

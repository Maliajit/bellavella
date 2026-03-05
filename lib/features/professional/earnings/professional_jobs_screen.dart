import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/professional_api_service.dart';
import '../models/professional_models.dart' as pro_models;
import '../../../../core/models/data_models.dart';

class ProfessionalJobsScreen extends StatefulWidget {
  const ProfessionalJobsScreen({super.key});

  @override
  State<ProfessionalJobsScreen> createState() => _ProfessionalJobsScreenState();
}

class _ProfessionalJobsScreenState extends State<ProfessionalJobsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<pro_models.ProfessionalBooking> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
          // Filter for pending/requested status if needed, 
          // but assuming getBookingRequests returns available ones for this screen.
          _requests = requests.where((r) => r.status == BookingStatus.requested).toList();
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_errorMessage'),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchRequests, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchRequests,
                          color: AppTheme.primaryColor,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Available Requests',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 15),
                                  if (_requests.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 40),
                                        child: Text('No new requests at the moment.'),
                                      ),
                                    )
                                  else
                                    ..._requests.map((request) => _buildJobCard(
                                          request.id,
                                          request.clientName,
                                          request.serviceName,
                                          request.time,
                                          '₹${request.totalPrice}',
                                          request.address,
                                        )),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _isScrolled ? Colors.white : Colors.black,
            onPressed: () => context.pop(),
          ),
          Text(
            'Job Requests',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(String id, String name, String service, String time, String price, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(price, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(service, style: const TextStyle(color: Colors.black87, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(location, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ProfessionalApiService.acceptBooking(id);
                  _fetchRequests();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request accepted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Accept Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

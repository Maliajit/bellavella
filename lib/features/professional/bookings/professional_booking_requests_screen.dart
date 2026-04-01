import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import 'package:bellavella/core/widgets/job_request_popup.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/widgets/scale_button.dart';

class ProfessionalBookingRequestsScreen extends StatefulWidget {
  const ProfessionalBookingRequestsScreen({super.key});

  @override
  State<ProfessionalBookingRequestsScreen> createState() => _ProfessionalBookingRequestsScreenState();
}

class _ProfessionalBookingRequestsScreenState extends State<ProfessionalBookingRequestsScreen> {
  List<pro_models.ProfessionalBooking> _requests = [];
  bool _isLoading = true;
  bool _isRejecting = false;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking accepted successfully!')),
        );
        _fetchRequests(); // Refresh list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String id) async {
    if (_isRejecting) return;

    final profileController = Provider.of<ProfessionalProfileController>(context, listen: false);

    // 🚫 HARD BLOCK: Check for suspension FIRST
    if (profileController.profile?.isSuspended == true) {
      JobRequestPopup.showRejectionLimit(context, 0, status: 'suspended');
      return;
    }

    // ⚡ INSTANT FEEDBACK
    HapticFeedback.mediumImpact();
    _isRejecting = true;

    final int currentRejectCount = profileController.profile?.rejectCount ?? 0;
    
    // 🔮 PREDICTIVE STATE
    final int predictedRemaining = (3 - (currentRejectCount + 1)).clamp(0, 3);
    final bool willBeSuspended = predictedRemaining <= 0;

    // 🔥 OPTIMISTIC UI: Remove from list immediately
    pro_models.ProfessionalBooking? removedBooking;
    int? removedIndex;
    setState(() {
      removedIndex = _requests.indexWhere((r) => r.id == id);
      if (removedIndex != -1) {
        removedBooking = _requests.removeAt(removedIndex!);
      }
    });

    // 🚀 SHOW POPUP INSTANTLY
    JobRequestPopup.showRejectionLimit(
      context, 
      predictedRemaining, 
      status: willBeSuspended ? 'suspended' : 'active',
      rejectCount: currentRejectCount + 1,
    );

    try {
      // 🔄 Background API Call
      final res = await ProfessionalApiService.rejectBooking(id);
      
      if (!mounted) return;
      
      if (res['success'] == true) {
        // 🧩 DESYNC PROTECTION: Always trust backend
        final data = res['data'];
        if (data != null) {
          final int trueCount = data['reject_count'] ?? (currentRejectCount + 1);
          final bool isSuspended = data['status'] == 'suspended' || (3 - trueCount) <= 0;
          profileController.updateRejectionStats(trueCount, isSuspended);
        } else {
          profileController.fetchProfile(); 
        }
      } else {
        // 🚨 ROLLBACK IF NEEDED (except if already suspended)
        if (res['_http_status'] == 403 || res['_account_suspended'] == true) {
          profileController.updateRejectionStats(3, true);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) context.go(AppRoutes.proSuspended);
          });
        } else {
          // General failure rollback
          if (removedBooking != null && removedIndex != -1) {
            setState(() => _requests.insert(removedIndex!, removedBooking!));
          }
        }
      }
    } catch (e) {
       debugPrint('❌ Reject Error: $e');
      if (!mounted) return;
      if (e.toString().contains('suspended')) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) context.go(AppRoutes.proSuspended);
        });
      } else {
        // Rollback on network error
        if (removedBooking != null && removedIndex != -1) {
           setState(() => _requests.insert(removedIndex!, removedBooking!));
        }

        // 📡 NETWORK FAILURE UX (Elite Polish)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Action failed. Check your connection."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
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
                padding: EdgeInsets.all(24),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final booking = _requests[index];
                  return _RequestCard(
                    name: booking.clientName,
                    service: booking.serviceName,
                    time: booking.time,
                    price: '₹${booking.totalPrice}',
                    onAccept: () => _acceptBooking(booking.id),
                    onDecline: () => _rejectBooking(booking.id),
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
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
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
              CircleAvatar(
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
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
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
                child: ScaleButton(
                  onTap: onDecline,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledForegroundColor: Colors.red,
                      disabledMouseCursor: SystemMouseCursors.click,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScaleButton(
                  onTap: onAccept,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.green,
                      disabledForegroundColor: Colors.white,
                      disabledMouseCursor: SystemMouseCursors.click,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

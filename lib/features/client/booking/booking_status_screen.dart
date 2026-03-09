import 'package:flutter/material.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;
  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _bookingInfo;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    if (widget.bookingId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid booking ID';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await ApiService.get('/client/bookings/${widget.bookingId}');

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _bookingInfo = response['data'] ?? {};
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load status';
            if (response['message'] == 'Unauthenticated.') {
              _errorMessage = 'Please sign in to view tracking status.';
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Status'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/client/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildStatusHeader(context),
                      const SizedBox(height: 48),
                      _buildTimeline(),
                      const SizedBox(height: 48),
                      _buildProfessionalInfo(context),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Track Professional',
                        onPressed: () => context.push('/client/live-tracking/${widget.bookingId}'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go('/client/home'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final statusStr = _bookingInfo?['status']?.toString().toLowerCase() ?? 'pending';
    String titleStr = 'Booking Confirmed!';
    if (statusStr == 'pending') titleStr = 'Booking Requested';
    if (statusStr == 'completed') titleStr = 'Booking Completed!';
    if (statusStr == 'cancelled') titleStr = 'Booking Cancelled';

    final time = _bookingInfo?['booking_time']?.toString() ?? '--:--';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusStr == 'cancelled' ? Colors.red.shade50 : Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(statusStr == 'cancelled' ? Icons.cancel_rounded : Icons.check_circle_rounded, 
             color: statusStr == 'cancelled' ? Colors.red : Colors.green, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          titleStr,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Scheduled for $time',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  int _getStatusLevel(String status) {
    switch (status) {
      case 'pending': return 1;
      case 'accepted': return 2;
      case 'on the way':
      case 'professional on the way': return 3;
      case 'service started':
      case 'started': return 4;
      case 'completed': return 5;
      default: return 1;
    }
  }

  Widget _buildTimeline() {
    final statusStr = _bookingInfo?['status']?.toString().toLowerCase() ?? 'pending';
    if (statusStr == 'cancelled') {
        return const Center(child: Text('This booking was cancelled.'));
    }
    
    final level = _getStatusLevel(statusStr);
    final timeStr = _bookingInfo?['booking_time']?.toString() ?? '--:--';

    return Column(
      children: [
        _TimelineItem(title: 'Requested', time: timeStr, isCompleted: level > 1, isActive: level == 1, isFirst: true),
        _TimelineItem(title: 'Accepted', time: '--:--', isCompleted: level > 2, isActive: level == 2),
        _TimelineItem(title: 'On the way', time: '--:--', isCompleted: level > 3, isActive: level == 3),
        _TimelineItem(title: 'Started', time: '--:--', isCompleted: level > 4, isActive: level == 4),
        _TimelineItem(title: 'Completed', time: '--:--', isCompleted: level >= 5, isActive: level == 5, isLast: true),
      ],
    );
  }

  Widget _buildProfessionalInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200'),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elena Smith', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Pro Beautician • 4.9 ★', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_rounded, color: AppTheme.primaryColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : (isActive ? AppTheme.primaryColor : Colors.grey.shade300),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 4) : null,
              ),
              child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive || isCompleted ? AppTheme.accentColor : Colors.grey,
                ),
              ),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}

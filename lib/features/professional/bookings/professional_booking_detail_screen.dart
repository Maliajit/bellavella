import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/widgets/base_widgets.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/features/professional/services/professional_api_service.dart';

class ProfessionalBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const ProfessionalBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<ProfessionalBookingDetailScreen> createState() => _ProfessionalBookingDetailScreenState();
}

class _ProfessionalBookingDetailScreenState extends State<ProfessionalBookingDetailScreen> {
  pro_models.ProfessionalBooking? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final booking = await ProfessionalApiService.getBookingDetail(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(Future<Map<String, dynamic>> Function(String) apiCall) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await apiCall(widget.bookingId);

      if (mounted) {
        Navigator.pop(context);
      }

      await _fetchBookingDetails();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _completeJob() async {
    await _updateStatus(ProfessionalApiService.jobComplete);
    if (mounted) {
      context.go('/professional/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Booking #${_booking!.id}')),
      body: RefreshIndicator(
        onRefresh: _fetchBookingDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientInfo(),
              const SizedBox(height: 24),
              _buildServiceInfo(),
              const SizedBox(height: 24),
              _buildScheduleInfo(),
              const SizedBox(height: 24),
              _buildLocationInfo(),
              const SizedBox(height: 40),
              _buildStatusUpdateUI(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          child: Icon(Icons.person_rounded),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _booking!.clientName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                _booking!.phone.isEmpty ? 'BellaVella Customer' : _booking!.phone,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _booking!.phone.isNotEmpty ? () {} : null,
          icon: const Icon(Icons.call_rounded, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildServiceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Requested',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.secondaryColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _booking!.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'Rs ${_booking!.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text('${_booking!.date} at ${_booking!.time}'),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_booking!.address, style: const TextStyle(height: 1.4)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusUpdateUI(BuildContext context) {
    final status = _booking!.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (status == BookingStatus.accepted)
          PrimaryButton(
            label: 'Start Journey',
            onPressed: () => _updateStatus(ProfessionalApiService.jobStartJourney),
          ),
        if (status == BookingStatus.onTheWay)
          PrimaryButton(
            label: 'Mark Arrived',
            onPressed: () => _updateStatus(ProfessionalApiService.jobArrived),
          ),
        if (status == BookingStatus.arrived ||
            status == BookingStatus.scanKit)
          PrimaryButton(
            label: 'Start Service',
            onPressed: () => _updateStatus(ProfessionalApiService.jobStartService),
          ),
        if (status == BookingStatus.inProgress ||
            status == BookingStatus.paymentPending)
          PrimaryButton(
            label: 'Complete Job',
            onPressed: _completeJob,
          ),
        const SizedBox(height: 12),
        if (status != BookingStatus.completed)
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Dashboard'),
          ),
        if (status == BookingStatus.completed)
          Text(
            'This booking is already completed.',
            style: GoogleFonts.outfit(color: Colors.grey.shade600),
          ),
      ],
    );
  }
}

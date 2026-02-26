import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/data_models.dart';

class ProfessionalBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const ProfessionalBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<ProfessionalBookingDetailScreen> createState() => _ProfessionalBookingDetailScreenState();
}

class _ProfessionalBookingDetailScreenState extends State<ProfessionalBookingDetailScreen> {
  BookingStatus _status = BookingStatus.accepted;
  final String _clientArrivalCode = "1234"; // Mock
  final String _professionalPaymentCode = "1234"; // Mock
  final _codeController = TextEditingController();
  bool _isKitVerified = false;

  void _verifyKitQR() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Scan Official Kit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan the QR code on your official Bellavella kit to ensure authenticity.'),
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Verifying kit reliability...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _isKitVerified = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kit Verified! You can now start the service.'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Simulate Scan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyArrival() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Client Verification', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 4-digit code shown on the client\'s app.'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: 'Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text == _clientArrivalCode) {
                setState(() => _status = BookingStatus.arrived);
                Navigator.pop(context);
                _codeController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid Code'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Collect Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Show this code to the client for payment confirmation:'),
            const SizedBox(height: 20),
            Text(
              _professionalPaymentCode,
              style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 10, color: AppTheme.primaryColor),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Done',
            onPressed: () {
              setState(() => _status = BookingStatus.completed);
              Navigator.pop(context);
              context.go('/professional/orders');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfo(),
            const SizedBox(height: 32),
            _buildServiceInfo(),
            const SizedBox(height: 32),
            _buildLocationInfo(),
            const SizedBox(height: 48),
            _buildStatusUpdateUI(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200'),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sarah Johnson', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Customer since 2023', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.call_rounded, color: Colors.green)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor)),
      ],
    );
  }

  Widget _buildServiceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Requested', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.secondaryColor),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hydrating hair Spa', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('₹1,200', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text('123, Rose Villa, Sector 5, Near Lotus Park, Mumbai, 400001', style: TextStyle(height: 1.4)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusUpdateUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_status == BookingStatus.accepted)
          PrimaryButton(
            label: 'Start Journey', 
            onPressed: () => setState(() => _status = BookingStatus.onTheWay),
          ),
        if (_status == BookingStatus.onTheWay)
          PrimaryButton(
            label: 'I Have Arrived', 
            onPressed: _verifyArrival,
          ),
        if (_status == BookingStatus.arrived)
          _isKitVerified 
            ? PrimaryButton(
                label: 'Start Service', 
                onPressed: () => setState(() => _status = BookingStatus.started),
              )
            : PrimaryButton(
                label: 'Verify Kit QR', 
                onPressed: _verifyKitQR,
              ),
        if (_status == BookingStatus.started)
          PrimaryButton(
            label: 'Complete & Collect Payment', 
            onPressed: _showPaymentCode,
          ),
        const SizedBox(height: 12),
        if (_status != BookingStatus.completed)
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cancel Request'),
          ),
      ],
    );
  }
}

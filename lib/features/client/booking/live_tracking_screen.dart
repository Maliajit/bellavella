import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/models/data_models.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // Mocking status updates
  BookingStatus _currentStatus = BookingStatus.onTheWay;
  final String _arrivalCode = "1234"; // Mock code for physical verification
  final _paymentConfirmController = TextEditingController();

  @override
  void dispose() {
    _paymentConfirmController.dispose();
    super.dispose();
  }

  void _showPaymentEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Payment Confirmation', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the code shown on the professional\'s app to confirm payment.'),
            const SizedBox(height: 20),
            TextField(
              controller: _paymentConfirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: '4-digit Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_paymentConfirmController.text == "1234") { // Mock check
                Navigator.pop(context);
                context.go('/client/home');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Confirmed! Service Completed.'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid Code'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Live Tracking', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Mock Map Area
          Container(
            color: Colors.grey.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 100, color: Colors.grey.shade300),
                  Text('Interactive Map View', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 20),
                  // Mock Professional Marker
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrackInfo(),
                  const Divider(height: 48),
                  _buildProfessionalCard(),
                  const SizedBox(height: 32),
                  if (_currentStatus == BookingStatus.onTheWay)
                    _buildArrivalCodeSection(),
                  if (_currentStatus == BookingStatus.arrived || _currentStatus == BookingStatus.started)
                    PrimaryButton(label: 'Verify Payment (Offline)', onPressed: _showPaymentEntryDialog),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // STATUS SIMULATOR (MOCK) - Moved to top layer
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSimBtn('On Way', BookingStatus.onTheWay),
                  _buildSimBtn('Arrived', BookingStatus.arrived),
                  _buildSimBtn('Started', BookingStatus.started),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    String statusText = "Professional is on the way";
    String timeText = "Arriving in 8 mins";
    IconData statusIcon = Icons.directions_bike;

    if (_currentStatus == BookingStatus.arrived) {
      statusText = "Professional has reached!";
      timeText = "Ready to start";
      statusIcon = Icons.location_on;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(statusIcon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(timeText, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalCard() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elena Smith', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 14),
                  SizedBox(width: 4),
                  Text('4.9 • Super Pro', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        _buildActionBtn(Icons.call_rounded, () {}),
        const SizedBox(width: 12),
        _buildActionBtn(Icons.chat_bubble_outline_rounded, () {}),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.accentColor, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildArrivalCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('Verification Code', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            _arrivalCode,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Show this code to the professional on arrival',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSimBtn(String label, BookingStatus status) {
    final isSelected = _currentStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _currentStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

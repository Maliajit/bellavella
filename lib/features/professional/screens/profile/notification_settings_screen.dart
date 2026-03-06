import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _bookingUpdates = true;
  bool _paymentAlerts = true;
  bool _marketingOffers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Notification Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Main Settings"),
            _buildToggleTile("Push Notifications", "Enable system alerts and updates", _pushNotifications, (v) => setState(() => _pushNotifications = v)),
            _buildToggleTile("Email Notifications", "Receive monthly reports and invoices", _emailNotifications, (v) => setState(() => _emailNotifications = v)),
            const SizedBox(height: 32),
            _buildSectionHeader("Activity Alerts"),
            _buildToggleTile("Booking Updates", "Alerts for new or modified bookings", _bookingUpdates, (v) => setState(() => _bookingUpdates = v)),
            _buildToggleTile("Payment Alerts", "Instant alerts for earnings and payouts", _paymentAlerts, (v) => setState(() => _paymentAlerts = v)),
            _buildToggleTile("Marketing Offers", "Learn about new features and rewards", _marketingOffers, (v) => setState(() => _marketingOffers = v)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1),
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value, 
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ProfessionalNotificationsScreen extends StatelessWidget {
  const ProfessionalNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Mark all read",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildSectionTitle("Today"),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.payments_outlined,
            iconColor: Colors.green.shade600,
            title: "Payment Received",
            description: "₹1,200 from Nikhil Sharma has been credited to your wallet.",
            time: "10:30 AM",
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Icons.calendar_month_outlined,
            iconColor: Colors.blue.shade600,
            title: "New Booking Accepted",
            description: "You have a new booking for a Classic Haircut at 04:30 PM.",
            time: "09:15 AM",
            isUnread: true,
          ),
          
          const SizedBox(height: 32),
          _buildSectionTitle("Yesterday"),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.verified_user_outlined,
            iconColor: Colors.orange.shade600,
            title: "Profile Verified",
            description: "Your professional profile has been verified! You can now accept premium jobs.",
            time: "05:45 PM",
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFFFB800),
            title: "New 5-Star Review!",
            description: "Pooja Mehta gave you a 5-star rating for her Hair Spa service.",
            time: "02:20 PM",
            isUnread: false,
          ),

          const SizedBox(height: 32),
          _buildSectionTitle("Earlier"),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.purple.shade600,
            title: "Low Kit Inventory",
            description: "Your service kits are low (6 remaining). Please refill soon to stay online.",
            time: "15 Aug, 11:00 AM",
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

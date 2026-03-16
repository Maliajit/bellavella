import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/core/models/data_models.dart';

class JobCard extends StatelessWidget {
  final ProfessionalBooking job;
  final String buttonText;
  final VoidCallback onPressed;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  const JobCard({
    super.key,
    required this.job,
    required this.buttonText,
    required this.onPressed,
    this.onCall,
    this.onNavigate,
  });

  String get _statusLabel {
    switch (job.status) {
      case BookingStatus.accepted:
        return '● ACCEPTED';
      case BookingStatus.onTheWay:
        return '● ON THE WAY';
      case BookingStatus.arrived:
        return '● ARRIVED';
      case BookingStatus.started:
        return '● IN PROGRESS';
      default:
        return '● ACTIVE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5F8F), Color(0xFFFF2D6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D6F).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Time badge + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job.time.isNotEmpty ? job.time : 'Asap',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Client Name
          Text(
            job.clientName.isNotEmpty ? job.clientName : 'Customer',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          // Service Name
          Text(
            job.serviceName.isNotEmpty ? job.serviceName : 'Facial Service',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 8),

          // Price
          Text(
            '₹${job.totalPrice.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.address.isNotEmpty ? job.address : 'Location unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons: Call & Navigate
          Row(
            children: [
              _buildSecondaryAction(
                icon: Icons.phone_rounded,
                label: 'Call',
                onTap: onCall,
              ),
              const SizedBox(width: 12),
              _buildSecondaryAction(
                icon: Icons.near_me_rounded,
                label: 'Navigate',
                onTap: onNavigate,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF2D6F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

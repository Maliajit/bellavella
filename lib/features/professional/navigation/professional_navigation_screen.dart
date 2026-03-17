import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/core/models/data_models.dart';

class ProfessionalNavigationScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  const ProfessionalNavigationScreen({super.key, required this.booking});

  @override
  State<ProfessionalNavigationScreen> createState() => _ProfessionalNavigationScreenState();
}

class _ProfessionalNavigationScreenState extends State<ProfessionalNavigationScreen> {
  late ProfessionalBooking _booking;
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _fetchLatestData();
  }

  Future<void> _fetchLatestData() async {
    try {
      final latest = await ProfessionalApiService.getBookingDetail(_booking.id);
      if (mounted) {
        setState(() {
          _booking = latest;
          _isLoading = false;
        });
        _syncController();
      }
    } catch (e) {
      debugPrint('Error fetching latest booking: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Syncs the local booking state with the central DashboardController.
  void _syncController() {
    if (mounted) {
      DashboardController.instance.setActiveJob(_booking);
      debugPrint('🔄 Navigation: Synced controller with ${_booking.id} (${_booking.status.name})');
    }
  }

  Future<void> _startJourney() async {
    setState(() => _isProcessing = true);
    try {
      final res = await ProfessionalApiService.jobStartJourney(widget.booking.id);
      if (mounted) {
        if (res['success'] == true) {
          // Proactively update status to On The Way in the controller
          final updated = widget.booking.copyWith(status: BookingStatus.onTheWay);
          DashboardController.instance.updateJob(updated);

          context.pushNamed(
            AppRoutes.proActiveJobName, 
            pathParameters: {'id': widget.booking.id},
            extra: updated
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to start journey')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _launchNavigation() async {
    if (_booking.lat != null && _booking.lng != null) {
      await _openGoogleMaps(_booking.lat!, _booking.lng!);
    } else {
      await _openAddressSearch(_booking.address);
    }
    // Also trigger the backend/state transition
    await _startJourney();
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAddressSearch(String address) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map Preview Section
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_preview.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F4F6),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Map Preview Unavailable",
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Navigation',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Panel
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _booking.clientName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _booking.serviceName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '12 mins',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              '4.2 km',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _booking.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _launchNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            "Start Journey",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

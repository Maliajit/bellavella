import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import '../widgets/workflow_stepper.dart';

class ProKitScanScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  const ProKitScanScreen({super.key, required this.booking});

  @override
  State<ProKitScanScreen> createState() => _ProKitScanScreenState();
}

class _ProKitScanScreenState extends State<ProKitScanScreen> {
  bool _isScanned = false;
  bool _isStarting = false;
  late ProfessionalBooking _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking.id.isNotEmpty && _booking.clientName == 'Unknown') {
      _fetchLatestDetails();
    }
  }

  Future<void> _fetchLatestDetails() async {
    try {
      final latest = await ProfessionalApiService.getBookingDetail(_booking.id);
      if (mounted) {
        setState(() => _booking = latest);
        _syncController();
      }
    } catch (e) {
      debugPrint('Failed to re-fetch booking: $e');
    }
  }

  /// Syncs the local booking state with the central DashboardController.
  void _syncController() {
    if (mounted) {
      DashboardController.instance.setActiveJob(_booking);
      debugPrint('🔄 Kit Scan: Synced controller with ${_booking.id} (${_booking.status.name})');
    }
  }

  Future<void> _startService() async {
    setState(() => _isStarting = true);
    try {
      final res = await ProfessionalApiService.jobStartService(_booking.id);
      if (mounted) {
        if (res['success'] == true) {
          // Fetch updated booking with serviceStartedAt
          final updatedBooking = await ProfessionalApiService.getBookingDetail(_booking.id);
          if (mounted) {
            DashboardController.instance.setActiveJob(updatedBooking);
            context.pushNamed(AppRoutes.proActiveJobName, pathParameters: {'id': _booking.id}, extra: updatedBooking);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to start service')),
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
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _simulateScan() {
    setState(() => _isScanned = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Scan Service Kit",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          const WorkflowStepper(currentStep: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (!_isScanned) ...[
                    const SizedBox(height: 20),
                    // Camera Mockup Area
                    GestureDetector(
                      onTap: _simulateScan,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Scanning Frame
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            // Scanning Line Animation Mock
                            Positioned(
                              top: 150,
                              child: Container(
                                width: 180,
                                height: 2,
                                color: Colors.blue.withValues(alpha: 0.5),
                              ),
                            ),
                            const Positioned(
                              bottom: 20,
                              child: Text(
                                "Tap to simulate scan",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Scan the barcode on the assigned service kit.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Enter Code Manually",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 40),
                    // Confirmation Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Kit Verified",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Kit ID: BK-2034",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isScanned)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _startService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isStarting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        "Start Service",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

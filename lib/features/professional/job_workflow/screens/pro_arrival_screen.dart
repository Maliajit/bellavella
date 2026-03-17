import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/core/models/data_models.dart';
import '../widgets/workflow_stepper.dart';

class ProArrivalScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  final bool isInsideContainer;
  const ProArrivalScreen({super.key, required this.booking, this.isInsideContainer = false});

  @override
  State<ProArrivalScreen> createState() => _ProArrivalScreenState();
}

class _ProArrivalScreenState extends State<ProArrivalScreen> {
  bool _isProcessing = false;
  late ProfessionalBooking _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    // Only fetch if name is missing or we explicitly need a refresh
    if (_booking.id.isNotEmpty && (_booking.clientName == 'Unknown' || _booking.clientName.isEmpty)) {
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

  void _confirmArrival() {
    // 🔥 Optimistic UI Update
    final updated = _booking.copyWith(status: BookingStatus.scanKit);
    DashboardController.instance.updateJob(updated);
    
    // 🔥 Navigate instantly
    context.pushNamed(AppRoutes.proScanKitName, pathParameters: {'id': _booking.id}, extra: updated);

    // 🔥 Backend Sync in Background
    ProfessionalApiService.jobArrived(_booking.id).then((res) {
      if (res['success'] != true) {
        debugPrint('Background arrival failed: ${res['message']}');
      }
    }).catchError((e) {
      debugPrint('Background arrival error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInsideContainer) {
      return _buildBody();
    }

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
          "Arrived at Location",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          const WorkflowStepper(currentStep: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _booking.serviceName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 20, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Address',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.booking.address,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Action Required",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Please confirm your arrival only when you have reached the customer's doorstep.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmArrival,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Confirm Arrival",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text(
                  "Call Customer",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

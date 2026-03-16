import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:intl/intl.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import '../widgets/workflow_stepper.dart';

class ProJobCompleteScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  const ProJobCompleteScreen({super.key, required this.booking});

  @override
  State<ProJobCompleteScreen> createState() => _ProJobCompleteScreenState();
}

class _ProJobCompleteScreenState extends State<ProJobCompleteScreen> {
  late ProfessionalBooking _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    if (_booking.id.isNotEmpty && _booking.clientName == 'Unknown') {
      _fetchLatestDetails();
    }
    // Job is complete — clear it from global active state immediately
    _clearActiveJob();
  }

  void _clearActiveJob() {
    if (mounted) {
      DashboardController.instance.clearJob();
      debugPrint('✅ Completion: Cleared active job controller');
    }
  }

  Future<void> _fetchLatestDetails() async {
    try {
      final latest = await ProfessionalApiService.getBookingDetail(_booking.id);
      if (mounted) {
        setState(() => _booking = latest);
      }
    } catch (e) {
      debugPrint('Failed to re-fetch booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const WorkflowStepper(currentStep: 5),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 64, color: Colors.green),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Job Completed Successfully",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        "You Earned",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(_booking.totalPrice),
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _summaryItem(Icons.person_outline_rounded, "Client", _booking.clientName),
                            const SizedBox(height: 16),
                            _summaryItem(Icons.timer_outlined, "Duration", "45 mins"),
                            const SizedBox(height: 16),
                            _summaryItem(Icons.qr_code_rounded, "Payment", "Received"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.goNamed(AppRoutes.proDashboardName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Return to Dashboard",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

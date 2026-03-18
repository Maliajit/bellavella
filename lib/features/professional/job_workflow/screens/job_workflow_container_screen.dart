import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/core/models/data_models.dart';
import '../widgets/workflow_stepper.dart';

// Import the existing screens (we will refactor them to provide 'Body' widgets or use them as-is)
import 'pro_arrival_screen.dart';
import 'pro_kit_scan_screen.dart';
import 'pro_service_screen.dart';
import 'pro_payment_screen.dart';
import 'pro_completion_screen.dart';

class JobWorkflowContainerScreen extends StatefulWidget {
  final String bookingId;
  const JobWorkflowContainerScreen({super.key, required this.bookingId});

  @override
  State<JobWorkflowContainerScreen> createState() => _JobWorkflowContainerScreenState();
}

class _JobWorkflowContainerScreenState extends State<JobWorkflowContainerScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure polling is active for this job
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().startJobPolling(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        final booking = controller.activeJob;
        
        // Redirect if job is completed or cleared
        if (booking == null || booking.id != widget.bookingId) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && Navigator.canPop(context)) {
               Navigator.of(context).pop();
             }
           });
           return const Scaffold(
             body: Center(child: CircularProgressIndicator()),
           );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, controller),
          body: Column(
            children: [
              WorkflowStepper(currentStep: controller.currentStep),
              Expanded(
                child: _buildStepContent(booking),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DashboardController controller) {
    final step = controller.currentStep;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
       leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            _getStepTitle(controller.currentWorkflowStep),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                "Step $step of 5",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(JobStep step) {
    switch (step) {
      case JobStep.arrived:
        return "I Have Arrived";
      case JobStep.scanKit:
        return "Scan Product Kit";
      case JobStep.service:
        return "Service In Progress";
      case JobStep.payment:
        return "Collect Payment";
      case JobStep.complete:
        return "Booking Completed";
    }
  }

  Widget _buildStepContent(ProfessionalBooking booking) {
    final step = context.read<DashboardController>().currentWorkflowStep;
    
    switch (step) {
      case JobStep.arrived:
        return ProArrivalScreen(booking: booking, isInsideContainer: true);
      case JobStep.scanKit:
        return ProKitScanScreen(booking: booking, isInsideContainer: true);
      case JobStep.service:
        return ProServiceScreen(booking: booking, isInsideContainer: true);
      case JobStep.payment:
        return ProPaymentScreen(booking: booking, isInsideContainer: true);
      case JobStep.complete:
        return ProJobCompleteScreen(booking: booking, isInsideContainer: true);
    }
  }
}

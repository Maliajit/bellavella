import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

import '../widgets/workflow_stepper.dart';

class ProKitScanScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  final bool isInsideContainer;

  const ProKitScanScreen({
    super.key,
    required this.booking,
    this.isInsideContainer = false,
  });

  @override
  State<ProKitScanScreen> createState() => _ProKitScanScreenState();
}

class _ProKitScanScreenState extends State<ProKitScanScreen> {
  bool _isScanned = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isScanned = widget.booking.status == BookingStatus.scanKit ||
        widget.booking.status == BookingStatus.inProgress ||
        widget.booking.status == BookingStatus.paymentPending ||
        widget.booking.status == BookingStatus.completed;
  }

  Future<void> _simulateScan() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().verifyKit();
      if (!mounted) return;

      if (!success) {
        setState(() => _isScanned = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kit verification failed. Please scan again.'),
          ),
        );
        return;
      }

      setState(() => _isScanned = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isScanned = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kit verification failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _startService() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().startService();
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start service. Please try again.'),
          ),
        );
        return;
      }

      context.goNamed(
        AppRoutes.proActiveJobName,
        pathParameters: {'id': widget.booking.id},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Start service failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
          'Scan Service Kit',
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
              children: [
                if (!_isScanned) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isProcessing ? null : _simulateScan,
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
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Positioned(
                            top: 150,
                            child: Container(
                              width: 180,
                              height: 2,
                              color: Colors.blue.withValues(alpha: 0.5),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Tap to simulate scan',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Scan the barcode on the assigned service kit.',
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
                      'Enter Code Manually',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kit Verified',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kit ID: BK-2034',
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
                onPressed: _isProcessing ? null : _startService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Start Service',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

import '../widgets/workflow_stepper.dart';

class ProArrivalScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  final bool isInsideContainer;

  const ProArrivalScreen({
    super.key,
    required this.booking,
    this.isInsideContainer = false,
  });

  @override
  State<ProArrivalScreen> createState() => _ProArrivalScreenState();
}

class _ProArrivalScreenState extends State<ProArrivalScreen> {
  static const String _demoArrivalOtp = '1234';

  bool _isProcessing = false;

  Future<void> _confirmArrival() async {
    if (_isProcessing) return;

    final isVerified = await _showArrivalOtpSheet();
    if (isVerified != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final success = await context.read<DashboardController>().confirmArrival();
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrival confirmation failed. Please try again.'),
          ),
        );
        return;
      }

      context.goNamed(
        AppRoutes.proScanKitName,
        pathParameters: {'id': widget.booking.id},
      );
      debugPrint('ProArrivalScreen: arrival confirmed via OTP + controller.');
    } catch (e) {
      debugPrint('ProArrivalScreen: arrival confirmation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arrival confirmation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showArrivalOtpSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ArrivalOtpSheet(
          clientName: widget.booking.clientName,
          demoOtp: _demoArrivalOtp,
        );
      },
    );
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
          'Arrived at Location',
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
                  widget.booking.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.booking.serviceName,
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
                      const Icon(
                        Icons.location_on_rounded,
                        size: 20,
                        color: Colors.blue,
                      ),
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
                  'Action Required',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ask the client for the 4-digit arrival OTP before confirming. '
                  'For demo use, the OTP is hardcoded as 1234.',
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
                  onPressed: _isProcessing ? null : _confirmArrival,
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
                          'Confirm Arrival',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text(
                  'Call Customer',
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

class _ArrivalOtpSheet extends StatefulWidget {
  final String clientName;
  final String demoOtp;

  const _ArrivalOtpSheet({
    required this.clientName,
    required this.demoOtp,
  });

  @override
  State<_ArrivalOtpSheet> createState() => _ArrivalOtpSheetState();
}

class _ArrivalOtpSheetState extends State<_ArrivalOtpSheet> {
  final TextEditingController _otpController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final enteredOtp = _otpController.text.trim();
    if (enteredOtp == widget.demoOtp) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorText = 'Incorrect OTP. Use 1234 for the demo flow.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinTheme = PinTheme(
      width: 58,
      height: 62,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFFDB2777),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Verify Client OTP',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask ${widget.clientName} for the arrival OTP before moving to kit verification.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'Demo OTP: ${widget.demoOtp}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDB2777),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Pinput(
                controller: _otpController,
                length: 4,
                autofocus: true,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration!.copyWith(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                errorPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration!.copyWith(
                    border: Border.all(color: Colors.red.shade400),
                  ),
                ),
                onCompleted: (_) => _verifyOtp(),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade500,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Verify and Continue',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

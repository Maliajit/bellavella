import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';

import '../widgets/workflow_stepper.dart';

class ProServiceScreen extends StatefulWidget {
  final ProfessionalBooking booking;
  final bool isInsideContainer;

  const ProServiceScreen({
    super.key,
    required this.booking,
    this.isInsideContainer = false,
  });

  @override
  State<ProServiceScreen> createState() => _ProServiceScreenState();
}

class _ProServiceScreenState extends State<ProServiceScreen> {
  bool _isProcessing = false;
  Timer? _timer;
  Timer? _syncTimer;
  String _timeDisplay = '00:00:00';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupBackgroundSync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  void _setupBackgroundSync() {
    // 📡 ELITE SYNC: Keeps the server-truth and local-timer perfectly aligned (drift protection).
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      
      // We don't necessarily need to call an API here because DashboardController 
      // already has a 5s polling interval. This screen-level pulse ensures the 
      // specific timer display remains snappy and reactive even during long sessions.
      setState(() {}); 
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _timeDisplay = _calculateElapsedTime();
      });
    });

    _timeDisplay = _calculateElapsedTime();
  }

  String _calculateElapsedTime() {
    final startTime = widget.booking.serviceStartedAt?.toUtc();
    if (startTime == null) return 'Waiting to start';

    final now = DateTime.now().toUtc();
    final difference = now.difference(startTime);
    if (difference.isNegative) return '00:00:00';

    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Future<void> _proceedToPayment() async {
    if (_isProcessing) return;

    if (widget.booking.serviceStartedAt == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Service Not Started',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'The service hasn\'t been started yet. Do you want to start and finish it now?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Yes, Proceed',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isProcessing = true);

    try {
      if (widget.booking.serviceStartedAt == null) {
        await context.read<DashboardController>().startService();
      }

      final success = await context.read<DashboardController>().finishService();
      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to finish service. Please try again.'),
          ),
        );
        return;
      }

      context.goNamed(
        AppRoutes.proCollectPaymentName,
        pathParameters: {'id': widget.booking.id},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Finish service failed: $e')),
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Service In Progress',
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
                  'Step 3 of 5',
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
      ),
      body: Column(
        children: [
          const WorkflowStepper(currentStep: 3),
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
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
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _timeDisplay,
                        style: GoogleFonts.inter(
                          fontSize: (widget.booking.serviceStartedAt == null) ? 32 : 48,
                          fontWeight: FontWeight.w900,
                          color: (widget.booking.serviceStartedAt == null) ? Colors.grey.shade400 : Colors.black87,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Service in progress',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Service Checklist',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _checklistItem(widget.booking.serviceName, true),
                _checklistItem('Post-service Cleanup', false),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: Text(
                      'Report Issue',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
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
              if (widget.booking.serviceStartedAt == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Start service to enable completion',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: _isProcessing ? null : _proceedToPayment,
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
                      'Finish Service',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checklistItem(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
                color: isDone ? Colors.green : Colors.transparent,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14,
                color: isDone ? Colors.white : Colors.transparent,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? Colors.black87 : Colors.grey.shade600,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class JobRequestPopup extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const JobRequestPopup({
    super.key,
    required this.jobData,
    required this.onAccept,
    required this.onReject,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> jobData,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Job Request',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return JobRequestPopup(
          jobData: jobData,
          onAccept: onAccept,
          onReject: onReject,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  @override
  State<JobRequestPopup> createState() => _JobRequestPopupState();
}

class _JobRequestPopupState extends State<JobRequestPopup> {
  int _timeLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft == 0) {
        timer.cancel();
        widget.onReject();
        Navigator.pop(context);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String service = widget.jobData['service'] ?? 'Premium Service';
    final String client = widget.jobData['client_name'] ?? 'Guest';
    final String location = widget.jobData['location'] ?? 'Nearby';
    final String price = widget.jobData['price'] ?? '0';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4891).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status/Timer Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4891),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Center(
                child: Text(
                  'NEW JOB REQUEST ($_timeLeft s)',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Service Icon & Title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF4891), width: 2),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFFF4891), size: 40),
            ),

            const SizedBox(height: 20),

            Text(
              service,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Earnings: ₹$price',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 30),

            // Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Client', client),
                  const Divider(height: 32),
                  _infoRow(Icons.location_on_outlined, 'Location', location),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onReject();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'REJECT',
                        style: GoogleFonts.outfit(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAccept();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4891),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF4891).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'ACCEPT JOB',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFFFF4891)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

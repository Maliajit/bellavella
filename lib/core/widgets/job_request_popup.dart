import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../widgets/scale_button.dart';

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

  /// Elite Rejection Limit Popup with Optimistic UI & Progress Bar
  static void showRejectionLimit(BuildContext context, int remaining, {String status = "active", int? rejectCount}) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isDismissible: status != "suspended",
      enableDrag: status != "suspended",
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 250),
      )..forward(),
      builder: (bottomSheetContext) => _RejectionLimitContent(
        remaining: remaining,
        status: status,
        rejectCount: rejectCount,
      ),
    );
  }

  /// Original Job Request Dialog
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

class _RejectionLimitContent extends StatefulWidget {
  final int remaining;
  final String status;
  final int? rejectCount;

  const _RejectionLimitContent({
    required this.remaining,
    required this.status,
    this.rejectCount,
  });

  @override
  State<_RejectionLimitContent> createState() => _RejectionLimitContentState();
}

class _RejectionLimitContentState extends State<_RejectionLimitContent> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 🔥 LAST CHANCE VISUAL PUNCH: Shake and Haptic if remaining == 1
    if (widget.remaining == 1 && widget.status != 'suspended') {
      _shakeController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1000), () => _shakeController.stop());
      HapticFeedback.vibrate();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastChance = widget.remaining == 1 && widget.status != 'suspended';
    final bool isSuspended = widget.status == 'suspended';

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double offset = _shakeController.value * 4.0;
        return Transform.translate(
          offset: Offset(isLastChance ? (offset % 2 == 0 ? offset : -offset) : 0, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: isLastChance 
                ? Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2)
                : null,
              boxShadow: isLastChance ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: (isSuspended ? Colors.red : (isLastChance ? Colors.redAccent : Colors.orange)).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuspended ? Icons.block : Icons.warning_amber_rounded,
                    color: isSuspended ? Colors.red : (isLastChance ? Colors.redAccent : Colors.orange),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  isSuspended ? 'Account Suspended' : (isLastChance ? 'LAST CHANCE!' : 'Be Careful!'),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isLastChance ? Colors.redAccent : Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Subtitle / Message
                Text(
                  isSuspended 
                    ? 'You have rejected too many requests today.\nYour account is temporarily suspended.'
                    : 'Frequent rejections may impact your account.\nRemaining chances: ${widget.remaining}/3',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // 🎯 MODERN PROGRESS BAR (Elite Polish)
                Container(
                  height: 10,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: (200 * (3 - widget.remaining) / 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSuspended 
                              ? [Colors.red, Colors.redAccent] 
                              : [Colors.orange, Colors.orangeAccent],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                
                // Action Button
                ScaleButton(
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    
                    if (isSuspended) {
                      context.go(AppRoutes.proSuspended);
                    } else {
                      try {
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      } catch (_) {}
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null, // Logic handled by ScaleButton onTap
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuspended ? Colors.red : (isLastChance ? Colors.redAccent : Colors.orange),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isSuspended ? Colors.red : (isLastChance ? Colors.redAccent : Colors.orange),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isSuspended ? 'UNDERSTOOD' : 'OK',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
                    child: ScaleButton(
                      onTap: () {
                        widget.onReject();
                        Navigator.pop(context);
                      },
                      child: OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledForegroundColor: Colors.grey.shade700,
                          disabledMouseCursor: SystemMouseCursors.click,
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ScaleButton(
                      onTap: () {
                        widget.onAccept();
                        Navigator.pop(context);
                      },
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4891),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFFF4891),
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: const Color(0xFFFF4891).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledMouseCursor: SystemMouseCursors.click,
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

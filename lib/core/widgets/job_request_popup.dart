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

  /// Elite Rejection Limit Popup with Pink Theme & Strict Flow
  static Future<bool?> showRejectionLimit(BuildContext context, int remaining, {String status = "active", int? rejectCount}) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: status != "suspended",
      enableDrag: status != "suspended",
      backgroundColor: Colors.transparent,
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

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 🔥 POPUP OPEN HAPTIC
    HapticFeedback.mediumImpact();

    if (widget.remaining == 0 && widget.status != 'suspended') {
      _shakeController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 1000), () => _shakeController.stop());
      HapticFeedback.vibrate();
    }

    // 🕒 AUTO-DISMISS (3s) - Only for active warnings
    if (widget.status != 'suspended' && widget.remaining >= 0) {
      _autoDismissTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinalWarning = widget.remaining == 0 && widget.status != 'suspended';
    final bool isSuspended = widget.status == 'suspended';
    
    // 🎨 COLOR SHIFT (Pink -> Red on Final Warning)
    final Color themeColor = isFinalWarning 
        ? const Color(0xFFE53935) // Alert Red
        : const Color(0xFFFF4D6D); // Theme Pink

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double offset = _shakeController.value * 4.0;

        return PopScope(
          canPop: false, // Prevents closing with the back button
          child: Transform.translate(
            offset: Offset(isFinalWarning ? (offset % 2 == 0 ? offset : -offset) : 0, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Indicator (Drag Handle)
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Icon (Color Shifted Circle)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuspended ? Icons.block : (isFinalWarning ? Icons.error_outline : Icons.warning_amber_rounded),
                      color: themeColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title (Expert Refinement)
                  Text(
                    isSuspended ? 'Account Suspended' : (isFinalWarning ? 'Final Warning' : 'Be Careful'),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle / Message
                  Text(
                    isSuspended 
                      ? 'You have rejected too many requests today.\nYour account is temporarily suspended.'
                      : (isFinalWarning 
                          ? 'You’ve reached your rejection limit.\nOne more rejection will suspend your account.'
                          : 'Frequent rejections may impact your account.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  if (!isSuspended) ...[
                    const SizedBox(height: 12),
                    Text(
                      isFinalWarning ? 'FINAL WARNING!' : 'Remaining: ${widget.remaining} of 3',
                      style: GoogleFonts.outfit(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 🎯 EXPERT ANIMATED STRIKE DOTS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final bool isStrike = index < (3 - widget.remaining);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: isStrike ? 14 : 12,
                          height: isStrike ? 14 : 12,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isStrike ? themeColor : Colors.grey[200],
                            border: isStrike ? null : Border.all(color: Colors.grey[300]!, width: 1),
                            boxShadow: isStrike ? [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                        );
                      }),
                    ),
                  ],

                  const SizedBox(height: 40),
                  
                  // Action Button (Full Width, Pink)
                  ScaleButton(
                    onTap: () {
                      Navigator.pop(context, true); 
                      if (isSuspended) {
                        context.go(AppRoutes.proSuspended);
                      }
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: themeColor,
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
        if (mounted) {
          timer.cancel();
          widget.onReject();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() => _timeLeft--);
        } else {
          timer.cancel();
        }
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
    final String price = widget.jobData['price']?.toString() ?? '0';

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

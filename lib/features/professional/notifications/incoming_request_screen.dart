import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart';
import 'package:bellavella/features/professional/controllers/dashboard_controller.dart';
import 'package:bellavella/core/services/realtime_job_service.dart';
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';

class IncomingRequestScreen extends StatefulWidget {
  final Map<String, dynamic> notification;
  const IncomingRequestScreen({super.key, required this.notification});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _vibrationTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 15;
  double _swipePosition = 0;
  final double _swipeThreshold = 150;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startVibrationLoop();
    _startAudioLoop();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _handleReject();
      }
    });
  }

  void _startAudioLoop() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Ensure the asset exists or use a generic sound if needed
      await _audioPlayer.play(AssetSource('audio/incoming_call.mp3'));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _startVibrationLoop() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          Vibration.vibrate(duration: 1000);
        });
        Vibration.vibrate(duration: 1000);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _vibrationTimer?.cancel();
    _countdownTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isProcessing) return;
    if (mounted) setState(() => _isProcessing = true);

    _vibrationTimer?.cancel();
    _countdownTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.stop();

    try {
      // ── Resolve booking_id from any payload shape ──────────────────────────
      // Shape 1 (Firestore job doc):   { "booking_id": 12, "service": "..." }
      // Shape 2 (DB notification):     notification['data'] = { "booking_id": 12 }
      final notif = widget.notification;
      final nestedData = notif['data'];
      final String bookingId = (notif['booking_id']
              ?? (nestedData is Map ? nestedData['booking_id'] : null)
              ?? '')
          .toString()
          .trim();

      debugPrint('🎯 _handleAccept → resolved bookingId: "$bookingId"');
      debugPrint('🎯 Full notification payload: $notif');

      if (bookingId.isEmpty) {
        throw Exception('Booking ID is missing from the notification. Cannot accept.');
      }

      // Preventive check: If this job is already active in our controller, just close and go there
      final currentActive = DashboardController.instance.activeJob;
      if (currentActive != null && currentActive.id == bookingId) {
        debugPrint('ℹ️ Job $bookingId is already active in DashboardController. Closing popup.');
        if (mounted) context.pop(true);
        return;
      }

      // Step 1: Push an optimistic booking state into the controller IMMEDIATELY
      ProfessionalBooking optimisticBooking = ProfessionalBooking.empty().copyWith(
        id: bookingId,
        clientName: clientName,
        serviceName: serviceName,
        address: location,
        totalAmount: earnings.isNotEmpty ? (double.tryParse(earnings.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) : 0.0,
        status: BookingStatus.accepted,
      );

      DashboardController.instance.setActiveJob(optimisticBooking);
      debugPrint('⚡ Optimistic UI: Syncing DashboardController instantly to accepted');

      // Step 2: Update Firestore instantly so our real-time status shows 'accepted'
      try {
        final profile = context.read<ProfessionalProfileController>().profile;
        if (profile != null) {
          RealtimeJobService.updateStatus(profile.id.toString(), 'accepted');
        }
      } catch (fe) {
        debugPrint('⚠️ Optimistic Firestore update failed: $fe');
      }

      // Step 3: Pop the incoming-request screen, returning true to dashboard IMMEDIATELY
      if (mounted) context.pop(true);

      // Step 4: Fire the backend API in the background (no await)
      ProfessionalApiService.acceptBooking(bookingId).then((response) {
        debugPrint('📡 Background Accept API response → success:${response['success']} message:${response['message']}');
        
        if (response['success'] == true) {
          ProfessionalBooking? confirmedBooking;
          if (response['data'] != null) {
            confirmedBooking = ProfessionalBooking.fromJson(response['data']);
            DashboardController.instance.setActiveJob(confirmedBooking);
            debugPrint('✅ Background accept: controller synced with true remote booking');
          } else {
            // Fallback: refetch active job
            ProfessionalApiService.getActiveJob().then((b) {
               if (b != null) DashboardController.instance.setActiveJob(b);
            });
          }
        }
      }).catchError((e) {
        debugPrint('❌ Background _handleAccept error: $e');
        // Theoretically, if it fails catastrophically, we might want to revert the state.
      });

    } catch (e) {
      debugPrint('❌ _handleAccept setup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accept setup failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isProcessing) return;
    if (mounted) setState(() => _isProcessing = true);

    _vibrationTimer?.cancel();
    _countdownTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.stop();

    try {
      final bookingId = widget.notification['booking_id']?.toString() ?? '';
      await ProfessionalApiService.rejectBooking(bookingId);
      if (mounted) context.pop(false);
    } catch (e) {
      if (mounted) context.pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String clientName = widget.notification['client_name'] ?? 'New Customer';
    final String serviceName = widget.notification['service'] ?? widget.notification['service_name'] ?? 'New Service Request';
    final String location = widget.notification['location'] ?? 'Nearby Location';
    final String earnings = widget.notification['price']?.toString() ?? '850';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Header Info
                Text(
                  'INCOMING REQUEST',
                  style: GoogleFonts.outfit(
                    color: AppTheme.greyText,
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Countdown Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Accept in ${_secondsRemaining}s',
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  width: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse Animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 240 * _pulseController.value,
                            height: 240 * _pulseController.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withValues(alpha: 1 - _pulseController.value),
                            ),
                          );
                        },
                      ),
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  clientName,
                  style: GoogleFonts.outfit(
                    color: AppTheme.accentColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  serviceName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppTheme.greyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Location info
                _buildInfoRow(Icons.location_on, location),
                _buildInfoRow(Icons.account_balance_wallet, 'Potential Earnings: ₹$earnings'),
                
                const Spacer(),
                
                if (_isProcessing)
                  Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                else
                  // Swipe Action UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxDisplacement = (constraints.maxWidth - 70) / 2;
                        final double activeThreshold = maxDisplacement * 0.9;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Track
                            Container(
                              height: 70,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(35),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Icon(Icons.close, color: Colors.redAccent, size: 28),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(Icons.check, color: Colors.greenAccent, size: 28),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Track Text
                            Text(
                              'Swipe to Respond',
                              style: TextStyle(color: AppTheme.greyText.withValues(alpha: 0.5)),
                            ),

                            // Slider Handle
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                if (mounted) {
                                  setState(() {
                                    _swipePosition += details.delta.dx;
                                    _swipePosition = _swipePosition.clamp(-maxDisplacement, maxDisplacement);
                                  });
                                }
                              },
                              onHorizontalDragEnd: (details) {
                                if (_swipePosition > activeThreshold) {
                                  _handleAccept();
                                } else if (_swipePosition < -activeThreshold) {
                                  _handleReject();
                                } else {
                                  if (mounted) {
                                    setState(() {
                                      _swipePosition = 0;
                                    });
                                  }
                                }
                              },
                              child: Transform.translate(
                                offset: Offset(_swipePosition, 0),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2),
                                    ],
                                  ),
                                  child: Icon(
                                    _swipePosition > 20 ? Icons.arrow_forward : (_swipePosition < -20 ? Icons.arrow_back : Icons.arrow_forward),
                                    color: AppTheme.primaryColor,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                
                const SizedBox(height: 20),
                Text(
                  'Swipe Right to Accept • Swipe Left to Reject',
                  style: TextStyle(color: AppTheme.greyText.withValues(alpha: 0.6), fontSize: 12),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 16)),
        ],
      ),
    );
  }
}

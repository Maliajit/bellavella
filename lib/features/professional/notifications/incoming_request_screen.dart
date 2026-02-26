import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';

class IncomingRequestScreen extends StatefulWidget {
  const IncomingRequestScreen({super.key});

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _vibrationTimer;
  double _swipePosition = 0;
  final double _swipeThreshold = 150;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startVibrationLoop();
    _startAudioLoop();
  }

  void _startAudioLoop() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/incoming_call.mp3'));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _startVibrationLoop() async {
    if (await Vibration.hasVibrator() == true) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        Vibration.vibrate(duration: 1000);
      });
      // Initial vibration
      Vibration.vibrate(duration: 1000);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _vibrationTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleAccept() {
    Vibration.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    context.pop(true); // Return true for accepted
  }

  void _handleReject() {
    Vibration.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    context.pop(false); // Return false for rejected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
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
                const SizedBox(height: 20),
                SizedBox(
                  height: 280,
                  width: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse Animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 280 * _pulseController.value,
                            height: 280 * _pulseController.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withValues(alpha: 1 - _pulseController.value),
                            ),
                          );
                        },
                      ),
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Rahul Sharma',
                  style: GoogleFonts.outfit(
                    color: AppTheme.accentColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Signature Deep Tissue Massage',
                  style: GoogleFonts.outfit(
                    color: AppTheme.greyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Location info
                _buildInfoRow(Icons.location_on, 'Ahmedabad, 3.2 km away'),
                _buildInfoRow(Icons.account_balance_wallet, 'Earnings: ₹850'),
                
                const Spacer(),
                
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Icon(Icons.close, color: Colors.redAccent, size: 28),
                                ),
                                Text(
                                  'Swipe to Respond',
                                  style: TextStyle(color: AppTheme.greyText.withValues(alpha: 0.5)),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 20),
                                  child: Icon(Icons.check, color: Colors.greenAccent, size: 28),
                                ),
                              ],
                            ),
                          ),
                          
                          // Slider Handle
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _swipePosition += details.delta.dx;
                                // Clamp position to stay within track
                                _swipePosition = _swipePosition.clamp(-maxDisplacement, maxDisplacement);
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              if (_swipePosition > activeThreshold) {
                                _handleAccept();
                              } else if (_swipePosition < -activeThreshold) {
                                _handleReject();
                              } else {
                                setState(() {
                                  _swipePosition = 0;
                                });
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/services/token_manager.dart';
import '../services/professional_api_service.dart';

class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  bool _isChecking = false;
  bool _hasNavigated = false;
  Timer? _timer;
  int _timerAttempt = 0;

  @override
  void initState() {
    super.initState();
    
    // Initial check
    _checkStatus(showMessage: false);

    // Setup adaptive polling for auto-unlock
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    final interval = _getInterval();
    debugPrint('Starting status poll timer with ${interval}s interval (Attempt: $_timerAttempt)');
    
    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      _checkStatus(showMessage: false);
      _timerAttempt++;
      
      // Adaptive backoff: Adjust frequency after specific attempts
      if (_timerAttempt == 2 || _timerAttempt == 4) {
         _startTimer(); 
      }
    });
  }

  int _getInterval() {
    if (_timerAttempt < 2) return 5;   // First 2 attempts: 5s
    if (_timerAttempt < 4) return 10;  // Next 2 attempts: 10s
    return 15;                         // Thereafter: 15s (Reduce server load)
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkStatus({bool showMessage = true}) async {
    // Request lock to prevent API spam/race conditions
    if (_isChecking || _hasNavigated) return;
    
    if (mounted) setState(() => _isChecking = true);
    try {
      final dynamic root = await ProfessionalApiService.getVerificationStatus();
      debugPrint('FULL API RESPONSE: $root');

      // 🔥 BULLETPROOF SAFE EXTRACTION (Handles data vs root vs double-wrap)
      final Map<String, dynamic> responseData =
          (root is Map && root['data'] is Map)
              ? Map<String, dynamic>.from(root['data'])
              : (root is Map ? Map<String, dynamic>.from(root) : {});

      final String currentStatus = (responseData['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      debugPrint('INNER DATA: $responseData');
      debugPrint('FINAL STATUS USED: $currentStatus');

      if (mounted) {
        if (currentStatus == 'active' && !_hasNavigated) {
          _hasNavigated = true;
          _stopTimer(); // 🔥 IMMEDIATELY stop timer
          context.go(AppRoutes.proDashboard);
          return;
        } else if (currentStatus == 'pending' || currentStatus == 'review') {
          if (!_hasNavigated) {
            _hasNavigated = true;
            _stopTimer();
            context.go(AppRoutes.proVerificationStatus);
            return;
          }
        } else if (showMessage) {
          // Only show message if it was a manual refresh and still suspended
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account is still suspended.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Status check error: $e (Account state unknown)');
      
      // 🛡️ NETWORK RESILIENCE: 
      // Do not show error snackbars during background auto-polling.
      // Only show them if the user manually tapped 'Refresh'.
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection and try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    const String phone = "919876543210"; 
    const String message = "Hello, my professional account is suspended. Please help me resolve this.";
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@bellavella.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Account Suspended - Appeal',
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Account Status',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please contact support to appeal your suspension.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppTheme.greyText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        'Reason: Policy Violation',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Action Buttons
              Column(
                children: [
                   _buildPrimaryButton(
                    label: _isChecking ? 'Checking...' : 'Refresh Status',
                    onPressed: _isChecking ? null : () => _checkStatus(showMessage: true),
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildOutlineButton(
                    label: 'Contact Support',
                    onPressed: () {
                      _showSupportOptions(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label, 
    required VoidCallback? onPressed,
    required Color color,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label, 
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade400 : AppTheme.primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color.withOpacity(0.05),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: color,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Support',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSupportTile(
              icon: Icons.chat_bubble_rounded,
              label: 'WhatsApp Support',
              color: const Color(0xFF25D366),
              onTap: () {
                Navigator.pop(context);
                _launchWhatsApp();
              },
            ),
            const SizedBox(height: 12),
            _buildSupportTile(
              icon: Icons.email_rounded,
              label: 'Email Support',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.pop(context);
                _launchEmail();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}

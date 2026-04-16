import 'dart:async';

import 'package:bellavella/core/routes/app_routes.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/controllers/professional_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  bool _isChecking = false;
  Timer? _timer;
  int _timerAttempt = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = _getInterval();
    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      _refreshStatus(showMessage: false);
      _timerAttempt++;
      if (_timerAttempt == 2 || _timerAttempt == 4) {
        _startTimer();
      }
    });
  }

  int _getInterval() {
    if (_timerAttempt < 2) {
      return 5;
    }
    if (_timerAttempt < 4) {
      return 10;
    }
    return 15;
  }

  Future<void> _refreshStatus({required bool showMessage}) async {
    if (_isChecking) {
      return;
    }

    setState(() => _isChecking = true);

    try {
      await context.read<ProfessionalProfileController>().fetchProfile();
      if (!mounted) {
        return;
      }

      final controller = context.read<ProfessionalProfileController>();
      if (!controller.isSuspended && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account restored. Redirecting...')),
        );
      } else if (controller.isSuspended && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account is still suspended.')),
        );
      }
    } catch (_) {
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection and try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _logout() async {
    await context.read<ProfessionalProfileController>().logout();
    if (mounted) {
      context.go(AppRoutes.proLogin);
    }
  }

  Future<void> _launchWhatsApp() async {
    const String phone = '919876543210';
    const String message =
        'Hello, my professional account is suspended. Please help me resolve this.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
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
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalProfileController>(
      builder: (context, controller, _) {
        final String reason = controller.suspensionReason?.trim().isNotEmpty == true
            ? controller.suspensionReason!.trim()
            : 'Policy violation';

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Account Suspended',
                            style: GoogleFonts.outfit(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your professional account is currently suspended. Please contact support to review this status.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppTheme.greyText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Text(
                              'Reason: $reason',
                              textAlign: TextAlign.center,
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
                    Column(
                      children: [
                        _buildPrimaryButton(
                          label: _isChecking ? 'Checking...' : 'Refresh Status',
                          onPressed: _isChecking
                              ? null
                              : () => _refreshStatus(showMessage: true),
                          color: AppTheme.primaryColor,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        _buildOutlineButton(
                          label: 'Contact Support',
                          onPressed: () => _showSupportOptions(context),
                        ),
                        const SizedBox(height: 12),
                        _buildOutlineButton(
                          label: 'Logout',
                          onPressed: _logout,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: color,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Support',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

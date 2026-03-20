import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/services/token_manager.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import '../services/professional_api_service.dart';

class VerificationStatusScreen extends StatefulWidget {
  final String? applicantName;
  const VerificationStatusScreen({super.key, this.applicantName});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  bool _isChecking = false;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final data = await ProfessionalApiService.getVerificationStatus();
      if (mounted) {
        final String verification = (data['verification'] ?? '').toString();
        final String status = (data['status'] ?? '').toString().toLowerCase();

        setState(() {
          _verificationStatus = verification;
        });

        if (status == 'active' && verification == 'Verified') {
          context.go(AppRoutes.proDashboard);
        } else if (status == 'suspended') {
          context.go(AppRoutes.proSuspended);
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to refresh status: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _verificationStatus == 'Rejected';

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
                        isRejected ? Icons.error_outline_rounded : Icons.access_time_rounded,
                        size: 80,
                        color: isRejected ? Colors.red : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.applicantName != null 
                        ? 'Hello, ${widget.applicantName}!' 
                        : 'Hello, Professional!',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRejected ? 'Application Rejected' : 'Application Under Review',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRejected 
                        ? 'Please contact support for more details.' 
                        : 'We’ll notify you once verified.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppTheme.greyText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Text(
                          'This usually takes 24–48 hours.',
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
                    onPressed: _isChecking ? null : _checkStatus,
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
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
}

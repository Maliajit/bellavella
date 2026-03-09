import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/router/route_names.dart';
import '../services/professional_api_service.dart';

class VerificationStatusScreen extends StatefulWidget {
  final String? applicantName;
  const VerificationStatusScreen({super.key, this.applicantName});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  bool _isChecking = false;
  String? _statusMessage;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      final profile = await ProfessionalApiService.getProfile();
      if (mounted) {
        setState(() {
          _verificationStatus = profile.verification;
          _isChecking = false;
        });
        if (profile.verification == 'Verified') {
          context.go(AppRoutes.proDashboard);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _verificationStatus == 'Rejected';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: (isRejected ? Colors.red : AppTheme.secondaryColor).withOpacity(0.3),
                        shape: BoxShape.circle,
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
                        : 'Application Status',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isRejected ? Colors.red : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRejected 
                        ? 'Application Rejected' 
                        : 'Application Under Review',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRejected 
                        ? 'Please contact support for more details.' 
                        : 'We’ll notify you once verified.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (!isRejected)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'This usually takes 24–48 hours.',
                          style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isChecking)
                const CircularProgressIndicator(color: AppTheme.primaryColor)
              else ...[
                PrimaryButton(
                  label: 'Refresh Status',
                  onPressed: _checkStatus,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Logout',
                  onPressed: () async {
                    await TokenManager.clearToken();
                    if (mounted) context.go(AppRoutes.proLogin);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

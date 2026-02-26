import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class VerificationStatusScreen extends StatelessWidget {
  final String? applicantName;
  const VerificationStatusScreen({super.key, this.applicantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        color: AppTheme.secondaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      applicantName != null 
                        ? 'Thanks, $applicantName!' 
                        : 'Application Submitted',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your application is under review',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We’ll notify you soon.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              PrimaryButton(
                label: 'Back to Login',
                onPressed: () => context.go('/professional/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

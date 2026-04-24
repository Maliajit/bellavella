import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/services/auth_flow_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import 'services/auth_api_service.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isButtonEnabled = _phoneController.text.length == 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 100% Height Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.6, 1.0],
                  colors: [
                    Color(0xFFFFD6E7), // Soft pink top
                    Color(0xFFFFF9FB), // Very light pink middle
                    Colors.white,      // White bottom
                  ],
                ),
              ),
            ),
          ),

          // Large Top-Left Circle
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D6F).withValues(alpha: 0.05),
              ),
            ),
          ),

          // Large Bottom-Right Circle
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D6F).withValues(alpha: 0.03),
              ),
            ),
          ),

          // Extra Decorative Shape for full coverage
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D6F).withValues(alpha: 0.02),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Skip Button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20.0, top: 10.0),
                          child: TextButton(
                            onPressed: () async {
                              await AuthFlowService.clearPendingAction();
                              if (!context.mounted) return;
                              context.go('/client/location-picker');
                            },
                            child: Text(
                              'SKIP',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF2D6F),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            // Illustration
                            Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF2D6F).withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Sparkles ring
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFFF2D6F).withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      // White inner circle
                                      Container(
                                        width: 85,
                                        height: 85,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.phone_android_rounded,
                                          size: 40,
                                          color: Color(0xFFFF2D6F),
                                        ),
                                      ),
                                      // Sparkles
                                      Positioned(
                                        top: 10,
                                        right: 15,
                                        child: Icon(Icons.auto_awesome, size: 16, color: const Color(0xFFFF2D6F).withValues(alpha: 0.4)),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        left: 10,
                                        child: Icon(Icons.auto_awesome, size: 12, color: const Color(0xFFFF2D6F).withValues(alpha: 0.3)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),

                            // Text
                            Text(
                              'Enter Your Phone Number',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A1A1A),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "We'll share you a message with an OTP to verify your account.",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 50),

                            // Input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF2D6F).withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFF2D6F)),
                                  hintText: 'Phone Number',
                                  prefixText: '+91 ',
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Legal
                            Text.rich(
                              TextSpan(
                                text: 'By continuing you agree to our ',
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(color: const Color(0xFFFF2D6F), fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: const Color(0xFFFF2D6F), fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.black45, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            // Button
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isButtonEnabled && !_isLoading
                                    ? () async {
                                        setState(() => _isLoading = true);
                                        try {
                                          final response = await AuthApiService.sendOtp(_phoneController.text);
                                          if (response['success'] == true) {
                                            if (!context.mounted) return;
                                            context.push('/client/verify-otp', extra: {
                                              'phone': _phoneController.text.trim(),
                                              'auto_fill_otp': response['data']?['otp']?.toString(),
                                            });
                                          } else {
                                            if (!context.mounted) return;
                                            ToastUtil.showError(context, response['message'] ?? 'Failed to send OTP');
                                          }
                                        } finally {
                                          if (mounted) setState(() => _isLoading = false);
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF2D6F),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        'Continue',
                                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

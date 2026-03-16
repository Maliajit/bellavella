import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/services/notification_service.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../services/professional_api_service.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String? referralCode;
  const OTPVerifyScreen({super.key, required this.phoneNumber, this.referralCode});

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await ProfessionalApiService.verifyOtp(widget.phoneNumber, otp);
      if (mounted) {
        if (response['success'] == true) {
          if (response['data'] != null && response['data']['is_new_user'] == true) {
            context.go('/professional/signup', extra: {
              'phone': widget.phoneNumber,
              'referral_code': widget.referralCode,
            });
          } else {
            // Register FCM token
            await NotificationService().registerFcmToken();
            context.go('/professional/dashboard');
          }
        } else {
          setState(() {
            _errorText = response['message'] ?? 'Incorrect OTP. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E2E2E), size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Verify OTP',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to +91 ${widget.phoneNumber}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2E2E),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (_controllers.every((c) => c.text.isNotEmpty)) {
                        _verifyOTP();
                      }
                    },
                  ),
                );
              }),
            ),
            if (_errorText != null)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    _errorText!,
                    style: GoogleFonts.outfit(
                      color: AppTheme.errorColor, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: _isLoading ? 'Verifying...' : 'Verify & Continue',
              onPressed: _isLoading ? null : _verifyOTP,
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                   Text(
                    "Didn't receive code?", 
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A7A7A),
                      fontWeight: FontWeight.w500,
                    )
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent')),
                      );
                    },
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor, 
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/services/notification_service.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../controllers/professional_profile_controller.dart';
import '../services/professional_api_service.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String? referralCode;
  final String? autoFillOtp;
  const OTPVerifyScreen({super.key, required this.phoneNumber, this.referralCode, this.autoFillOtp});

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  String _appSignature = "";

  @override
  void initState() {
    super.initState();
    _listenOtp();
    _getAppSignature();
    
    // Auto-fill from API response if provided
    if (widget.autoFillOtp != null && widget.autoFillOtp!.isNotEmpty) {
      _otpController.text = widget.autoFillOtp!;
      // Use a small delay to ensure UI is ready before auto-verifying
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) _verifyOTP(widget.autoFillOtp!);
      });
    }
  }

  void _listenOtp() async {
    listenForCode();
  }

  void _getAppSignature() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      debugPrint("🔍 App Signature: $_appSignature");
    } catch (e) {
      debugPrint("⚠️ Failed to get app signature: $e");
    }
  }

  @override
  void codeUpdated() {
    setState(() {
      _otpController.text = code ?? "";
    });
    if (_otpController.text.length == 4) {
      _verifyOTP(_otpController.text);
    }
  }

  @override
  void dispose() {
    cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP(String otp) async {
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
            await NotificationService().registerFcmToken();
            await context.read<ProfessionalProfileController>().fetchProfile();
            if (!mounted) {
              return;
            }

            final controller = context.read<ProfessionalProfileController>();
            if (controller.isSuspended) {
              context.go('/professional/suspended');
            } else {
              context.go('/professional/dashboard');
            }
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
    final defaultPinTheme = PinTheme(
      width: 70,
      height: 70,
      textStyle: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2E2E2E),
      ),
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
    );

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
            
            Center(
              child: Pinput(
                length: 4,
                controller: _otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                onCompleted: _verifyOTP,
                autofocus: true,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),
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
              onPressed: _isLoading ? null : () => _verifyOTP(_otpController.text),
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
                      _otpController.clear();
                      _listenOtp();
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
                  if (_appSignature.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "App Hash: $_appSignature",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

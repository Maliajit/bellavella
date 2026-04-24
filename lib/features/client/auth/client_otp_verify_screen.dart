import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:bellavella/core/services/auth_flow_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/cart/controllers/cart_provider.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/services/token_manager.dart';
import 'services/auth_api_service.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class ClientOTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  final String? autoFillOtp;

  const ClientOTPVerifyScreen({
    super.key,
    required this.phoneNumber,
    this.autoFillOtp,
  });

  @override
  State<ClientOTPVerifyScreen> createState() => _ClientOTPVerifyScreenState();
}

class _ClientOTPVerifyScreenState extends State<ClientOTPVerifyScreen>
    with CodeAutoFill {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final _referralController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  String _appSignature = '';

  @override
  void initState() {
    super.initState();
    _listenOtp();
    _getAppSignature();

    if (widget.autoFillOtp != null && widget.autoFillOtp!.isNotEmpty) {
      _applyOtp(widget.autoFillOtp!);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _verifyOTP();
        }
      });
    }
  }

  void _listenOtp() {
    listenForCode();
  }

  Future<void> _getAppSignature() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      debugPrint('Client OTP App Signature: $_appSignature');
    } catch (e) {
      debugPrint('Failed to get client OTP app signature: $e');
    }
  }

  void _applyOtp(String otp) {
    final digits = otp.replaceAll(RegExp(r'[^0-9]'), '');
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
  }

  @override
  void codeUpdated() {
    final incomingCode = code ?? '';
    _applyOtp(incomingCode);
    if (incomingCode.replaceAll(RegExp(r'[^0-9]'), '').length >= 4) {
      _verifyOTP();
    }
  }

  @override
  void dispose() {
    cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _referralController.dispose();
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
      final response = await AuthApiService.verifyOtp(
        widget.phoneNumber, 
        otp, 
        referralCode: _referralController.text.isNotEmpty ? _referralController.text : null,
      );

      if (response['success'] == true) {
        // service already stored token if provided, so just navigate
        final int coins = response['coins_awarded'] ?? 0;
        if (coins > 0 && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded, color: AppTheme.primaryColor, size: 64),
                  const SizedBox(height: 16),
                  Text('Congratulations!', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('You\'ve received $coins welcome coins!', 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Awesome!', 
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
        if (!mounted) return;
        await context.read<CartProvider>().fetchCart();
        if (!mounted) return;
        if (TokenManager.hasLocation) {
          await AuthFlowService.continueAfterClientAuth(context);
        } else {
          context.go('/client/location-picker');
        }
      } else {
        setState(() {
          _errorText =
              response['message'] ?? 'Incorrect OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Network error. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthApiService.sendOtp(widget.phoneNumber);
      if (!context.mounted) return;

      if (response['success'] == true) {
        final autoFillOtp = response['data']?['otp']?.toString();
        if (autoFillOtp != null && autoFillOtp.isNotEmpty) {
          _applyOtp(autoFillOtp);
          _verifyOTP();
          return;
        }

        if (!mounted) return;
        ToastUtil.showSuccess(context, response['message'] ?? 'OTP resent successfully');
      } else {
        if (!mounted) return;
        ToastUtil.showError(context, response['message'] ?? 'Failed to resend OTP');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

          // Extra Decorative Shape
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
                      // Back Button
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFF2D6F), size: 22),
                          onPressed: () => context.pop(),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
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
                                          Icons.mark_email_read_rounded,
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
                            const SizedBox(height: 50),

                            // Text
                            Text(
                              'Verify Your Account',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A1A1A),
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We sent a code to +91 ${widget.phoneNumber}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // OTP Boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (index) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFFF2D6F).withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    autofocus: index == 0,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFF2D6F),
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
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
                                padding: const EdgeInsets.only(top: 16),
                                child: Center(
                                  child: Text(
                                    _errorText!,
                                    style: GoogleFonts.inter(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 40),

                            // Referral Code
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF2D6F).withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _referralController,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  labelText: 'Referral Code (Optional)',
                                  labelStyle: GoogleFonts.inter(color: Colors.black38),
                                  hintText: 'Enter code if any',
                                  prefixIcon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF2D6F)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
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
                                onPressed: _isLoading ? null : _verifyOTP,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF2D6F),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(
                                        'Verify & Continue',
                                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Resend Section
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Didn't receive code?",
                                    style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading ? null : _resendOTP,
                                    child: Text(
                                      'Resend OTP',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF2D6F),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
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

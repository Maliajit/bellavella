import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verify OTP',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a code to +91 ${widget.phoneNumber}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
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
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _referralController,
              decoration: InputDecoration(
                labelText: 'Referral Code (Optional)',
                hintText: 'Enter code if any',
                prefixIcon: const Icon(Icons.card_giftcard_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Verify & Continue',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _verifyOTP,
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text(
                    "Didn't receive code?",
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resendOTP,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_appSignature.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'App Hash: $_appSignature',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class ClientOTPVerifyScreen extends StatefulWidget {
  final String phoneNumber;
  const ClientOTPVerifyScreen({super.key, required this.phoneNumber});

  @override
  State<ClientOTPVerifyScreen> createState() => _ClientOTPVerifyScreenState();
}

class _ClientOTPVerifyScreenState extends State<ClientOTPVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String? _errorText;

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

  void _verifyOTP() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp == '1234') {
      setState(() => _errorText = null);
      // Success - Navigate to location picker
      context.go('/client/location-picker');
    } else {
      setState(() => _errorText = 'Incorrect OTP. Please try again.');
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
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 28),
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
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
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
                  style:
                      const TextStyle(color: AppTheme.errorColor, fontSize: 14),
                ),
              ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Verify & Continue',
              onPressed: _verifyOTP,
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text("Didn't receive code?",
                      style: TextStyle(color: AppTheme.greyText)),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent')),
                      );
                    },
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold),
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

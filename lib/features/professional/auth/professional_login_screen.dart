import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class ProfessionalLoginScreen extends StatefulWidget {
  const ProfessionalLoginScreen({super.key});

  @override
  State<ProfessionalLoginScreen> createState() => _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends State<ProfessionalLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }



  bool get _isContinueEnabled {
    return _phoneController.text.length == 10 && 
           RegExp(r'^[0-9]+$').hasMatch(_phoneController.text) &&
           _isAgreed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Professional',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              'Login with your phone number',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: 'Phone Number',
                prefixText: '+91 ',
                counterText: '',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (value) => setState(() => _isAgreed = value ?? false),
                  activeColor: AppTheme.primaryColor,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAgreed = !_isAgreed),
                    child: const Text('I agree to Terms & Conditions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Continue',
              onPressed: _isContinueEnabled
                  ? () => context.push('/professional/verify-otp',
                      extra: _phoneController.text)
                  : null,
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => context.push('/professional/signup'),
                child: const Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: AppTheme.greyText),
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

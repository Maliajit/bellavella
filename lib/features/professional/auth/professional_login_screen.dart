import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../services/professional_api_service.dart';

class ProfessionalLoginScreen extends StatefulWidget {
  const ProfessionalLoginScreen({super.key});

  @override
  State<ProfessionalLoginScreen> createState() => _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends State<ProfessionalLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isAgreed = false;
  bool _isLoading = false;
  bool _showReferral = false;

  Future<void> _sendOtp() async {
    if (!_isContinueEnabled) return;

    setState(() => _isLoading = true);

    try {
      final res = await ProfessionalApiService.sendOtp(_phoneController.text);
      if (mounted) {
        if (res['success'] == true) {
          context.push(
            '/professional/verify-otp',
            extra: {
              'phone': _phoneController.text.trim(),
              'referral_code': _referralController.text.trim(),
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to send OTP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
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
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Welcome,\nProfessional',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E2E2E),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Login with your phone number to continue your journey.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 60),
            
            // Phone Input
            Container(
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E2E2E),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 22),
                  hintText: 'Phone Number',
                  prefixText: '+91 ',
                  prefixStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2E2E),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Agreement Checkbox
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: const Color(0xFF555555),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      onChanged: (value) => setState(() => _isAgreed = value ?? false),
                      activeColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      side: const BorderSide(color: Color(0xFF555555), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAgreed = !_isAgreed),
                      child: Text(
                        'I agree to Terms & Conditions',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            PrimaryButton(
              label: _isLoading ? 'Sending...' : 'Continue',
              onPressed: _isContinueEnabled && !_isLoading ? _sendOtp : null,
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showReferral = !_showReferral;
                  });
                },
                child: Text(
                  _showReferral ? 'Hide referral code' : 'Have a referral code?',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showReferral ? 1.0 : 0.0,
                child: _showReferral ? Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
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
                        controller: _referralController,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E2E2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Referral Code (Optional)',
                          hintStyle: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFFA0A0A0),
                          ),
                          prefixIcon: const Icon(Icons.card_giftcard, size: 20, color: Color(0xFF7A7A7A)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ) : const SizedBox.shrink(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

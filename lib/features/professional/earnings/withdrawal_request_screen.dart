import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:bellavella/features/professional/models/professional_models.dart' as pro_models;
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  State<WithdrawalRequestScreen> createState() => _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  
  pro_models.ProfessionalWallet? _wallet;
  Professional? _profile;

  final TextEditingController _amountCtrl = TextEditingController();
  double? _amount;
  String _selectedMethod = 'bank'; // 'bank' or 'upi'

  // Design tokens
  static const Color _primary = Color(0xFFFF4D7D); 
  static const Color _green = Color(0xFF22C55E); 
  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final wallet = await ProfessionalApiService.getWallet(tab: 'earnings');
      final profile = await ProfessionalApiService.getProfile();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _available => _wallet?.earningsBalance ?? 0.0;
  bool get _hasBank => _profile?.payout.accountNumber.isNotEmpty ?? false;
  bool get _hasUpi => _profile?.payout.upiId.isNotEmpty ?? false;

  void _submitRequest() async {
    if (_amount == null || _amount! < 500 || _amount! > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be between ₹500 and ₹50,000'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_amount! > _available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds available balance'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedMethod == 'bank' && !_hasBank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add bank details in Profile first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedMethod == 'upi' && !_hasUpi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add UPI details in Profile first'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ProfessionalApiService.requestWithdrawal(_amount!, _selectedMethod);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted successfully!'), backgroundColor: _green),
        );
        // Refresh wallet and navigate back
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text('Withdraw Funds', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => context.pushNamed(AppRoutes.proWithdrawalHistoryName),
              child: Text('History', style: GoogleFonts.outfit(color: _primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 64),
        const SizedBox(height: 16),
        Text('Failed to load wallet', style: GoogleFonts.outfit(fontSize: 16, color: _textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _fetchData, 
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          child: const Text('Retry'),
        ),
      ]
    )
  );

  Widget _buildContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C1B3A), Color(0xFF2D1F5E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF1C1B3A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available for Withdrawal', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('₹${_available.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Amount Input
              Text('Amount to Withdraw', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) => setState(() => _amount = double.tryParse(val)),
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: _textPrimary),
                  hintText: '0',
                  hintStyle: GoogleFonts.outfit(fontSize: 24, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primary, width: 2)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Min: ₹500  •  Max: ₹50,000', style: GoogleFonts.outfit(fontSize: 12, color: _textSecondary)),
                  if (_amount != null && _amount! > _available)
                    Text('Exceeds balance', style: GoogleFonts.outfit(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
              
              const SizedBox(height: 30),

              // Method Selection
              Text('Withdrawal Method', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 12),
              
              _buildMethodCard(
                'bank', 
                Icons.account_balance_rounded, 
                'Bank Transfer', 
                _hasBank ? '****${_profile!.payout.accountNumber.length > 4 ? _profile!.payout.accountNumber.substring(_profile!.payout.accountNumber.length - 4) : _profile!.payout.accountNumber}' : 'Not Added',
                _hasBank
              ),
              const SizedBox(height: 12),
              _buildMethodCard(
                'upi', 
                Icons.qr_code_2_rounded, 
                'UPI Transfer', 
                _hasUpi ? _profile!.payout.upiId : 'Not Added',
                _hasUpi
              ),

              const SizedBox(height: 120), // Padding for bottom button
            ],
          ),
        ),

        // Floating Action Button Area
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_amount != null && _amount! >= 500 && _amount! <= 50000 && _amount! <= _available && !_isSubmitting) 
                  ? _submitRequest 
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Request Withdrawal', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard(String id, IconData icon, String title, String subtitle, bool isAvailable) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          setState(() => _selectedMethod = id);
        } else {
          // Navigate to add details
          if (id == 'bank') context.pushNamed(AppRoutes.proEditBankDetailsName).then((_) => _fetchData());
          if (id == 'upi') context.pushNamed(AppRoutes.proEditUPIDetailsName).then((_) => _fetchData());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? _primary.withOpacity(0.1) : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? _primary : Colors.grey.shade400, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: isAvailable ? _textSecondary : Colors.red.shade400)),
                ],
              ),
            ),
            if (isAvailable) 
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? _primary : Colors.grey.shade300, width: 2),
                  color: isSelected ? _primary : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              )
            else
              Text('Add', style: GoogleFonts.outfit(color: _primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

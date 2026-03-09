import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderController;
  late TextEditingController _accountController;
  late TextEditingController _confirmAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;

  String? _selectedBank;
  final List<String> _banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'Yes Bank',
    'IDFC First Bank',
    'Other'
  ];

  XFile? _proofImage;
  bool _isVerified = false;
  String? _existingProofUrl;

  @override
  void initState() {
    super.initState();
    final payout = context.read<ProfessionalProfileController>().profile?.payout;
    
    _holderController = TextEditingController(text: payout?.accountHolder);
    
    String? existingBank = payout?.bankName;
    if (existingBank != null && existingBank.isNotEmpty) {
      if (_banks.contains(existingBank)) {
        _selectedBank = existingBank;
      } else {
        _banks.insert(0, existingBank);
        _selectedBank = existingBank;
      }
    }

    _accountController = TextEditingController(text: payout?.accountNumber);
    _confirmAccountController = TextEditingController(text: payout?.accountNumber);
    _ifscController = TextEditingController(text: payout?.ifsc);
    _branchController = TextEditingController(text: payout?.branch);
    _isVerified = payout?.verificationStatus == 'Verified';
    _existingProofUrl = payout?.bankProofImage;
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isVerified) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _proofImage = image;
      });
    }
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) return 'Please enter IFSC code';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) {
      return 'Enter a valid 11-character IFSC code';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isVerified) return;
    if (_formKey.currentState!.validate()) {
      if (_accountController.text != _confirmAccountController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account numbers do not match')),
        );
        return;
      }
      
      if (_selectedBank == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a bank')),
        );
        return;
      }

      final success = await context.read<ProfessionalProfileController>().updateBankDetails({
        'account_holder': _holderController.text,
        'bank_name': _selectedBank!,
        'account_number': _accountController.text,
        'ifsc': _ifscController.text,
        'branch': _branchController.text,
      }, proofImage: _proofImage);
      
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details updated and pending verification!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft fintech background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bank Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
        ),
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          final status = controller.profile?.payout.verificationStatus ?? 'Pending';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add your bank account to receive payouts and withdrawals.",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  if (_isVerified)
                    _buildStatusBanner(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      text: "Your bank details are verified and cannot be edited.",
                    )
                  else if (status != 'Pending')
                    _buildStatusBanner(
                      icon: Icons.info_outline,
                      color: Colors.orange,
                      text: "Status: $status. Review pending.",
                    ),

                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField("Account Holder Name", _holderController, Icons.person_outline),
                        const SizedBox(height: 20),
                        
                        _buildDropdownField("Bank Name", Icons.account_balance_outlined),
                        const SizedBox(height: 20),
                        
                        _buildTextField("Account Number", _accountController, Icons.numbers_outlined, keyboardType: TextInputType.number, obscureText: true),
                        const SizedBox(height: 20),
                        
                        _buildTextField("Confirm Account Number", _confirmAccountController, Icons.numbers_outlined, keyboardType: TextInputType.number),
                        const SizedBox(height: 20),
                        
                        _buildTextField("IFSC Code", _ifscController, Icons.code_rounded, isUppercase: true, validator: _validateIFSC),
                        const SizedBox(height: 20),
                        
                        _buildTextField("Branch Name (Optional)", _branchController, Icons.location_on_outlined, isRequired: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Verification Section
                  Text(
                    "Bank Verification",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload Cancelled Cheque or Bank Passbook",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: _buildImagePreview(),
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  if (!_isVerified)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: controller.isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: controller.isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : Text('Save Bank Details', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner({required IconData icon, required MaterialColor color, required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.shade50, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.inter(color: color.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBank,
          items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: _isVerified ? null : (val) {
            setState(() => _selectedBank = val);
          },
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: _isVerified ? Colors.grey.shade400 : AppTheme.primaryColor.withValues(alpha: 0.7)),
            filled: true,
            fillColor: _isVerified ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v == null ? 'Please select a bank' : null,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_proofImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: kIsWeb
            ? Image.network(_proofImage!.path, fit: BoxFit.cover)
            : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
      );
    } else if (_existingProofUrl != null && _existingProofUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(_existingProofUrl!, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.cloud_upload_rounded, size: 32, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 12),
        Text("Tap to upload document", style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text("JPG, PNG or PDF (Max 5MB)", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    {
      TextInputType? keyboardType, 
      bool isRequired = true, 
      bool obscureText = false,
      bool isUppercase = false,
      String? Function(String?)? validator
    }
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            if (isRequired) const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: !_isVerified,
          textCapitalization: isUppercase ? TextCapitalization.characters : TextCapitalization.none,
          style: GoogleFonts.inter(fontSize: 14, color: _isVerified ? Colors.grey.shade700 : Colors.black87, fontWeight: FontWeight.w500),
          onChanged: isUppercase && !_isVerified ? (val) {
            controller.value = controller.value.copyWith(text: val.toUpperCase());
          } : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: _isVerified ? Colors.grey.shade400 : AppTheme.primaryColor.withValues(alpha: 0.7)),
            filled: true,
            fillColor: _isVerified ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: const TextStyle(height: 1),
          ),
          validator: validator ?? (v) => isRequired && (v == null || v.isEmpty) ? 'Please enter $label' : null,
        ),
      ],
    );
  }
}

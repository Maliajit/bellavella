import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Tab/Mode
  bool _isUpiMode = false;

  // Bank Controllers
  late TextEditingController _holderController;
  late TextEditingController _accountController;
  late TextEditingController _confirmAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;

  // UPI Controllers
  late TextEditingController _upiController;

  String? _selectedBank;
  final List<String> _banks = [
    'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank',
    'Kotak Mahindra Bank', 'Punjab National Bank', 'Bank of Baroda',
    'Canara Bank', 'Union Bank of India', 'IndusInd Bank', 'Yes Bank',
    'IDFC First Bank', 'Other'
  ];

  final List<String> _upiSuggestions = ['oksbi', 'okaxis', 'ybl', 'paytm', 'ibl', 'upi'];

  XFile? _proofImage;
  bool _isVerified = false;
  String? _existingBankProofUrl;
  String? _existingUpiScreenshotUrl;

  @override
  void initState() {
    super.initState();
    final payout = context.read<ProfessionalProfileController>().profile?.payout;
    
    // Bank Init
    _holderController = TextEditingController(text: payout?.accountHolder);
    _accountController = TextEditingController(text: payout?.accountNumber);
    _confirmAccountController = TextEditingController(text: payout?.accountNumber);
    _ifscController = TextEditingController(text: payout?.ifsc);
    _branchController = TextEditingController(text: payout?.branch);
    _existingBankProofUrl = payout?.bankProofImage;

    // UPI Init
    _upiController = TextEditingController(text: payout?.upiId);
    _existingUpiScreenshotUrl = payout?.upiScreenshot;

    // State Init
    _isVerified = payout?.verificationStatus == 'Verified';
    
    // Default to UPI if bank is empty and UPI is there
    if ((payout?.accountNumber == null || payout?.accountNumber?.isEmpty == true) && 
        (payout?.upiId != null && payout?.upiId?.isNotEmpty == true)) {
      _isUpiMode = true;
    }

    String? existingBank = payout?.bankName;
    if (existingBank != null && existingBank.isNotEmpty) {
      if (_banks.contains(existingBank)) {
        _selectedBank = existingBank;
      } else {
        _banks.insert(0, existingBank);
        _selectedBank = existingBank;
      }
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isVerified) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _proofImage = image);
    }
  }

  void _applyUpiSuggestion(String handle) {
    if (_isVerified) return;
    String currentText = _upiController.text;
    if (currentText.contains('@')) {
      _upiController.text = "${currentText.split('@')[0]}@$handle";
    } else {
      _upiController.text = "$currentText@$handle";
    }
    _upiController.selection = TextSelection.fromPosition(TextPosition(offset: _upiController.text.length));
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) return 'Please enter IFSC code';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) return 'Invalid IFSC code';
    return null;
  }

  String? _validateUpi(String? value) {
    if (value == null || value.isEmpty) return "Enter UPI ID";
    if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]+$').hasMatch(value)) return "Invalid UPI ID";
    return null;
  }

  Future<bool> _save() async {
    if (_isVerified) return false;
    if (!_formKey.currentState!.validate()) return false;

    final controller = context.read<ProfessionalProfileController>();
    bool success = false;

    if (_isUpiMode) {
      success = await controller.updateUPIDetails({
        'upi_id': _upiController.text,
      }, screenshot: _proofImage);
    } else {
      if (_accountController.text != _confirmAccountController.text) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account numbers do not match')));
        return false;
      }
      if (_selectedBank == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank')));
        return false;
      }

      success = await controller.updateBankDetails({
        'account_holder': _holderController.text,
        'bank_name': _selectedBank!,
        'account_number': _accountController.text,
        'ifsc': _ifscController.text,
        'branch': _branchController.text,
      }, proofImage: _proofImage);
    }

    if (success && mounted) {
      context.pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_isUpiMode ? "UPI" : "Bank"} details updated and pending verification!')),
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Payment Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          final payout = controller.profile?.payout;
          final status = payout?.verificationStatus ?? 'Pending';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Banner
                  if (_isVerified)
                    _buildStatusBanner(Icons.check_circle, Colors.green, "Your details are verified and cannot be edited.")
                  else if (status != 'Pending' && status != 'Not Applied')
                    _buildStatusBanner(Icons.info_outline, Colors.orange, "Status: $status. Review pending."),

                  // Mode Toggle
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(child: _buildToggleItem("Bank Account", !_isUpiMode, () => setState(() => _isUpiMode = false))),
                        Expanded(child: _buildToggleItem("UPI ID", _isUpiMode, () => setState(() => _isUpiMode = true))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Forms Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _isUpiMode ? _buildUpiForm() : _buildBankForm(),
                  ),

                  const SizedBox(height: 32),
                  
                  // Image Upload Section
                  Text(_isUpiMode ? "UPI Screenshot" : "Bank Verification", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_isUpiMode ? "Upload QR or UPI ID screenshot" : "Upload Cancelled Cheque or Passbook", style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  
                  _buildImageUploadArea(),

                  const SizedBox(height: 40),
                  
                  if (!_isVerified)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: controller.isLoading 
                            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))) 
                            : Text('Save Details', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBankForm() {
    return Column(
      children: [
        _buildTextField("Account Holder Name", _holderController, Icons.person_outline),
        _buildDropdownField("Bank Name", Icons.account_balance_outlined),
        _buildTextField("Account Number", _accountController, Icons.numbers_outlined, keyboardType: TextInputType.number, obscureText: true),
        _buildTextField("Confirm Account Number", _confirmAccountController, Icons.numbers_outlined, keyboardType: TextInputType.number),
        _buildTextField("IFSC Code", _ifscController, Icons.code_rounded, isUppercase: true, validator: _validateIFSC),
        _buildTextField("Branch (Optional)", _branchController, Icons.location_on_outlined, isRequired: false),
      ],
    );
  }

  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("UPI ID", _upiController, Icons.alternate_email_rounded, hint: "example@upi", validator: _validateUpi),
        if (!_isVerified) ...[
          const SizedBox(height: 8),
          Text("Suggestions:", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _upiSuggestions.map((e) => ActionChip(
              label: Text(e, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              onPressed: () => _applyUpiSuggestion(e),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUploadArea() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: _buildImagePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    final existingUrl = _isUpiMode ? _existingUpiScreenshotUrl : _existingBankProofUrl;
    if (_proofImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: kIsWeb ? Image.network(_proofImage!.path, fit: BoxFit.cover) : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
      );
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(existingUrl, fit: BoxFit.cover));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_rounded, size: 32, color: AppTheme.primaryColor),
        const SizedBox(height: 12),
        Text("Tap to upload document", style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusBanner(IconData icon, MaterialColor color, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade200)),
      child: Row(children: [
        Icon(icon, color: color.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.inter(color: color.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, bool isRequired = true, bool obscureText = false, bool isUppercase = false, String? hint, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: !_isVerified,
            textCapitalization: isUppercase ? TextCapitalization.characters : TextCapitalization.none,
            style: GoogleFonts.inter(fontSize: 14, color: _isVerified ? Colors.grey.shade700 : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
              hintText: hint,
              filled: true, fillColor: _isVerified ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            ),
            validator: validator ?? (v) => isRequired && (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBank,
            items: _banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: _isVerified ? null : (val) => setState(() => _selectedBank = val),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
              filled: true, fillColor: _isVerified ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderController;
  late TextEditingController _bankController;
  late TextEditingController _accountController;
  late TextEditingController _ifscController;
  late TextEditingController _branchController;

  @override
  void initState() {
    super.initState();
    final payout = context.read<ProfessionalProfileController>().profile?.payout;
    _holderController = TextEditingController(text: payout?.accountHolder);
    _bankController = TextEditingController(text: payout?.bankName);
    _accountController = TextEditingController(text: payout?.accountNumber);
    _ifscController = TextEditingController(text: payout?.ifsc);
    _branchController = TextEditingController(text: payout?.branch);
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateBankDetails({
        'account_holder': _holderController.text,
        'bank_name': _bankController.text,
        'account_number': _accountController.text,
        'ifsc': _ifscController.text,
        'branch': _branchController.text,
      });
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Bank Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField("Account Holder Name", _holderController, Icons.person_outlined),
                  const SizedBox(height: 20),
                  _buildTextField("Bank Name", _bankController, Icons.account_balance_outlined),
                  const SizedBox(height: 20),
                  _buildTextField("Account Number", _accountController, Icons.numbers_outlined, keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  _buildTextField("IFSC Code", _ifscController, Icons.code),
                  const SizedBox(height: 20),
                  _buildTextField("Branch Name", _branchController, Icons.location_on_outlined),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: controller.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Details', style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        ),
      ],
    );
  }
}

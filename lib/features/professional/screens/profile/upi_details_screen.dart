import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class UPIDetailsScreen extends StatefulWidget {
  const UPIDetailsScreen({super.key});

  @override
  State<UPIDetailsScreen> createState() => _UPIDetailsScreenState();
}

class _UPIDetailsScreenState extends State<UPIDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    final payout = context.read<ProfessionalProfileController>().profile?.payout;
    _upiController = TextEditingController(text: payout?.upiId);
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateUPIDetails({
        'upi_id': _upiController.text,
      });
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI details updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('UPI Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   _buildTextField("UPI ID", _upiController, Icons.alternate_email_rounded),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                     child: Row(
                       children: [
                         Icon(Icons.info_outline, color: Colors.orange.shade800, size: 18),
                         const SizedBox(width: 12),
                         Expanded(child: Text("Make sure your UPI ID is correct for instant payouts.", style: TextStyle(color: Colors.orange.shade800, fontSize: 12))),
                       ],
                     ),
                   ),
                   const SizedBox(height: 48),
                   SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: controller.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save UPI ID', style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: "example@upi",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Please enter UPI ID' : null,
        ),
      ],
    );
  }
}

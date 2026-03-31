import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class EditContactDetailsScreen extends StatefulWidget {
  const EditContactDetailsScreen({super.key});

  @override
  State<EditContactDetailsScreen> createState() => _EditContactDetailsScreenState();
}

class _EditContactDetailsScreenState extends State<EditContactDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfessionalProfileController>().profile;
    _phoneController = TextEditingController(text: profile?.phone);
    _emailController = TextEditingController(text: profile?.email);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateProfile({
        'phone': _phoneController.text,
        'email': _emailController.text,
      });
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact details updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Contact Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          return Padding(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   _buildTextField("Mobile Number", _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone, readOnly: true),
                   const SizedBox(height: 20),
                   _buildTextField("Email Address", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress, readOnly: true),
                   const SizedBox(height: 16),
                   Text(
                     "Contact support to change your registered mobile number or email address.",
                     textAlign: TextAlign.center,
                     style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey.shade700 : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: readOnly ? Colors.grey.shade500 : Colors.black87),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        ),
      ],
    );
  }
}

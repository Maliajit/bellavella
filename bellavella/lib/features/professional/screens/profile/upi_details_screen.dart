import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class UPIDetailsScreen extends StatefulWidget {
  const UPIDetailsScreen({super.key});

  @override
  State<UPIDetailsScreen> createState() => _UPIDetailsScreenState();
}

class _UPIDetailsScreenState extends State<UPIDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _upiController;

  XFile? _proofImage;
  bool _isVerified = false;
  String? _existingProofUrl;

  final List<String> _upiSuggestions = [
    'oksbi', 'okaxis', 'ybl', 'paytm', 'ibl', 'upi'
  ];

  @override
  void initState() {
    super.initState();
    final payout = context.read<ProfessionalProfileController>().profile?.payout;
    _upiController = TextEditingController(text: payout?.upiId);
    _isVerified = payout?.verificationStatus == 'Verified';
    _existingProofUrl = payout?.upiScreenshot;
  }

  @override
  void dispose() {
    _upiController.dispose();
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

  void _applySuggestion(String handle) {
    if (_isVerified) return;
    String currentText = _upiController.text;
    String newText;
    if (currentText.contains('@')) {
      newText = currentText.split('@')[0] + '@' + handle;
    } else {
      newText = currentText + '@' + handle;
    }
    _upiController.text = newText;
    // Move cursor to the end
    _upiController.selection = TextSelection.fromPosition(TextPosition(offset: _upiController.text.length));
  }

  String? _validateUpi(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter UPI ID";
    }
    RegExp regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z]+$');
    if (!regex.hasMatch(value)) {
      return "Enter valid UPI ID (e.g., example@upi)";
    }
    return null;
  }

  Future<void> _save() async {
    if (_isVerified) return;
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateUPIDetails({
        'upi_id': _upiController.text,
      }, screenshot: _proofImage);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI details updated and pending verification!')),
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
          final status = controller.profile?.payout.verificationStatus ?? 'Pending';
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isVerified)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text("Your UPI details are verified and cannot be edited.", style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    )
                  else if (status != 'Pending')
                     Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text("Status: $status", style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),

                   _buildTextField("UPI ID", _upiController, Icons.alternate_email_rounded),
                   const SizedBox(height: 12),
                   if (!_isVerified) ...[
                     Text("Suggestions:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: _upiSuggestions.map((e) => ActionChip(
                         label: Text(e, style: const TextStyle(fontSize: 12)),
                         backgroundColor: Colors.white,
                         side: BorderSide(color: Colors.grey.shade300),
                         onPressed: () => _applySuggestion(e),
                       )).toList(),
                     ),
                     const SizedBox(height: 16),
                   ],

                   const SizedBox(height: 12),
                   Text("Upload Screenshot (Optional)", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                   const SizedBox(height: 8),
                   Text("Upload UPI screenshot from the app (GPay, PhonePe, Paytm)", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                   const SizedBox(height: 12),
                   InkWell(
                     onTap: _pickImage,
                     borderRadius: BorderRadius.circular(12),
                     child: Container(
                       width: double.infinity,
                       height: 160,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.grey.shade300, width: 1),
                       ),
                       child: _buildImagePreview(),
                     ),
                   ),

                   const SizedBox(height: 48),
                   if (!_isVerified)
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

  Widget _buildImagePreview() {
    if (_proofImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(_proofImage!.path, fit: BoxFit.cover)
            : Image.file(File(_proofImage!.path), fit: BoxFit.cover),
      );
    } else if (_existingProofUrl != null && _existingProofUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_existingProofUrl!, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text("Upload Screenshot", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !_isVerified,
          style: TextStyle(fontSize: 14, color: _isVerified ? Colors.grey.shade700 : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: _isVerified ? Colors.grey.shade400 : Colors.grey.shade600),
            hintText: "example@upi",
            filled: true,
            fillColor: _isVerified ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryColor)),
          ),
          validator: _validateUpi,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class EditPersonalInformationScreen extends StatefulWidget {
  const EditPersonalInformationScreen({super.key});

  @override
  State<EditPersonalInformationScreen> createState() => _EditPersonalInformationScreenState();
}

class _EditPersonalInformationScreenState extends State<EditPersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _selectedGender;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfessionalProfileController>().profile;
    _nameController = TextEditingController(text: profile?.name);
    _bioController = TextEditingController(text: profile?.bio);
    _selectedGender = profile?.gender;
    if (profile?.dob != null) {
      _selectedDob = DateTime.tryParse(profile!.dob!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateProfile({
        'name': _nameController.text,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'dob': _selectedDob?.toIso8601String().split('T').first,
      });

      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Personal Information', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildTextField("Full Name", _nameController, Icons.person_outlined, readOnly: true),
                   const SizedBox(height: 20),
                   _buildGenderPicker(),
                   const SizedBox(height: 20),
                   _buildDatePicker(),
                   const SizedBox(height: 20),
                   _buildTextField("Bio / About Me", _bioController, Icons.description_outlined, maxLines: 4, readOnly: true),
                   const SizedBox(height: 20),
                   Text(
                     "Contact support to update your personal information.",
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey.shade700 : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: readOnly ? Colors.grey.shade500 : Colors.black87),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: readOnly ? Colors.transparent : AppTheme.primaryColor)),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gender", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = _selectedGender == g;
            return Padding(
              padding: EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(g),
                selected: isSelected,
                onSelected: null, // Disabled
                disabledColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100), side: BorderSide(color: Colors.transparent)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date of Birth", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                _selectedDob == null ? 'Not specified' : _selectedDob!.toIso8601String().split('T').first, 
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700)
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}

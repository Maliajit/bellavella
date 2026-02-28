import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class ProfessionalSignupScreen extends StatefulWidget {
  const ProfessionalSignupScreen({super.key});

  @override
  State<ProfessionalSignupScreen> createState() => _ProfessionalSignupScreenState();
}

class _ProfessionalSignupScreenState extends State<ProfessionalSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Section A Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  
  // Section B Data
  final List<String> _allSkills = ['Facial', 'Waxing', 'Makeup', 'Hair Styling', 'Manicure', 'Pedicure', 'Massage'];
  final List<String> _selectedSkills = [];
  String? _selectedExperience;
  final List<String> _allLanguages = ['Gujarati', 'Hindi', 'English', 'Marathi', 'Punjabi'];
  final List<String> _selectedLanguages = [];
  
  // Section C Controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedState;

  // Section D: ID Verification
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  XFile? _aadharFront;
  XFile? _aadharBack;
  XFile? _panPhoto;
  XFile? _liveSelfie;

  final List<String> _experienceLevels = ['Fresher', '0–1 Year', '1–3 Years', '3–5 Years', '5+ Years'];
  final List<String> _indianStates = ['Gujarat', 'Maharashtra', 'Rajasthan', 'Madhya Pradesh', 'Delhi', 'Karnataka'];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkills.isEmpty) {
        _showErrorSnackBar('Please select at least one skill');
        return;
      }
      if (_selectedLanguages.isEmpty) {
        _showErrorSnackBar('Please select at least one language');
        return;
      }
      if (_aadharController.text.length != 12) {
        _showErrorSnackBar('Aadhar number must be 12 digits');
        return;
      }
      if (_aadharFront == null || _aadharBack == null) {
        _showErrorSnackBar('Please upload both sides of Aadhar card');
        return;
      }
      if (_panController.text.length != 10) {
        _showErrorSnackBar('PAN number must be 10 characters');
        return;
      }
      if (_panPhoto == null) {
        _showErrorSnackBar('Please upload PAN card photo');
        return;
      }
      if (_liveSelfie == null) {
        _showErrorSnackBar('Please capture a live selfie');
        return;
      }
      
      // Success - Navigate to Verification Status
      context.go('/professional/verification-status', extra: _nameController.text);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  Future<void> _pickImage(String type, {ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera && type == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (type == 'aadhar_front') _aadharFront = image;
        else if (type == 'aadhar_back') _aadharBack = image;
        else if (type == 'pan') _panPhoto = image;
        else if (type == 'selfie') _liveSelfie = image;
      });
    }
  }

  void _showImageSourceSheet(String type) {
    if (type == 'selfie') {
      _pickImage('selfie', source: ImageSource.camera);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Image Source', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_outlined, 'Camera', () {
                  Navigator.pop(context);
                  _pickImage(type, source: ImageSource.camera);
                }),
                _buildSourceOption(Icons.photo_library_outlined, 'Gallery', () {
                  Navigator.pop(context);
                  _pickImage(type, source: ImageSource.gallery);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(
          'Professional Registration',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF2E2E2E),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E2E2E), size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Profile',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E2E2E),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us verify your skills to get started on the platform.',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A7A7A), 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionHeader('Personal Information', Icons.person_rounded),
              _buildCard([
                _buildTextField('Full Name', _nameController, Icons.person_outline, (v) => v!.isEmpty ? 'Name required' : null),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, Icons.email_outlined, (v) {
                  if (v!.isEmpty) return 'Email required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter valid email';
                  return null;
                }, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField('DOB', _dobController, Icons.calendar_today_outlined, (v) => v!.isEmpty ? 'DOB required' : null),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown('Gender', ['Male', 'Female', 'Other'], _selectedGender, (v) => setState(() => _selectedGender = v)),
              ]),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Skills & Expertise', Icons.auto_awesome_rounded),
              _buildCard([
                const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedSkills.add(skill);
                          else _selectedSkills.remove(skill);
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildDropdown('Experience', _experienceLevels, _selectedExperience, (v) => setState(() => _selectedExperience = v)),
                const SizedBox(height: 16),
                const Text('Languages Known', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allLanguages.map((lang) {
                    final isSelected = _selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedLanguages.add(lang);
                          else _selectedLanguages.remove(lang);
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  }).toList(),
                ),
              ]),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Communication Address', Icons.home_rounded),
              _buildCard([
                _buildTextField('Address', _addressController, Icons.home_outlined, (v) => v!.isEmpty ? 'Address required' : null, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField('City', _cityController, Icons.location_city_outlined, (v) => v!.isEmpty ? 'City required' : null),
                const SizedBox(height: 16),
                _buildDropdown('State', _indianStates, _selectedState, (v) => setState(() => _selectedState = v)),
                const SizedBox(height: 16),
                _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined, (v) {
                  if (v!.isEmpty) return 'Pincode required';
                  if (v.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(v)) return 'Pincode must be 6 digits';
                  return null;
                }, keyboardType: TextInputType.number, maxLength: 6),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('Identity Verification', Icons.verified_user_rounded),
              _buildCard([
                _buildTextField(
                  'Aadhar Number', 
                  _aadharController, 
                  Icons.badge_outlined, 
                  (v) => (v == null || v.length != 12) ? '12-digit Aadhar required' : null,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                const SizedBox(height: 24),
                const Text('Aadhar Card Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildImagePickerTile('Front side', _aadharFront, () => _showImageSourceSheet('aadhar_front'))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildImagePickerTile('Back side', _aadharBack, () => _showImageSourceSheet('aadhar_back'))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  'PAN Number', 
                  _panController, 
                  Icons.credit_card_outlined, 
                  (v) => (v == null || v.length != 10) ? '10-char PAN required' : null,
                  maxLength: 10,
                ),
                const SizedBox(height: 16),
                const Text('PAN Card Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox( width: double.infinity, child: _buildImagePickerTile('Upload Photo', _panPhoto,  () => _showImageSourceSheet('pan'), ),),
                const SizedBox(height: 24),
                const Text('Live Selfie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Capture a clear photo of your face', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildImagePickerTile(
                    'Capture Selfie',
                    _liveSelfie,
                    () => _showImageSourceSheet('selfie'),
                    isSquare: true,
                  ),
                ),

              ]),
              
              const SizedBox(height: 48),
              PrimaryButton(label: 'Submit Application', onPressed: _submitForm),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2E2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, String? Function(String?) validator, {TextInputType? keyboardType, int maxLines = 1, int? maxLength}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF7A7A7A), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7A7A7A)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? '$hint required' : null,
      decoration: InputDecoration(
        hintText: 'Select $hint',
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF7A7A7A), fontWeight: FontWeight.w400),
        prefixIcon: Icon(
          hint == 'Gender' ? Icons.people_outline : hint == 'Experience' ? Icons.work_outline : Icons.map_outlined, 
          size: 20,
          color: const Color(0xFF7A7A7A),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildImagePickerTile(String label, XFile? image, VoidCallback onTap, {bool isSquare = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSquare ? 200 : 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    label.toLowerCase().contains('selfie') ? Icons.camera_front_rounded : Icons.add_a_photo_outlined, 
                    color: AppTheme.primaryColor.withValues(alpha: 0.5)
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
      ),
    );
  }
}

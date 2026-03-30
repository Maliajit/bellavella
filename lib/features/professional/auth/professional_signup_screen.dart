import 'dart:io';
import '../services/professional_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';

class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (int i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      if ((i == 1 || i == 3) && i != trimmed.length - 1) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ProfessionalSignupScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? referralCode;
  const ProfessionalSignupScreen({super.key, this.phoneNumber, this.referralCode});

  @override
  State<ProfessionalSignupScreen> createState() => _ProfessionalSignupScreenState();
}

class _ProfessionalSignupScreenState extends State<ProfessionalSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  
  // Validation Error Keys (for auto-scroll)
  final _personalInfoKey = GlobalKey();
  final _skillsKey = GlobalKey();
  final _addressKey = GlobalKey();
  final _bankingKey = GlobalKey();
  final _idVerificationKey = GlobalKey();

  // Image Error States (for visual feedback)
  bool _aadharFrontError = false;
  bool _aadharBackError = false;
  bool _panPhotoError = false;
  bool _certificateError = false;
  bool _lightBillError = false;
  bool _selfieError = false;
  bool _skillsError = false;
  bool _languagesError = false;
  bool _termsError = false;

  bool _showErrorTop = false;
  
  // Section A Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  DateTime? _selectedDob;
  String? _selectedGender;
  final _referralCodeController = TextEditingController();
  
  // Section B Data
  final List<String> _allSkills = ['Facial', 'Waxing', 'Makeup', 'Hair Styling', 'Manicure', 'Pedicure', 'Massage'];
  final List<String> _selectedSkills = [];
  String? _selectedExperience;
  final List<String> _allLanguages = ['Gujarati', 'Hindi', 'English', 'Marathi', 'Punjabi'];
  final List<String> _selectedLanguages = [];
  
  // Section C Controllers
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedState;
  String? _selectedCity;
  String? _selectedArea;
  bool _isTermsAccepted = false;

  // Section D: Banking Details
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  // Section E: ID Verification
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  XFile? _aadharFront;
  XFile? _aadharBack;
  XFile? _panPhoto;
  XFile? _bankProofPhoto;
  XFile? _certificatePhoto;
  XFile? _lightBillPhoto;
  XFile? _liveSelfie;

  final List<String> _experienceLevels = ['Fresher', '0–1 Year', '1–3 Years', '3–5 Years', '5+ Years'];
  final List<String> _experienceOptions = ['Fresher', '0-1 Year', '1-3 Years', '3-5 Years', '5+ Years'];
  final Map<String, Map<String, List<String>>> _locationOptions = const {
    'Gujarat': {
      'Ahmedabad': ['Navrangpura', 'Maninagar', 'Bopal'],
      'Surat': ['Adajan', 'Vesu', 'Katargam'],
    },
    'Maharashtra': {
      'Mumbai': ['Andheri', 'Borivali', 'Powai'],
      'Pune': ['Kothrud', 'Wakad', 'Hinjewadi'],
    },
    'Rajasthan': {
      'Jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'Mansarovar'],
      'Udaipur': ['Hiran Magri', 'Sector 14', 'Shobhagpura'],
    },
    'Madhya Pradesh': {
      'Indore': ['Vijay Nagar', 'Palasia', 'Bhawarkuan'],
      'Bhopal': ['Arera Colony', 'Kolar Road', 'MP Nagar'],
    },
    'Delhi': {
      'New Delhi': ['Lajpat Nagar', 'Dwarka', 'Saket'],
      'North Delhi': ['Model Town', 'Rohini', 'Civil Lines'],
    },
    'Karnataka': {
      'Bengaluru': ['Indiranagar', 'Whitefield', 'Jayanagar'],
      'Mysuru': ['VV Mohalla', 'Kuvempunagar', 'Nazarbad'],
    },
  };

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedGender = 'Female';
    if (widget.referralCode != null) {
      _referralCodeController.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    _referralCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _availableStates => _locationOptions.keys.toList();

  List<String> get _availableCities {
    if (_selectedState == null) return const [];
    return _locationOptions[_selectedState!]!.keys.toList();
  }

  List<String> get _availableAreas {
    if (_selectedState == null || _selectedCity == null) return const [];
    return _locationOptions[_selectedState!]![_selectedCity!] ?? const [];
  }

  void _handleDobChanged(String value) {
    if (value.length != 10) {
      if (_selectedDob != null) {
        setState(() => _selectedDob = null);
      }
      return;
    }

    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(value);
      if (_isAtLeast18(parsed)) {
        if (_selectedDob != parsed) {
          setState(() => _selectedDob = parsed);
        }
      } else if (_selectedDob != null) {
        setState(() => _selectedDob = null);
      }
    } catch (_) {
      if (_selectedDob != null) {
        setState(() => _selectedDob = null);
      }
    }
  }

  bool _isAtLeast18(DateTime dob) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year - 18, now.month, now.day);
    return !dob.isAfter(cutoff);
  }

  String? _validateDob(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'DOB required';
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(input)) {
      return 'Use dd/mm/yyyy format';
    }

    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(input);
      if (!_isAtLeast18(parsed)) {
        return 'Professional must be at least 18 years old';
      }
      _selectedDob = parsed;
    } catch (_) {
      return 'Enter a valid date';
    }

    return null;
  }

  void _scrollToError(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateImagesAndExtra() {
    bool valid = true;
    setState(() {
      _aadharFrontError = _aadharFront == null;
      _aadharBackError = _aadharBack == null;
      _panPhotoError = _panPhoto == null;
      _certificateError = _certificatePhoto == null;
      _lightBillError = _lightBillPhoto == null;
      _selfieError = _liveSelfie == null;
      _skillsError = _selectedSkills.isEmpty;
      _languagesError = _selectedLanguages.isEmpty;
      _termsError = !_isTermsAccepted;
    });

    if (_skillsError || _languagesError) {
      if (valid) _scrollToError(_skillsKey);
      valid = false;
    }

    if (_aadharFrontError || _aadharBackError || _panPhotoError || _certificateError || _lightBillError || _selfieError) {
      if (valid) _scrollToError(_idVerificationKey);
      valid = false;
    }

    if (_termsError) {
      valid = false;
    }

    return valid;
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    
    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    final bool isExtraValid = _validateImagesAndExtra();

    if (!isFormValid || !isExtraValid) {
      setState(() => _showErrorTop = true);
      
      if (!isFormValid) {
        // Auto scroll to first form error
        if (_nameController.text.isEmpty || _emailController.text.isEmpty || _dobController.text.isEmpty) {
          _scrollToError(_personalInfoKey);
        } else if (_addressController.text.isEmpty || _selectedState == null || _selectedCity == null || _selectedArea == null || _pincodeController.text.length != 6) {
          _scrollToError(_addressKey);
        } else if (_accountHolderController.text.isEmpty || _bankNameController.text.isEmpty || _accountNumberController.text.isEmpty || _ifscController.text.isEmpty) {
          _scrollToError(_bankingKey);
        } else if (_aadharController.text.length != 12 || _panController.text.length != 10) {
          _scrollToError(_idVerificationKey);
        }
      }
      
      _showErrorSnackBar('Please complete all required fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
      _showErrorTop = false;
    });
    
    try {
      final combinedAddress = [
        _addressController.text.trim(),
        if (_selectedArea != null && _selectedArea!.trim().isNotEmpty) _selectedArea!.trim(),
      ].join(', ');

      final response = await ProfessionalApiService.register(
        mobile: widget.phoneNumber ?? '',
        name: _nameController.text.trim(),
        category: _selectedSkills.join(', '),
        city: _selectedCity ?? '',
        email: _emailController.text.trim(),
        dob: _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null,
        gender: _selectedGender,
        experience: _selectedExperience,
        languages: _selectedLanguages.join(', '),
        address: combinedAddress,
        pincode: _pincodeController.text.trim(),
        state: _selectedState,
        aadharNumber: _aadharController.text.trim(),
        panNumber: _panController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        upiId: _upiController.text.trim(),
        aadharFront: _aadharFront,
        aadharBack: _aadharBack,
        panPhoto: _panPhoto,
        bankProof: _bankProofPhoto,
        certificate: _certificatePhoto,
        lightBill: _lightBillPhoto,
        selfie: _liveSelfie,
        referralCode: _referralCodeController.text.trim().isNotEmpty ? _referralCodeController.text.trim() : null,
      );

      if (mounted) {
        if (response['success'] == true) {
          final int coins = response['coins_awarded'] ?? 0;
          if (coins > 0) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: AppTheme.primaryColor, size: 64),
                    const SizedBox(height: 16),
                    Text('Congratulations!', 
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('You\'ve received $coins welcome coins!', 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Awesome!', 
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (mounted) {
            context.go('/professional/verification-status', extra: _nameController.text);
          }
        } else {
          _showErrorSnackBar(response['message'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        else if (type == 'bank_proof') _bankProofPhoto = image;
        else if (type == 'certificate') _certificatePhoto = image;
        else if (type == 'light_bill') _lightBillPhoto = image;
        else if (type == 'selfie') _liveSelfie = image;
      });
    }
  }

  void _removeImage(String type) {
    setState(() {
      if (type == 'aadhar_front') _aadharFront = null;
      else if (type == 'aadhar_back') _aadharBack = null;
      else if (type == 'pan') _panPhoto = null;
      else if (type == 'bank_proof') _bankProofPhoto = null;
      else if (type == 'certificate') _certificatePhoto = null;
      else if (type == 'light_bill') _lightBillPhoto = null;
      else if (type == 'selfie') _liveSelfie = null;
    });
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
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              if (_showErrorTop)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Please complete all required fields',
                        style: GoogleFonts.outfit(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
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
              
              _buildSectionHeader('Personal Information', Icons.person_rounded, _personalInfoKey),
              _buildCard([
                _buildTextField('Full Name', _nameController, Icons.person_outline, (v) => (v == null || v.isEmpty) ? 'Full name is required' : null),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, Icons.email_outlined, (v) {
                  if (v == null || v.isEmpty) return 'Email required';
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
                    return 'Enter a valid email (e.g., user@example.com)';
                  }
                  return null;
                }, keyboardType: TextInputType.emailAddress, autocorrect: false),
                const SizedBox(height: 16),
                _buildTextField(
                  'DOB (dd/mm/yyyy)',
                  _dobController,
                  Icons.edit_calendar_outlined,
                  _validateDob,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_DobInputFormatter()],
                  onChanged: _handleDobChanged,
                ),
                const SizedBox(height: 16),
                _buildDropdown('Gender', const ['Female'], _selectedGender, (v) => setState(() => _selectedGender = v)),
                const SizedBox(height: 16),
                _buildTextField('Referral Code (Optional)', _referralCodeController, Icons.card_giftcard_rounded, (v) => null),
              ]),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Skills & Expertise', Icons.auto_awesome_rounded, _skillsKey),
              _buildCard([
                Row(
                  children: [
                    const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_skillsError) const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('* Required', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
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
                _buildDropdown('Experience', _experienceOptions, _selectedExperience, (v) => setState(() => _selectedExperience = v)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Languages Known', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_languagesError) const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('* Required', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
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
              _buildSectionHeader('Communication Address', Icons.home_rounded, _addressKey),
              _buildCard([
                _buildTextField('Address', _addressController, Icons.home_outlined, (v) => (v == null || v.isEmpty) ? 'Address required' : null, maxLines: 3),
                const SizedBox(height: 16),
                _buildDropdown('State', _availableStates, _selectedState, (v) => setState(() {
                  _selectedState = v;
                  _selectedCity = null;
                  _selectedArea = null;
                })),
                const SizedBox(height: 16),
                _buildDropdown(
                  'City',
                  _availableCities,
                  _selectedCity,
                  _selectedState == null ? null : (v) => setState(() {
                    _selectedCity = v;
                    _selectedArea = null;
                  }),
                  enabled: _selectedState != null,
                  emptyLabel: 'Select state first',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'Area',
                  _availableAreas,
                  _selectedArea,
                  _selectedCity == null ? null : (v) => setState(() => _selectedArea = v),
                  enabled: _selectedCity != null,
                  emptyLabel: 'Select city first',
                ),
                const SizedBox(height: 16),
                _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined, (v) {
                  if (v == null || v.isEmpty) return 'Pincode required';
                  if (v.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(v)) return 'Pincode must be 6 digits';
                  return null;
                }, keyboardType: TextInputType.number, maxLength: 6),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('Banking Details', Icons.account_balance_rounded, _bankingKey),
              _buildCard([
                _buildTextField('Account Holder Name', _accountHolderController, Icons.person_outline, (v) => (v == null || v.isEmpty) ? 'Account holder name is required' : null),
                const SizedBox(height: 16),
                _buildTextField('Bank Name', _bankNameController, Icons.account_balance_outlined, (v) => (v == null || v.isEmpty) ? 'Bank name is required' : null),
                const SizedBox(height: 16),
                _buildTextField('Account Number', _accountNumberController, Icons.pin_outlined, (v) {
                  if (v == null || v.isEmpty) return 'Account number is required';
                  if (v.length < 9) return 'Enter a valid account number';
                  return null;
                }, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(
                  'IFSC Code', 
                  _ifscController, 
                  Icons.vpn_key_outlined, 
                  (v) {
                    if (v == null || v.isEmpty) return 'IFSC code is required';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v)) return 'Invalid IFSC format (e.g. SBIN0012345)';
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'UPI ID (Optional)', 
                  _upiController, 
                  Icons.alternate_email_rounded, 
                  (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) return 'Invalid UPI ID format';
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'Passbook / Cancelled Cheque Photo',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF2E2E2E)),
                ),
                const SizedBox(height: 8),
                _buildImagePickerTile('Upload Passbook / Cheque', _bankProofPhoto, 'bank_proof'),
              ]),

              const SizedBox(height: 32),
              _buildSectionHeader('Identity Verification', Icons.verified_user_rounded, _idVerificationKey),
              _buildCard([
                _buildTextField(
                  'Aadhar Number', 
                  _aadharController, 
                  Icons.badge_outlined, 
                  (v) {
                    if (v == null || v.isEmpty) return 'Aadhaar number is required';
                    if (!RegExp(r'^[0-9]{12}$').hasMatch(v)) return 'Aadhaar must be exactly 12 digits';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Aadhar Card Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildImagePickerTile('Front side', _aadharFront, 'aadhar_front', isError: _aadharFrontError)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildImagePickerTile('Back side', _aadharBack, 'aadhar_back', isError: _aadharBackError)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  'PAN Number', 
                  _panController, 
                  Icons.credit_card_outlined, 
                  (v) {
                    if (v == null || v.isEmpty) return 'PAN number is required';
                    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(v)) return 'Invalid PAN format (ABCDE1234F)';
                    return null;
                  },
                  maxLength: 10,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 12),
                SizedBox( width: double.infinity, child: _buildImagePickerTile('Upload Photo', _panPhoto, 'pan', isError: _panPhotoError),),
                const SizedBox(height: 24),
                const Text('Professional Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox( width: double.infinity, child: _buildImagePickerTile('Upload Certificate', _certificatePhoto, 'certificate', isError: _certificateError),),
                const SizedBox(height: 24),
                const Text('Light Bill Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Upload a recent light bill image for address verification', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildImagePickerTile('Upload Light Bill', _lightBillPhoto, 'light_bill', isError: _lightBillError),
                ),
                const SizedBox(height: 24),
                const Text('Live Selfie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Capture a clear photo with white plain background only. Otherwise request will be rejected.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildImagePickerTile(
                    'Capture Selfie',
                    _liveSelfie,
                    'selfie',
                    isSquare: true,
                    isError: _selfieError,
                  ),
                ),

              ]),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: _termsError ? AppTheme.errorColor : const Color(0xFF555555),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (value) => setState(() {
                          _isTermsAccepted = value ?? false;
                          if (_isTermsAccepted) _termsError = false;
                        }),
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        side: BorderSide(
                          color: _termsError ? AppTheme.errorColor : const Color(0xFF555555),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isTermsAccepted = !_isTermsAccepted;
                          if (_isTermsAccepted) _termsError = false;
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I agree to Terms & Conditions',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _termsError ? AppTheme.errorColor : const Color(0xFF7A7A7A),
                              ),
                            ),
                            if (_termsError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Please accept Terms & Conditions',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              PrimaryButton(
                label: _isLoading ? 'Submitting...' : 'Submit Application', 
                onPressed: _isLoading ? null : _submitForm
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildSectionHeader(String title, IconData icon, GlobalKey key) {
    return Padding(
      key: key,
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

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, String? Function(String?) validator, {TextInputType? keyboardType, int maxLines = 1, int? maxLength, List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none, bool autocorrect = true, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF7A7A7A), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7A7A7A)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?>? onChanged, {bool enabled = true, String? emptyLabel}) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)))).toList(),
      onChanged: enabled && items.isNotEmpty ? onChanged : null,
      validator: (v) => v == null ? '$hint required' : null,
      decoration: InputDecoration(
        hintText: items.isEmpty ? (emptyLabel ?? 'No $hint available') : 'Select $hint',
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
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildImagePickerTile(String label, XFile? image, String type, {bool isSquare = false, bool isError = false}) {
    return GestureDetector(
      onTap: () => image == null ? _showImageSourceSheet(type) : null,
      child: Container(
        height: isSquare ? 220 : 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isError ? AppTheme.errorColor.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isError ? AppTheme.errorColor : const Color(0xFFE5E7EB), 
            width: isError ? 1.5 : 1.2
          ),
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? Image.network(image.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(
                            File(image.path), 
                            fit: BoxFit.cover, 
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _removeImage(type),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        label.toLowerCase().contains('selfie') ? Icons.face_rounded : label.toLowerCase().contains('passbook') ? Icons.account_balance_wallet_outlined : Icons.cloud_upload_outlined, 
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label, 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF374151), 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

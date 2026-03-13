import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../../../core/models/data_models.dart';
import 'services/client_api_service.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _dateOfBirth = 'Select Date';

  bool _isLoading  = true;
  bool _isSaving   = false;
  bool _isUploading = false;
  Customer? _profile;

  // Locally picked image bytes — used for instant preview on web
  Uint8List? _pickedImageBytes;
  // URL returned by the server after a successful upload
  String? _uploadedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final profile = await ClientApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile       = profile;
          _nameController.text  = profile.name;
          _emailController.text = profile.email ?? '';
          _phoneController.text = profile.mobile;
          _dateOfBirth   = profile.dateOfBirth ?? 'Select Date';
          _isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnack('Failed to load profile: $e');
    }
  }

  // ─── Image Picker ─────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
              title: const Text('Open Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_uploadedAvatarUrl != null || _profile?.avatar != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pickedImageBytes  = null;
                    _uploadedAvatarUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Picks an image, shows an instant local preview, then uploads to server.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;

      // Read bytes immediately for instant local preview (works on web too)
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _isUploading      = true;
      });

      final response = await ClientApiService.uploadAvatar(file);

      if (!mounted) return;

      if (response['success'] == true) {
        final newUrl = response['data']?['avatar'] as String?;
        setState(() {
          _uploadedAvatarUrl = newUrl;
          if (_profile != null && newUrl != null) {
            _profile = Customer(
              id:          _profile!.id,
              name:        _profile!.name,
              mobile:      _profile!.mobile,
              email:       _profile!.email,
              avatar:      newUrl,
              dateOfBirth: _profile!.dateOfBirth,
              status:      _profile!.status,
              joined:      _profile!.joined,
              referralCode: _profile!.referralCode,
            );
          }
        });
        _showSnack('Profile photo updated!', success: true);
      } else {
        // Revert preview on failure
        setState(() => _pickedImageBytes = null);
        _showSnack(response['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) setState(() => _pickedImageBytes = null);
      _showSnack('Image upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── Date Picker ─────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    if (_dateOfBirth != 'Select Date') {
      try { initial = DateTime.parse(_dateOfBirth); } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'name':          _nameController.text.trim(),
        if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
        if (_dateOfBirth != 'Select Date') 'date_of_birth': _dateOfBirth,
      };

      final response = await ClientApiService.updateProfile(data);
      if (!mounted) return;

      if (response['success'] == true) {
        _showSnack('Profile updated successfully!', success: true);
        Navigator.pop(context);
      } else {
        _showSnack(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    if (success) {
      ToastUtil.showSuccess(context, msg);
    } else {
      ToastUtil.showError(context, msg);
    }
  }

  String? get _serverAvatarUrl => _uploadedAvatarUrl ?? _profile?.avatar;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileImage(),
            const SizedBox(height: 40),
            _buildInputField('Full Name', _nameController),
            const SizedBox(height: 24),
            _buildInputField('Email', _emailController),
            const SizedBox(height: 24),
            _buildReadOnlyField('Mobile Number', _phoneController),
            const SizedBox(height: 24),
            _buildDatePickerField(),
            const SizedBox(height: 60),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        // Avatar circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100, width: 4),
          ),
          child: ClipOval(
            child: Stack(
            fit: StackFit.expand,
            children: [
              // Local bytes preview (instant, works on web)
              if (_pickedImageBytes != null)
                Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
              // Server URL (loaded after upload or on screen open)
              else if (_serverAvatarUrl != null && _serverAvatarUrl!.isNotEmpty)
                Image.network(
                  _serverAvatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                )
              // Fallback placeholder
              else
                _avatarPlaceholder(),

              // Uploading overlay
              if (_isUploading)
                Container(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          ),
        ),

        // Edit button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _showImageSourceSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: false,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: const InputDecoration(
            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
            disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.5)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateOfBirth,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Icon(Icons.calendar_month_outlined, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProfessionalEditProfileScreen extends StatefulWidget {
  const ProfessionalEditProfileScreen({super.key});

  @override
  State<ProfessionalEditProfileScreen> createState() => _ProfessionalEditProfileScreenState();
}

class _ProfessionalEditProfileScreenState extends State<ProfessionalEditProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(text: 'Kevin Shah');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _addressController = TextEditingController(text: 'Baner, Pune, Maharashtra');
  final TextEditingController _skillsController = TextEditingController(text: 'Full Body Waxing, Gold Glow Facial');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildTextField('Full Name', _nameController, Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 20),
                        _buildTextField('Skills (comma separated)', _skillsController, Icons.work_outline),
                        const SizedBox(height: 20),
                        _buildTextField('Address', _addressController, Icons.location_on_outlined, maxLines: 3),
                        const SizedBox(height: 40),
                        _buildSaveButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _isScrolled ? Colors.white : Colors.black,
            onPressed: () => context.go('/professional/profile'),
          ),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.pink.shade300),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            context.go('/professional/profile');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: AppTheme.primaryColor.withOpacity(0.5),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

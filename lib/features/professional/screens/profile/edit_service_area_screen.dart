import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class EditServiceAreaScreen extends StatefulWidget {
  const EditServiceAreaScreen({super.key});

  @override
  State<EditServiceAreaScreen> createState() => _EditServiceAreaScreenState();
}

class _EditServiceAreaScreenState extends State<EditServiceAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cityController;
  late TextEditingController _radiusController;
  late TextEditingController _areasController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfessionalProfileController>().profile;
    _cityController = TextEditingController(text: profile?.city);
    _radiusController = TextEditingController(text: profile?.serviceRadius?.toString());
    _areasController = TextEditingController(text: profile?.serviceArea);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _radiusController.dispose();
    _areasController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfessionalProfileController>().updateServiceArea({
        'city': _cityController.text,
        'service_radius': double.tryParse(_radiusController.text),
        'service_area': _areasController.text,
      });

      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service area updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Service Area', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
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
                  _buildTextField("City", _cityController, Icons.location_city),
                  const SizedBox(height: 20),
                  _buildTextField("Service Radius (km)", _radiusController, Icons.radar, keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  _buildTextField("Areas Covered", _areasController, Icons.map_outlined, maxLines: 3),
                  const SizedBox(height: 40),
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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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

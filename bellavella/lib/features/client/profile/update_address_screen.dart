import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/features/client/profile/services/client_profile_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class UpdateAddressScreen extends StatefulWidget {
  final Address? address; // If null, it's for adding new address

  const UpdateAddressScreen({super.key, this.address});

  // Factory constructor to handle router extra
  factory UpdateAddressScreen.fromExtra(Object? extra) {
    return UpdateAddressScreen(address: extra as Address?);
  }

  @override
  State<UpdateAddressScreen> createState() => _UpdateAddressScreenState();
}

class _UpdateAddressScreenState extends State<UpdateAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedLabel = 'Home';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      // Pre-fill form for editing
      _houseController.text = widget.address!.houseNumber;
      _areaController.text = widget.address!.area;
      _landmarkController.text = widget.address!.landmark;
      _cityController.text = widget.address!.city;
      _pincodeController.text = widget.address!.pincode;
      _phoneController.text = widget.address!.phone;
      _selectedLabel = widget.address!.label;
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.address != null) {
        // Update existing address
        await ClientProfileApiService.updateAddress(
          addressId: widget.address!.id,
          label: _selectedLabel,
          houseNumber: _houseController.text,
          address: _areaController.text,
          landmark: _landmarkController.text,
          city: _cityController.text,
          pincode: _pincodeController.text,
          phone: _phoneController.text,
        );
      } else {
        // Add new address
        await ClientProfileApiService.addAddress(
          label: _selectedLabel,
          houseNumber: _houseController.text,
          address: _areaController.text,
          landmark: _landmarkController.text,
          city: _cityController.text,
          pincode: _pincodeController.text,
          phone: _phoneController.text,
        );
      }

      if (mounted) {
        ToastUtil.showSuccess(
          context,
          widget.address != null
              ? 'Address updated successfully!'
              : 'Address added successfully!',
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, 'Failed to save address: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Manage Address',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.address != null) ...[
                Text(
                  widget.address!.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.address!.fullAddress,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
              ],
              _buildTextField('House/Flat Number *', _houseController, (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter house/flat number';
                }
                return null;
              }),
              const SizedBox(height: 20),
              _buildTextField('Area / Street / Society *', _areaController, (
                value,
              ) {
                if (value == null || value.isEmpty) {
                  return 'Please enter area/street/society';
                }
                return null;
              }),
              const SizedBox(height: 20),
              _buildTextField('Landmark (Optional)', _landmarkController),
              const SizedBox(height: 20),
              _buildTextField('City *', _cityController, (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter city';
                }
                return null;
              }),
              const SizedBox(height: 20),
              _buildTextField('Pincode *', _pincodeController, (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pincode';
                }
                if (value.length != 6) {
                  return 'Pincode must be 6 digits';
                }
                return null;
              }, TextInputType.number, [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ]),
              const SizedBox(height: 20),
              _buildTextField('Phone Number *', _phoneController, (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.length != 10) {
                  return 'Phone number must be 10 digits';
                }
                return null;
              }, TextInputType.phone, [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]),
              const SizedBox(height: 30),
              const Text(
                'Save as',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildLabelChip('Home'),
                  _buildLabelChip('Work'),
                  _buildLabelChip('Other'),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.address != null
                              ? 'Update address'
                              : 'Add address',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLabelChip(String label) {
    bool isSelected = _selectedLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFB6C1).withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

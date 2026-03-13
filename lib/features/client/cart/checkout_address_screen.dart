import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bellavella/core/utils/toast_util.dart';

class CheckoutAddressScreen extends StatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  static const Color pinkPrimary = Color(0xFFFF4891);
  
  String _currentAddress = "Fetching location...";
  String _currentArea = "Loading...";
  bool _isHomeSelected = true;
  
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otherLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void dispose() {
    _houseController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _otherLabelController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          setState(() {
            _currentArea = placemark.subLocality ?? placemark.locality ?? "Unknown Area";
            _currentAddress = "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}";
          });
        }
      } else {
         setState(() {
            _currentArea = "Unknown Area";
            _currentAddress = "Location permission denied";
         });
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
      setState(() {
        _currentArea = "Unknown Area";
        _currentAddress = "Failed to fetch location";
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (isRequired ? '*' : ''),
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
        floatingLabelStyle: GoogleFonts.outfit(color: pinkPrimary, fontSize: 13),
        suffixIcon: IconButton(
          icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
          onPressed: () => controller.clear(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: pinkPrimary),
        ),
      ),
    );
  }

  Widget _buildSaveAsChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  void _proceedToSlots() {
    if (_houseController.text.trim().isEmpty) {
      ToastUtil.showError(context, 'Please enter House/Flat Number.');
      return;
    }

    if (!_isHomeSelected && _otherLabelController.text.trim().isEmpty) {
      ToastUtil.showError(context, 'Please enter a label for "Other".');
      return;
    }

    // Prepare address data
    final addressData = {
      'label': _isHomeSelected ? 'Home' : _otherLabelController.text.trim(),
      'fullAddress': _currentAddress,
      'houseNumber': _houseController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'name': _nameController.text.trim(),
    };

    // Navigate to Slots screen
    context.push('/client/checkout-slots', extra: {'addressData': addressData});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Address',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Map Representation Header
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1526778446212-04fa3e4f3a73?q=80&w=1000'),
                fit: BoxFit.cover,
                opacity: 0.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.location_on, color: pinkPrimary, size: 50),
                ),
                Positioned(
                  bottom: 10,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Icon(Icons.my_location, color: pinkPrimary),
                  ),
                ),
              ],
            ),
          ),
          
          // Address Details Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentArea,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentAddress,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchAddress,
                      child: Text(
                        'Refresh',
                        style: GoogleFonts.outfit(
                          color: pinkPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                _buildTextField(_houseController, 'House/Flat Number', isRequired: true),
                const SizedBox(height: 15),
                _buildTextField(_landmarkController, 'Landmark (Optional)'),
                const SizedBox(height: 15),
                _buildTextField(_nameController, 'Name (Optional)'),
                const SizedBox(height: 25),
                Text(
                  'Save as',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSaveAsChip('Home', _isHomeSelected, () => setState(() => _isHomeSelected = true)),
                    const SizedBox(width: 12),
                    _buildSaveAsChip('Other', !_isHomeSelected, () => setState(() => _isHomeSelected = false)),
                  ],
                ),
                if (!_isHomeSelected) ...[
                  const SizedBox(height: 15),
                  _buildTextField(_otherLabelController, 'e.g. John\'s Home', isRequired: true),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: ElevatedButton(
          onPressed: _proceedToSlots,
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkPrimary,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Proceed to Slots',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

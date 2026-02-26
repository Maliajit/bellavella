import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_widgets.dart';
import '../../../../core/utils/location_util.dart';

class ClientLocationPickerScreen extends StatefulWidget {
  const ClientLocationPickerScreen({super.key});

  @override
  State<ClientLocationPickerScreen> createState() => _ClientLocationPickerScreenState();
}

class _ClientLocationPickerScreenState extends State<ClientLocationPickerScreen> {
  String _address = 'Fetching location...';
  String _subAddress = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (!kIsWeb) {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'Location services are disabled.';
        }
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Main bold location - prioritize more specific areas
          String? mainLoc = place.subLocality;
          if (mainLoc == null || mainLoc.isEmpty || mainLoc == place.locality) {
            mainLoc = place.thoroughfare;
          }
          if (mainLoc == null || mainLoc.isEmpty) {
            mainLoc = place.name;
          }
          _address = mainLoc ?? place.locality ?? 'Unknown Location';

          // Full sub-address details
          List<String> addressParts = [];
          if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) addressParts.add(place.thoroughfare!);
          if (place.subLocality != null && place.subLocality!.isNotEmpty && place.subLocality != place.name) addressParts.add(place.subLocality!);
          if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
          if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
          if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);

          // Use a set to remove duplicates if any (e.g. name is same as thoroughfare)
          _subAddress = addressParts.toSet().join(', ');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Could not fetch location';
        _subAddress = e.toString();
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Confirm Location',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Location Illustration/Visual
            // Location PIN Visual
            Stack(
              alignment: Alignment.center,
              children: [
                // Custom PIN Visual
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B86C4), // Match the blue-purple color
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0E0E0), // Light grey center
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B86C4),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Address Details (Matched to Image)
            if (!_isLoading) ...[
              Text(
                'Delivering service at',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFF2E7D32), // Green color
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _address,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _subAddress,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const Spacer(),

            if (_hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: _determinePosition,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ),

            PrimaryButton(
              label: 'Confirm & Continue',
              isLoading: _isLoading,
              onPressed: _isLoading
                  ? null
                  : () {
                      LocationUtil.setLocation(_address, _subAddress);
                      context.go('/client/home');
                    },
            ),
          ],
        ),
      ),
    );
  }
}

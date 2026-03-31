import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class HomeLocationService {
  Future<Map<String, String>?> determinePosition() async {
    // Geocoding reverse-lookup is not supported on Flutter Web
    if (kIsWeb) {
      return {'address': 'Your Location', 'subAddress': ''};
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          String? mainLoc = place.subLocality;
          if (mainLoc == null || mainLoc.isEmpty || mainLoc == place.locality) {
            mainLoc = place.thoroughfare;
          }
          if (mainLoc == null || mainLoc.isEmpty) {
            mainLoc = place.name;
          }

          return {
            'address': mainLoc ?? place.locality ?? 'Unknown',
            'subAddress': place.locality ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
    return null;
  }
}

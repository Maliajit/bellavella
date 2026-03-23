import 'dart:async';

import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/utils/toast_util.dart';
import 'package:bellavella/features/client/profile/manage_address_screen.dart';
import 'package:bellavella/features/client/profile/services/client_profile_api_service.dart'
    as profile_api;
import 'package:bellavella/features/client/profile/update_address_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum _AddressSource { currentLocation, savedAddress }

class CheckoutAddressScreen extends StatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  static const LatLng _fallbackLatLng = LatLng(23.0225, 72.5714);

  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  GoogleMapController? _mapController;
  LatLng _mapCenter = _fallbackLatLng;
  LatLng? _deviceLatLng;

  bool _isFetchingLocation = false;
  bool _isReverseGeocoding = false;
  bool _isLoadingSavedAddresses = true;

  String _currentArea = 'Unknown Area';
  String _currentCity = '';
  String _currentAddressPreview = 'Fetching location context...';
  String? _savedAddressesError;

  List<Address> _savedAddresses = const [];
  String? _selectedSavedAddressId;
  String _manualLabel = 'Home';

  @override
  void initState() {
    super.initState();
    unawaited(_initializeScreen());
  }

  @override
  void dispose() {
    _houseController.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([
      _loadSavedAddresses(),
      _refreshCurrentLocation(recenterMap: true),
    ]);
  }

  Future<void> _loadSavedAddresses() async {
    setState(() {
      _isLoadingSavedAddresses = true;
      _savedAddressesError = null;
    });

    try {
      final response = await profile_api.ClientProfileApiService.getAddresses();
      final addresses = response
          .map((item) => Address.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses = addresses;
        _isLoadingSavedAddresses = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savedAddressesError = e.toString();
        _isLoadingSavedAddresses = false;
      });
    }
  }

  Future<void> _refreshCurrentLocation({bool recenterMap = false}) async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() => _isFetchingLocation = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentArea = 'Unknown Area';
          _currentAddressPreview = 'Location permission denied';
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _deviceLatLng = latLng;
        _mapCenter = latLng;
      });

      await _reverseGeocode(latLng, updateMap: recenterMap);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentArea = 'Unknown Area';
        _currentAddressPreview = 'Failed to fetch location';
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _reverseGeocode(
    LatLng target, {
    bool updateMap = false,
  }) async {
    if (_isReverseGeocoding) {
      return;
    }

    setState(() => _isReverseGeocoding = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      final area =
          placemark?.subLocality?.trim().isNotEmpty == true
              ? placemark!.subLocality!.trim()
              : placemark?.locality?.trim().isNotEmpty == true
              ? placemark!.locality!.trim()
              : 'Unknown Area';
      final city =
          placemark?.locality?.trim().isNotEmpty == true
              ? placemark!.locality!.trim()
              : placemark?.administrativeArea?.trim().isNotEmpty == true
              ? placemark!.administrativeArea!.trim()
              : '';

      final previewParts = <String?>[
        placemark?.subLocality,
        placemark?.locality,
        placemark?.administrativeArea,
      ].where((part) => part != null && part!.trim().isNotEmpty).join(', ');

      if (!mounted) {
        return;
      }

      setState(() {
        _currentArea = area;
        _currentCity = city;
        _currentAddressPreview =
            previewParts.isEmpty ? 'Unknown Area' : previewParts;
        _mapCenter = target;
      });

      if (updateMap) {
        await _animateCamera(target);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentArea = 'Unknown Area';
        _currentCity = '';
        _currentAddressPreview = 'Unable to identify area';
      });
    } finally {
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      } else {
        _isReverseGeocoding = false;
      }
    }
  }

  Future<void> _animateCamera(LatLng target) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
  }

  void _selectSavedAddress(Address address) {
    setState(() {
      _selectedSavedAddressId = address.id;
    });

    final lat = address.latitude;
    final lng = address.longitude;
    if (lat != null && lng != null) {
      final target = LatLng(lat, lng);
      setState(() => _mapCenter = target);
      unawaited(_animateCamera(target));
    }
  }

  void _useCurrentLocationFlow() {
    setState(() => _selectedSavedAddressId = null);
  }

  Address? get _selectedSavedAddress {
    if (_selectedSavedAddressId == null) {
      return null;
    }

    for (final address in _savedAddresses) {
      if (address.id == _selectedSavedAddressId) {
        return address;
      }
    }
    return null;
  }

  _ResolvedAddressSelection get _resolvedSelection {
    final saved = _selectedSavedAddress;
    if (saved != null) {
      return _ResolvedAddressSelection(
        source: _AddressSource.savedAddress,
        sourceLabel: 'Saved Address',
        label: saved.label,
        fullAddress: saved.shortPreview,
        displayAddress: saved.fullAddress,
        preview: saved.shortPreview,
        houseNumber: saved.houseNumber,
        landmark: saved.landmark,
        name: _nameController.text.trim(),
        latitude: saved.latitude,
        longitude: saved.longitude,
        savedAddressId: saved.id,
        city: saved.city.trim(),
      );
    }

    final preview = _currentAddressPreview.trim().isNotEmpty
        ? _currentAddressPreview.trim()
        : _currentArea;
    final label = _manualLabel == 'Other' ? 'Other' : 'Home';

    return _ResolvedAddressSelection(
      source: _AddressSource.currentLocation,
      sourceLabel: 'Current Location',
      label: label,
      fullAddress: _currentArea == 'Unknown Area'
          ? _currentAddressPreview.trim()
          : _currentArea,
      displayAddress: _composeAddress(
        houseNumber: _houseController.text.trim(),
        landmark: _landmarkController.text.trim(),
        area: _currentArea,
      ),
      preview: preview.isEmpty ? 'Unknown Area' : preview,
      houseNumber: _houseController.text.trim(),
      landmark: _landmarkController.text.trim(),
      name: _nameController.text.trim(),
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      city: _currentCity.trim(),
    );
  }

  String _composeAddress({
    required String houseNumber,
    required String landmark,
    required String area,
  }) {
    final parts = <String>[
      if (houseNumber.isNotEmpty) houseNumber,
      if (landmark.isNotEmpty) landmark,
      if (area.isNotEmpty && area != 'Unknown Area') area,
    ];
    return parts.join(', ');
  }

  bool _validateSelection(_ResolvedAddressSelection selection) {
    if (selection.source == _AddressSource.savedAddress) {
      if (selection.savedAddressId == null) {
        return false;
      }
      if (selection.city.isEmpty) {
        ToastUtil.showError(
          context,
          'Selected saved address is incomplete. City is missing.',
        );
        return false;
      }
      return true;
    }

    final normalizedLocation = selection.fullAddress.toLowerCase();
    if (normalizedLocation.isEmpty ||
        normalizedLocation == 'unknown area' ||
        normalizedLocation == 'unable to identify area' ||
        normalizedLocation.contains('permission denied') ||
        normalizedLocation.contains('failed to fetch location')) {
      ToastUtil.showError(
        context,
        'Unable to detect area from map. Refresh location and try again.',
      );
      return false;
    }

    if (selection.houseNumber.isEmpty) {
      ToastUtil.showError(context, 'Please enter House/Flat Number.');
      return false;
    }

    if (selection.city.isEmpty) {
      ToastUtil.showError(
        context,
        'Unable to detect city from the selected location. Refresh and try again.',
      );
      return false;
    }

    return true;
  }

  void _proceedToSlots() {
    final selection = _resolvedSelection;
    if (!_validateSelection(selection)) {
      return;
    }

    final addressData = {
      'label': selection.label,
      'fullAddress': selection.fullAddress,
      'houseNumber': selection.houseNumber,
      'landmark': selection.landmark,
      'name': selection.name,
      'sourceType': selection.source.name,
      'addressId': selection.savedAddressId,
      'city': selection.city,
      'latitude': selection.latitude,
      'longitude': selection.longitude,
    };

    context.push(
      '/client/checkout-slots',
      extra: {'addressData': addressData},
    );
  }

  Future<void> _openAddAddress() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const UpdateAddressScreen(),
      ),
    );
    if (result == true && mounted) {
      await _loadSavedAddresses();
    }
  }

  Future<void> _openManageAddresses() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManageAddressScreen(),
      ),
    );
    if (mounted) {
      await _loadSavedAddresses();
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final saved = _selectedSavedAddress;
    if (saved?.latitude != null && saved?.longitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected-saved-address'),
          position: LatLng(saved!.latitude!, saved.longitude!),
          infoWindow: InfoWindow(title: saved.label, snippet: saved.shortPreview),
        ),
      );
    }
    return markers;
  }

  bool get _isSavedAddressActive => _selectedSavedAddress != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Select Address',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMapSurface(),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 160),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFFF4891),
                  size: 44,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _MapActionButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _refreshCurrentLocation(recenterMap: true),
                ),
                const SizedBox(height: 12),
                _MapActionButton(
                  icon: Icons.center_focus_strong_rounded,
                  onTap: () {
                    final saved = _selectedSavedAddress;
                    if (saved?.latitude != null && saved?.longitude != null) {
                      unawaited(
                        _animateCamera(
                          LatLng(saved!.latitude!, saved.longitude!),
                        ),
                      );
                      return;
                    }

                    final target = _deviceLatLng ?? _mapCenter;
                    unawaited(_animateCamera(target));
                  },
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.34,
            minChildSize: 0.18,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.18, 0.34, 0.92],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 18,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9DF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                        children: [
                          _buildSavedAddressesSection(),
                          const SizedBox(height: 24),
                          _buildManualSection(),
                          const SizedBox(height: 28),
                          _buildProceedButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapSurface() {
    if (kIsWeb) {
      return _buildMapFallback(
        title: 'Map preview unavailable on web',
        subtitle:
            'Location controls are kept safe until Google Maps is fully ready.',
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _mapCenter,
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      markers: _buildMarkers(),
      onMapCreated: (controller) => _mapController = controller,
      onCameraMove: (position) => _mapCenter = position.target,
      onCameraIdle: () => unawaited(_reverseGeocode(_mapCenter)),
    );
  }

  Widget _buildMapFallback({
    required String title,
    required String subtitle,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF3FF), Color(0xFFF6F8FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: AppTheme.primaryColor, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6E6E7A),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isSavedAddressActive
              ? const Color(0xFFE8E8EE)
              : AppTheme.primaryColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSavedAddressActive
                ? 'Saved address is selected. Use current location instead to complete details manually.'
                : 'Complete the detected area with house, landmark, and name details.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF787884),
            ),
          ),
          const SizedBox(height: 18),
          if (_isSavedAddressActive) ...[
            OutlinedButton.icon(
              onPressed: _useCurrentLocationFlow,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(
                'Use Current Location Instead',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
          ],
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _isSavedAddressActive ? 0.58 : 1,
            child: IgnorePointer(
              ignoring: _isSavedAddressActive,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _houseController,
                    label: 'House/Flat Number*',
                    hint: 'Required',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _landmarkController,
                    label: 'Landmark (Optional)',
                    hint: 'Nearby landmark',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name (Optional)',
                    hint: 'Address contact name',
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Save as',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF636370),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSaveAsChip('Home'),
                      const SizedBox(width: 10),
                      _buildSaveAsChip('Other'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _proceedToSlots,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'Proceed to Slots',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saved Addresses',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openManageAddresses,
                child: Text(
                  'Manage',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select a previously saved service address. Saved selection always stays the booking source until changed.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF787884),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingSavedAddresses)
            const Center(child: CircularProgressIndicator())
          else if (_savedAddressesError != null)
            _InlineErrorState(
              message: 'Failed to load saved addresses',
              onRetry: _loadSavedAddresses,
            )
          else if (_savedAddresses.isEmpty)
            _EmptySavedAddresses(onAddNew: _openAddAddress)
          else ...[
            for (final address in _savedAddresses) ...[
              _SavedAddressCard(
                address: address,
                isSelected:
                    _isSavedAddressActive &&
                    _selectedSavedAddressId == address.id,
                onTap: () => _selectSavedAddress(address),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _openAddAddress,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.28),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add New Address',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(
          color: const Color(0xFF8B8B97),
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.outfit(
          color: const Color(0xFFC0C0C8),
          fontSize: 13,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Color(0xFF9A9AA4)),
                onPressed: () {
                  controller.clear();
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
        filled: true,
        fillColor: const Color(0xFFFCFCFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E5EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildSaveAsChip(String label) {
    final isSelected = _manualLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _manualLabel = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black87 : const Color(0xFFE1E1E8),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : const Color(0xFF71717E),
          ),
        ),
      ),
    );
  }
}

class _ResolvedAddressSelection {
  final _AddressSource source;
  final String sourceLabel;
  final String label;
  final String fullAddress;
  final String displayAddress;
  final String preview;
  final String houseNumber;
  final String landmark;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? savedAddressId;
  final String city;

  const _ResolvedAddressSelection({
    required this.source,
    required this.sourceLabel,
    required this.label,
    required this.fullAddress,
    required this.displayAddress,
    required this.preview,
    required this.houseNumber,
    required this.landmark,
    required this.name,
    this.latitude,
    this.longitude,
    this.savedAddressId,
    required this.city,
  });
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _SavedAddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (address.label.toLowerCase()) {
      'home' => Icons.home_rounded,
      'work' => Icons.work_rounded,
      _ => Icons.bookmark_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : const Color(0xFFFCFCFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE4E4EC),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.label,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.shortPreview,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF6E6E7A),
                    ),
                  ),
                  if (address.houseNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      address.houseNumber,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF8B8B97),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InlineErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB3261E),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedAddresses extends StatelessWidget {
  final VoidCallback onAddNew;

  const _EmptySavedAddresses({
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No saved addresses yet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add an address from your account and it will appear here for one-tap selection.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF787884),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddNew,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }
}

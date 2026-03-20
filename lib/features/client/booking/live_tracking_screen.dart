import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final response = await ApiService.get('/client/bookings/${widget.bookingId}');

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {
        _booking = Booking.fromJson(response['data'] ?? {});
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = response['message']?.toString() ?? 'Unable to load booking.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Professional'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final booking = _booking;
    final professional = booking?.professional;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.secondaryColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Live tracking will appear here.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  booking?.canTrackProfessional == true
                      ? 'Tracking is enabled for this booking, but the live map rollout is not active yet.'
                      : 'Tracking is not currently available for this booking.',
                  style: const TextStyle(color: AppTheme.greyText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (professional != null && professional.id.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.secondaryColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: professional.photoUrl.isNotEmpty
                        ? NetworkImage(professional.photoUrl)
                        : null,
                    child: professional.photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professional.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          professional.phone.isEmpty
                              ? 'Professional assigned'
                              : professional.phone,
                          style: const TextStyle(color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

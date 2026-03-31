import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../services/professional_api_service.dart';

class ProfessionalScheduleScreen extends StatefulWidget {
  const ProfessionalScheduleScreen({super.key});

  @override
  State<ProfessionalScheduleScreen> createState() =>
      _ProfessionalScheduleScreenState();
}

class _ProfessionalScheduleScreenState
    extends State<ProfessionalScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  // Data
  List<dynamic> _bookings = [];
  bool _morningSlot = true;
  bool _afternoonSlot = true;
  bool _eveningSlot = false;
  bool _loading = true;
  bool _slotsUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  bool get _isToday =>
      DateFormat('yyyy-MM-dd').format(_selectedDate) ==
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final res = await ProfessionalApiService.getSchedule(_dateKey);
      if (mounted && res['success'] == true) {
        final data = (res['data'] as Map?) ?? {};
        final slots = (data['slots'] as Map?) ?? {};
        final rawBookings = data['bookings'];
        setState(() {
          _bookings = rawBookings is List ? List<dynamic>.from(rawBookings) : [];
          _morningSlot   = slots['morning']   == null ? true  : (slots['morning']   == true);
          _afternoonSlot = slots['afternoon'] == null ? true  : (slots['afternoon'] == true);
          _eveningSlot   = slots['evening']   == null ? false : (slots['evening']   == true);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSlot(String slot, bool value) async {
    // Optimistic UI update
    setState(() {
      if (slot == 'morning') _morningSlot = value;
      if (slot == 'afternoon') _afternoonSlot = value;
      if (slot == 'evening') _eveningSlot = value;
      _slotsUpdating = true;
    });

    try {
      await ProfessionalApiService.updateSlots(
        morning:   slot == 'morning'   ? value : null,
        afternoon: slot == 'afternoon' ? value : null,
        evening:   slot == 'evening'   ? value : null,
      );
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          if (slot == 'morning') _morningSlot = !value;
          if (slot == 'afternoon') _afternoonSlot = !value;
          if (slot == 'evening') _eveningSlot = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update slot availability')),
        );
      }
    } finally {
      if (mounted) setState(() => _slotsUpdating = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'started':
      case 'in progress': return Colors.blue;
      default: return AppTheme.primaryColor;
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
            _buildCalendarStrip(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : RefreshIndicator(
                      onRefresh: _loadSchedule,
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(),
                            const SizedBox(height: 20),
                            _buildScheduleSection(),
                            const SizedBox(height: 32),
                          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Schedule',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          if (_slotsUpdating)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadSchedule();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                      fontSize: isToday ? 9 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
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

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isToday ? "Today's Schedule" : DateFormat('EEE, dd MMM').format(_selectedDate),
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_bookings.length} booking${_bookings.length != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(Icons.event_available_outlined, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No bookings for this day',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _bookings
          .whereType<Map>()
          .map((b) => _buildScheduleItem(
                slot: b['slot']?.toString() ?? '',
                service: b['service_name']?.toString() ?? 'Service',
                client: b['customer_name']?.toString() ?? 'Client',
                status: b['status']?.toString() ?? 'Pending',
              ))
          .toList(),
    );
  }

  Widget _buildScheduleItem({
    required String slot,
    required String service,
    required String client,
    required String status,
  }) {
    final isCompleted = status.toLowerCase() == 'completed';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                slot,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: isCompleted
                    ? []
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Client: $client',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          Icon(Icons.check_circle_outline_rounded, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

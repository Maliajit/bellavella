import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/base_widgets.dart';

class ProfessionalAvailabilityScreen extends StatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  State<ProfessionalAvailabilityScreen> createState() => _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState extends State<ProfessionalAvailabilityScreen> {
  bool isAcceptingBookings = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Working Hours')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusToggle(),
            const SizedBox(height: 32),
            const Text('Select Time Slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Set your available hours for tomorrow, 12 Feb.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildTimeSlotGrid(),
            const SizedBox(height: 48),
            PrimaryButton(label: 'Save Changes', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAcceptingBookings ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAcceptingBookings ? 'Online & Accepting' : 'Offline / On Break',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isAcceptingBookings ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
                Text(
                  'Switch off to stop receiving new requests.',
                  style: TextStyle(fontSize: 12, color: isAcceptingBookings ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isAcceptingBookings,
            onChanged: (val) => setState(() => isAcceptingBookings = val),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final time = [
          '09:00 AM', '10:00 AM', '11:00 AM',
          '12:00 PM', '02:00 PM', '03:00 PM',
          '04:00 PM', '05:00 PM', '06:00 PM'
        ][index];
        final isSelected = index < 4 || index == 7; // Mock selection
        return _TimeSlotItem(time: time, isSelected: isSelected);
      },
    );
  }
}

class _TimeSlotItem extends StatelessWidget {
  final String time;
  final bool isSelected;
  const _TimeSlotItem({required this.time, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryColor),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.accentColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

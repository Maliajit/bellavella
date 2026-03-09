import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import '../../controllers/professional_profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class EditWorkingHoursScreen extends StatefulWidget {
  const EditWorkingHoursScreen({super.key});

  @override
  State<EditWorkingHoursScreen> createState() => _EditWorkingHoursScreenState();
}

class _EditWorkingHoursScreenState extends State<EditWorkingHoursScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final Set<String> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfessionalProfileController>().profile;
    if (profile?.workingHours.isNotEmpty == true) {
      final wh = profile!.workingHours;
      if (wh['available_days'] is List) {
        _selectedDays.addAll((wh['available_days'] as List).cast<String>());
      }
      if (wh['start_time'] is String) {
        final parts = (wh['start_time'] as String).split(':');
        if (parts.length == 2) {
          _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
      if (wh['end_time'] is String) {
        final parts = (wh['end_time'] as String).split(':');
        if (parts.length == 2) {
          _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    } else {
      _selectedDays.addAll(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
    }
  }

  Future<void> _selectTime(bool start) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: start ? _startTime : _endTime
    );
    if (picked != null) {
      setState(() {
        if (start) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _save() async {
    final success = await context.read<ProfessionalProfileController>().updateWorkingHours({
      'available_days': _selectedDays.toList(),
      'start_time': '${_startTime.hour}:${_startTime.minute}',
      'end_time': '${_endTime.hour}:${_endTime.minute}',
    });

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Working hours updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Working Hours', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ProfessionalProfileController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Available Days", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _days.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedDays.add(day);
                          else _selectedDays.remove(day);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Text("Available Times", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTimePicker("Start Time", _startTime, () => _selectTime(true))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimePicker("End Time", _endTime, () => _selectTime(false))),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: controller.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

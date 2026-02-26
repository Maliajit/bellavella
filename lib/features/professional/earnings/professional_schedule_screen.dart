import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProfessionalScheduleScreen extends StatefulWidget {
  const ProfessionalScheduleScreen({super.key});

  @override
  State<ProfessionalScheduleScreen> createState() => _ProfessionalScheduleScreenState();
}

class _ProfessionalScheduleScreenState extends State<ProfessionalScheduleScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
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
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarStrip(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Schedule',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildScheduleItem('10:00 AM', 'Glow Glow Facial', 'Anita Sharma', true),
                          _buildScheduleItem('02:30 PM', 'Honey Waxing', 'Priya Gupta', false),
                          _buildScheduleItem('05:00 PM', 'Nail Art', 'Sneha Reddy', false),
                          const SizedBox(height: 30),
                          const Text(
                            'Manage Availability',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          _buildAvailabilityToggle('Morning Slots (9 AM - 12 PM)', true),
                          _buildAvailabilityToggle('Afternoon Slots (12 PM - 4 PM)', true),
                          _buildAvailabilityToggle('Evening Slots (4 PM - 8 PM)', false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _isScrolled ? AppTheme.primaryColor : Colors.white,
        boxShadow: _isScrolled 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: _isScrolled ? Colors.white : Colors.black,
            onPressed: () => context.go('/professional/earnings'),
          ),
          Text(
            'Schedule',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withOpacity(0.2),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected 
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildScheduleItem(String time, String service, String client, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: isCompleted ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service, style: TextStyle(fontWeight: FontWeight.bold, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                      if (isCompleted)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Client: $client', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle(String label, bool isOn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Switch(
            value: isOn,
            onChanged: (val) {},
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

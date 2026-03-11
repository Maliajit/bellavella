import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/features/client/services/client_api_service.dart';

class CheckoutSlotScreen extends StatefulWidget {
  final Map<String, dynamic> addressData;

  const CheckoutSlotScreen({
    super.key,
    required this.addressData,
  });

  @override
  State<CheckoutSlotScreen> createState() => _CheckoutSlotScreenState();
}

class _CheckoutSlotScreenState extends State<CheckoutSlotScreen> {
  static const Color pinkPrimary = Color(0xFFFF4891);
  static const Color pinkLight = Color(0xFFFFF0F5);

  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic> _slotsData = {};
  List<String> _categoriesToBook = [];
  final Map<String, String?> _selectedCategorySlots = {};

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      final response = await ClientApiService.getSlotsFromCart();
      
      if (response['success'] == true) {
        setState(() {
          _slotsData = response['data']['slots'];
          _categoriesToBook = _slotsData.keys.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load slots.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching slots.';
        _isLoading = false;
      });
    }
  }

  void _showDetailedSlotPicker(BuildContext context, String category, String defaultDuration, dynamic backendDates, {VoidCallback? onConfirm}) {
    int activeDateIndex = 0;
    
    // Parse backend dates if provided, otherwise fallback to local 4 days
    List<DateTime> dates = [];
    if (backendDates != null && backendDates is List) {
       for (var dt in backendDates) {
           dates.add(DateTime.parse(dt['date']));
       }
    }

    if (dates.isEmpty) {
        final now = DateTime.now();
        final dayRange = category.toLowerCase().contains('brid') ? 31 : 4;
        dates = List.generate(dayRange, (index) => now.add(Duration(days: index)));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSlotState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Text(
                          'When should the professional arrive?',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Service will take approx. $defaultDuration',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 25),
                        // Date picker
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: dates.length,
                            itemBuilder: (ctx, idx) {
                              final date = dates[idx];
                              // Local fallback logic since full date parsing from backend wasn't fully mocked for slots grid
                              final isToday = idx == 0 && date.day == DateTime.now().day;
                              final isSelected = activeDateIndex == idx;
                              final dayName = isToday ? "Today" : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][date.weekday - 1];
                              
                              return GestureDetector(
                                onTap: () => setSlotState(() => activeDateIndex = idx),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? pinkLight : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? pinkPrimary : Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: isSelected ? pinkPrimary : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${date.day}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? pinkPrimary : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Select start time of service',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        // Time Grid
                        _buildTimeGrid(dates[activeDateIndex], category, setSlotState),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: _selectedCategorySlots[category] != null
                          ? () {
                              Navigator.pop(context);
                              setState(() {}); 
                              if (onConfirm != null) onConfirm();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCategorySlots[category] != null ? pinkPrimary : const Color(0xFFEEEEEE),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedCategorySlots[category] != null ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
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

  Widget _buildTimeGrid(DateTime selectedDate, String category, StateSetter setModalState) {
    final List<DateTime> slotTimes = [];
    DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 0); // 6 AM
    DateTime end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 0); // 11 PM
    
    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      if (selectedDate.day == DateTime.now().day && start.isBefore(DateTime.now())) {
        start = start.add(const Duration(minutes: 30));
        continue;
      }
      slotTimes.add(start);
      start = start.add(const Duration(minutes: 30));
    }

    if (slotTimes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No slots available for today',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: slotTimes.length,
      itemBuilder: (context, index) {
        final time = slotTimes[index];
        final timeLabel = "${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}";
        
        bool isExtra = false;
        if (time.hour < 8 || (time.hour == 21 && time.minute >= 30) || time.hour >= 22) {
          isExtra = true;
        }

        final dayName = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][time.weekday - 1];
        final monthName = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][time.month - 1];
        final selectionKey = "$dayName, $monthName ${selectedDate.day} at $timeLabel";
        final isSelected = _selectedCategorySlots[category] == selectionKey;

        return GestureDetector(
          onTap: () {
            setModalState(() {
              _selectedCategorySlots[category] = selectionKey;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isSelected ? pinkLight : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? pinkPrimary : Colors.grey.shade200),
                ),
                alignment: Alignment.center,
                child: Text(
                  timeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isSelected ? pinkPrimary : Colors.black87,
                  ),
                ),
              ),
              if (isExtra)
                Positioned(
                  top: -8,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+ ₹100',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9A825),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlotServiceCard(String title, String duration, {bool isSelected = false, String? selectedSlot, VoidCallback? onSelect}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? pinkPrimary : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isSelected && selectedSlot != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedSlot,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: pinkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? pinkLight : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? pinkPrimary : Colors.grey.shade300),
              ),
              child: Text(
                isSelected ? 'Change' : 'Select',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? pinkPrimary : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToReview() {
    if (_selectedCategorySlots.length < _categoriesToBook.length) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a slot for all categories.')),
       );
       return;
    }

    final combinedData = {
      'address': widget.addressData['label'],
      'fullAddress': widget.addressData['fullAddress'],
      'houseNumber': widget.addressData['houseNumber'],
      'landmark': widget.addressData['landmark'],
      'name': widget.addressData['name'],
      'slots': _selectedCategorySlots,
    };

    context.push('/client/checkout-review', extra: combinedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Select Slots',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: pinkPrimary))
          : _errorMessage != null 
              ? Center(child: Text(_errorMessage!, style: GoogleFonts.outfit(color: Colors.red)))
              : _categoriesToBook.isEmpty 
                  ? Center(child: Text("Cart is empty.", style: GoogleFonts.outfit()))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: _categoriesToBook.map((category) {
                        final isSelected = _selectedCategorySlots.containsKey(category);
                        final slotInfo = _selectedCategorySlots[category];
                        
                        final catData = _slotsData[category] ?? {};
                        final defaultDuration = category.toLowerCase().contains("salon") ? '1 hr & 30 mins' : '1 hr & 20 mins';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildSlotServiceCard(
                            category,
                            'Service will take approx. $defaultDuration',
                            isSelected: isSelected,
                            selectedSlot: slotInfo,
                            onSelect: () => _showDetailedSlotPicker(
                              context,
                              category,
                              defaultDuration,
                              catData['available_dates']
                            ),
                          ),
                        );
                      }).toList(),
                    ),
      bottomNavigationBar: _isLoading || _errorMessage != null || _categoriesToBook.isEmpty
          ? null 
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ElevatedButton(
                onPressed: _selectedCategorySlots.length == _categoriesToBook.length
                    ? _proceedToReview
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategorySlots.length == _categoriesToBook.length ? pinkPrimary : const Color(0xFFEEEEEE),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm and Review',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedCategorySlots.length == _categoriesToBook.length ? Colors.white : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
    );
  }
}

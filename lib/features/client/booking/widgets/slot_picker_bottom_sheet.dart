import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SlotPickerSelection {
  final DateTime date;
  final String timeLabel;
  final String selectionKey;

  const SlotPickerSelection({
    required this.date,
    required this.timeLabel,
    required this.selectionKey,
  });
}

class SlotPickerBottomSheet {
  static const Color pinkPrimary = Color(0xFFFF4891);
  static const Color pinkLight = Color(0xFFFFF0F5);

  static Future<SlotPickerSelection?> show({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<DateTime> dates,
    String? initialSelectionKey,
    String confirmLabel = 'Confirm',
  }) {
    var activeDateIndex = 0;
    String? selectedKey = initialSelectionKey;

    if (initialSelectionKey != null && initialSelectionKey.isNotEmpty) {
      for (var index = 0; index < dates.length; index++) {
        if (initialSelectionKey.contains('${dates[index].day}')) {
          activeDateIndex = index;
          break;
        }
      }
    }

    return showModalBottomSheet<SlotPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
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
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          itemBuilder: (ctx, idx) {
                            final date = dates[idx];
                            final isToday = _isSameDate(date, DateTime.now());
                            final isSelected = activeDateIndex == idx;
                            final dayName = isToday
                                ? 'Today'
                                : _weekdayLabel(date);

                            return GestureDetector(
                              onTap: () => setState(() => activeDateIndex = idx),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? pinkLight : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? pinkPrimary
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: isSelected
                                            ? pinkPrimary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? pinkPrimary
                                            : Colors.black,
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
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SlotTimeGrid(
                        selectedDate: dates[activeDateIndex],
                        selectedKey: selectedKey,
                        onSelected: (selection) {
                          setState(() => selectedKey = selection.selectionKey);
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: selectedKey == null
                        ? null
                        : () {
                            final selection = _selectionFromKey(
                              dates[activeDateIndex],
                              selectedKey!,
                            );
                            Navigator.pop(context, selection);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedKey != null
                          ? pinkPrimary
                          : const Color(0xFFEEEEEE),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selectedKey != null
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static SlotPickerSelection _selectionFromKey(DateTime date, String key) {
    final parts = key.split(' at ');
    final timeLabel = parts.length > 1 ? parts[1] : '';
    return SlotPickerSelection(
      date: DateTime(date.year, date.month, date.day),
      timeLabel: timeLabel,
      selectionKey: key,
    );
  }

  static String _weekdayLabel(DateTime value) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[value.weekday - 1];
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _SlotTimeGrid extends StatelessWidget {
  final DateTime selectedDate;
  final String? selectedKey;
  final ValueChanged<SlotPickerSelection> onSelected;

  const _SlotTimeGrid({
    required this.selectedDate,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final slotTimes = <DateTime>[];
    var start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6, 0);
    final end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 0);

    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      if (SlotPickerBottomSheet._isSameDate(selectedDate, DateTime.now()) &&
          start.isBefore(DateTime.now())) {
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
        final timeLabel =
            '${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
        final dayName = SlotPickerBottomSheet._weekdayLabel(time);
        final monthName = _monthLabel(time);
        final selectionKey = '$dayName, $monthName ${selectedDate.day} at $timeLabel';
        final isSelected = selectedKey == selectionKey;
        final isExtra = time.hour < 8 ||
            (time.hour == 21 && time.minute >= 30) ||
            time.hour >= 22;

        return GestureDetector(
          onTap: () {
            onSelected(
              SlotPickerSelection(
                date: selectedDate,
                timeLabel: timeLabel,
                selectionKey: selectionKey,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? SlotPickerBottomSheet.pinkLight
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? SlotPickerBottomSheet.pinkPrimary
                        : Colors.grey.shade200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  timeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isSelected
                        ? SlotPickerBottomSheet.pinkPrimary
                        : Colors.black87,
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

  static String _monthLabel(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[value.month - 1];
  }
}

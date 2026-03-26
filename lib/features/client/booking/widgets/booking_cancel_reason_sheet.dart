import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingCancelReasonSelection {
  final String code;
  final String label;
  final String? note;

  const BookingCancelReasonSelection({
    required this.code,
    required this.label,
    this.note,
  });
}

class BookingCancelReasonSheet extends StatefulWidget {
  const BookingCancelReasonSheet({super.key});

  static Future<BookingCancelReasonSelection?> show(BuildContext context) {
    return showModalBottomSheet<BookingCancelReasonSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingCancelReasonSheet(),
    );
  }

  @override
  State<BookingCancelReasonSheet> createState() => _BookingCancelReasonSheetState();
}

class _BookingCancelReasonSheetState extends State<BookingCancelReasonSheet> {
  static const Color pinkPrimary = Color(0xFFFF4891);

  final TextEditingController _noteController = TextEditingController();
  String? _selectedCode;

  static const List<Map<String, String>> _reasons = [
    {'code': 'changed_plan', 'label': 'My plan changed'},
    {'code': 'mistake', 'label': 'I booked by mistake'},
    {'code': 'other_service', 'label': 'I found another service'},
    {'code': 'trust_issue', 'label': 'I am not comfortable with the booking'},
    {'code': 'price', 'label': 'Price is too high'},
    {'code': 'reschedule', 'label': 'I want to reschedule instead'},
    {'code': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedReason = _reasons.cast<Map<String, String>?>().firstWhere(
          (reason) => reason?['code'] == _selectedCode,
          orElse: () => null,
        );
    final requiresNote = _selectedCode == 'other';
    final canConfirm = _selectedCode != null && (!requiresNote || _noteController.text.trim().isNotEmpty);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Why are you cancelling your booking?',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose one reason to continue.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),
              ..._reasons.map((reason) {
                final isSelected = _selectedCode == reason['code'];
                return InkWell(
                  onTap: () => setState(() => _selectedCode = reason['code']),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? pinkPrimary : Colors.grey.shade300,
                        width: isSelected ? 1.6 : 1,
                      ),
                      color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reason['label']!,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? pinkPrimary : Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (requiresNote) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tell us a little more',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey.shade500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: pinkPrimary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Go Back',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canConfirm
                          ? () => Navigator.pop(
                                context,
                                BookingCancelReasonSelection(
                                  code: _selectedCode!,
                                  label: selectedReason?['label'] ?? '',
                                  note: _noteController.text.trim().isEmpty
                                      ? null
                                      : _noteController.text.trim(),
                                ),
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pinkPrimary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Confirm Cancel',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

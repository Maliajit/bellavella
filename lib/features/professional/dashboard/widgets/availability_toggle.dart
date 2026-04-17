import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellavella/core/theme/app_theme.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool>? onChanged;

  const AvailabilityToggle({
    super.key,
    required this.isOnline,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!isOnline) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isOnline 
              ? Colors.green.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: isOnline 
                ? Colors.green.withValues(alpha: 0.25) 
                : Colors.grey.withValues(alpha: 0.2),
            width: onChanged == null ? 0.5 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Background Text
            Positioned.fill(
              child: Row(
                mainAxisAlignment: isOnline ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isOnline ? 12 : 12),
                    child: Text(
                      isOnline ? "ONLINE" : "OFFLINE",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sliding Knob
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              left: isOnline ? 68 : 4,
              top: 4,
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.black).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey.shade400,
                      boxShadow: isOnline ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ] : [],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

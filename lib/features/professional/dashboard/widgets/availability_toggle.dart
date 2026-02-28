import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const AvailabilityToggle({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: SizedBox(
        width: 104, // Default width, can be wrapped in constrained box
        height: 38,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final double knobSize = height - 12; // 6px padding on each side
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isOnline 
                    ? Colors.green.withValues(alpha: 0.15) 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: isOnline 
                      ? Colors.green.withValues(alpha: 0.3) 
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Text Layer
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: isOnline ? 12 : (width - 50), // Approximate text width shift
                    child: Text(
                      isOnline ? "Online" : "Offline",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  // Knob Layer
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: isOnline ? (width - knobSize - 12) : 0,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

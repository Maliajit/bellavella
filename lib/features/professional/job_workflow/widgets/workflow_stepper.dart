import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class WorkflowStepper extends StatelessWidget {
  final int currentStep; // 1 to 5

  const WorkflowStepper({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> steps = ['Arrived', 'Scan Kit', 'Service', 'Payment', 'Complete'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final int stepNum = index + 1;
              final bool isCompleted = stepNum < currentStep;
              final bool isActive = stepNum == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                stepNum.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : Colors.grey.shade500,
                                ),
                              ),
                      ),
                    ),
                    // Connector Line
                    if (index != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final bool isActive = (index + 1) == currentStep;
              return Text(
                steps[index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? Colors.black87 : Colors.grey.shade400,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

import 'package:bellavella/features/client/packages/models/package_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PackageOptionSelectorSheet extends StatelessWidget {
  final String title;
  final List<PackageOption> options;
  final int? selectedOptionId;

  const PackageOptionSelectorSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptionId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.id == selectedOptionId;

                  return ListTile(
                    onTap: () => Navigator.pop(context, option),
                    title: Text(
                      option.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: option.subtitle == null
                        ? null
                        : Text(option.subtitle!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rs ${option.price?.toStringAsFixed(0) ?? '0'}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

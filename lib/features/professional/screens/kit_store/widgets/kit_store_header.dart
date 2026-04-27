import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KitStoreHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const KitStoreHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F7F9),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF111827),
                    size: 22,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kit Store',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Purchase professional tools & kits',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Live Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search kits by name...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFFD1D5DB),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

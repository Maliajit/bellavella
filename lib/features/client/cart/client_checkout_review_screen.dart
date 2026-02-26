import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientCheckoutReviewScreen extends StatelessWidget {
  final Map<String, dynamic> checkoutData;

  const ClientCheckoutReviewScreen({super.key, required this.checkoutData});

  @override
  Widget build(BuildContext context) {
    // Theme colors matching the cart
    const Color pinkPrimary = Color(0xFFFF4891);
    const Color pinkLight = Color(0xFFFFF0F5);

    final addressLabel = checkoutData['address'] as String;
    final fullAddress = checkoutData['fullAddress'] as String;
    final houseNumber = checkoutData['houseNumber'] as String;
    final landmark = checkoutData['landmark'] as String;
    final slots = checkoutData['slots'] as Map<String, String?>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Checkout',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Address Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: pinkLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_outlined, color: pinkPrimary),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              addressLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$houseNumber, $landmark. $fullAddress',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Slots Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: pinkLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.access_time, color: pinkPrimary),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Scheduled Sessions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...slots.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.value ?? 'No slot selected',
                                style: GoogleFonts.outfit(
                                  color: pinkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: ElevatedButton(
          onPressed: () {
            // Future payment logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkPrimary,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Proceed to pay',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

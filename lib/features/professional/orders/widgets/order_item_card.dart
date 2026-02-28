import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final Function(bool) onSwipeAction; // true for positive action, false for negative

  const OrderItemCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onSwipeAction,
  });

  @override
  Widget build(BuildContext context) {
    final String status = order['status'] ?? 'Pending';
    final bool isAccepted = status == 'Accepted';
    final bool isPending = status == 'Pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Dismissible(
          key: Key(order['id']?.toString() ?? UniqueKey().toString()),
          direction: (isPending || isAccepted) 
              ? DismissDirection.horizontal 
              : DismissDirection.none,
          background: _buildSwipeBackground(
            isPending ? "Accept" : "Start", 
            Colors.green, 
            Alignment.centerLeft
          ),
          secondaryBackground: _buildSwipeBackground(
            isPending ? "Reject" : "Cancel", 
            Colors.red, 
            Alignment.centerRight
          ),
          onDismissed: (direction) {
            onSwipeAction(direction == DismissDirection.startToEnd);
          },
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Customer Name & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order['name'] ?? 'Customer',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      _buildStatusPill(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Second Row: Service
                  Text(
                    order['service'] ?? 'Unknown Service',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Third Row: Time • Date
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        "${order['time'] ?? ''} • ${order['date'] ?? ''}",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Fourth Row: Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order['location'] ?? 'Unknown Location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom Row: Price & Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order['price'] ?? '₹0',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black45),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        break;
      case 'Accepted':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'Ongoing':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case 'Completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Cancelled':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(String label, Color color, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      color: color,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

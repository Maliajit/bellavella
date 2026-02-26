import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/utils/location_util.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Theme colors matching the screenshots
  static const Color pinkPrimary = Color(0xFFFF4891);
  static const Color pinkLight = Color(0xFFFFF0F5);
  static const Color greenSaving = Color(0xFF00897B);

  int? _selectedTip;
  
  // Address State
  String _currentAddress = "Fetching location...";
  String _currentArea = "Panchvati";
  bool _isHomeSelected = true;
  final TextEditingController _houseController = TextEditingController(text: "202");
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: "Harsh");
  final TextEditingController _otherLabelController = TextEditingController();

  // Slot Selection State
  final Map<String, String?> _selectedCategorySlots = {};
  final List<String> _cartCategories = ['Salon Luxe', 'Spa for Women', 'Bridle'];

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          setState(() {
            _currentArea = placemark.subLocality ?? placemark.locality ?? "Unknown Area";
            _currentAddress = "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Your cart',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSavingsBanner(),
            _buildCartCategorySection('Salon Prime', [
              _CartItem(
                title: 'Mani-pedi delight',
                price: 1359,
                originalPrice: 1458,
                quantity: 1,
              ),
            ]),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            _buildCartCategorySection('Salon Luxe', [
              _CartItem(
                title: 'Roll-on waxing (Full arms & legs, underarm)',
                price: 1349,
                quantity: 1,
                subtitle: 'Full arms, full legs - Cirepil mojito ro...',
              ),
              _CartItem(
                title: 'Threading',
                quantity: 1,
                isSubGroup: true,
                subItems: [
                  _SubItem(name: 'Threading - Forehead', price: 99),
                  _SubItem(name: 'Threading - Eyebrows', price: 99),
                ],
              ),
              _CartItem(
                title: 'Rejuvenating crystal spa pedicure',
                price: 1369,
                quantity: 1,
                subtitle: 'Rejuvenating crystal spa ...',
              ),
            ]),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            _buildFrequentlyAdded(),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            _buildCouponsSection(),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            _buildTipSection(),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            _buildPolicySection(),
            const SizedBox(height: 100), // Spacer for sticky footer
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyFooter(),
    );
  }

  Widget _buildSavingsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.sell, color: greenSaving, size: 20),
          const SizedBox(width: 12),
          Text(
            'Saving ₹99 on this order',
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCategorySection(String category, List<_CartItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          ...items.map((item) => _buildCartItem(item)),
        ],
      ),
    );
  }

  Widget _buildCartItem(_CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                        ),
                        child: Text(
                          item.subtitle!,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!item.isSubGroup) _buildQuantitySelector(item.quantity),
              if (!item.isSubGroup) ...[
                const SizedBox(width: 15),
                _buildPriceDisplay(item.price!, item.originalPrice),
              ]
            ],
          ),
          if (item.isSubGroup) ...[
            const SizedBox(height: 15),
            ...item.subItems!.map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 12),
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                          ),
                          child: Text(
                            sub.name,
                            style: GoogleFonts.outfit(fontSize: 15, color: Colors.black87),
                          ),
                        ),
                      ),
                      _buildQuantitySelector(1),
                      const SizedBox(width: 15),
                      Text(
                        '₹${sub.price}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: pinkLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pinkPrimary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove, size: 16, color: pinkPrimary),
            onPressed: () {},
          ),
          Text(
            '$quantity',
            style: GoogleFonts.outfit(
              color: pinkPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 16, color: pinkPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(int price, int? originalPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹$price',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (originalPrice != null)
          Text(
            '₹$originalPrice',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _buildFrequentlyAdded() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Frequently added together',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSuggestCard('Threading', '49', 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=400'),
                _buildSuggestCard('Casmara charcoal detox mask', '1,299', 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400'),
                _buildSuggestCard('RIC wax', '69', 'https://images.unsplash.com/photo-1522338242992-e1a54906a8da?q=80&w=400'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestCard(String title, String price, String img) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(img, height: 160, width: 170, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹$price', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text('Add', style: GoogleFonts.outfit(color: pinkPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Icon(Icons.percent, color: greenSaving),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coupons and offers', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Login/Sign up to view offers', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment summary',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _summaryRow('Salon Luxe', '₹2,297'),
          _summaryRow('Spa for Women', '₹1,733'),
          const Divider(height: 30),
          _summaryRow('Total amount', '₹4,030', isBold: true),
          const SizedBox(height: 15),
          _summaryRow('Amount to pay', '₹4,030', isBold: true, largeText: true),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    final tips = [50, 75, 100];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a tip to thank your professionals',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ...tips.map((tip) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTip = tip),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTip == tip ? pinkPrimary.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedTip == tip ? pinkPrimary : Colors.grey.shade300,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '₹$tip',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _selectedTip == tip ? pinkPrimary : Colors.black87,
                              ),
                            ),
                          ),
                          if (tip == 75)
                            Positioned(
                              top: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00695C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Custom',
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tip will be split equally between the professionals.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation & reschedule policy',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'A small fee may apply depending on the service if you cancel or reschedule after a certain time',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Read full policy',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, bool largeText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: largeText ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black : Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: largeText ? 18 : 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        onPressed: () => _showAddressPicker(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: pinkPrimary,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'Add address and slot',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddressPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Map Section
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1526778446212-04fa3e4f3a73?q=80&w=1000'),
                            fit: BoxFit.cover,
                            opacity: 0.3,
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.location_on, color: pinkPrimary, size: 50),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Place the pin accurately on map',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: Icon(Icons.my_location, color: pinkPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details Section
                Expanded(
                  flex: 5,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentArea,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentAddress,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Change',
                              style: GoogleFonts.outfit(
                                color: pinkPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 40),
                      _buildTextField(_houseController, 'House/Flat Number*', isRequired: true),
                      const SizedBox(height: 15),
                      _buildTextField(_landmarkController, 'Landmark (Optional)'),
                      const SizedBox(height: 15),
                      _buildTextField(_nameController, 'Name'),
                      const SizedBox(height: 25),
                      Text(
                        'Save as',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSaveAsChip('Home', _isHomeSelected, () => setModalState(() => _isHomeSelected = true)),
                          const SizedBox(width: 12),
                          _buildSaveAsChip('Other', !_isHomeSelected, () => setModalState(() => _isHomeSelected = false)),
                        ],
                      ),
                      if (!_isHomeSelected) ...[
                        const SizedBox(height: 15),
                        _buildTextField(_otherLabelController, 'e.g. John\'s Home'),
                      ],
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSlotsPicker(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pinkPrimary,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Save and proceed to slots',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSlotsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSlotsState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select slots',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: const Icon(Icons.close, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ..._cartCategories.map((category) {
                final isSelected = _selectedCategorySlots.containsKey(category);
                final slotInfo = _selectedCategorySlots[category];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildSlotServiceCard(
                    category,
                    category == 'Salon Luxe' ? 'Service will take approx. 1 hr & 30 mins' : 'Service will take approx. 1 hr & 20 mins',
                    isSelected: isSelected,
                    selectedSlot: slotInfo,
                    onSelect: () => _showDetailedSlotPicker(
                      context,
                      category,
                      category == 'Salon Luxe' ? '1 hr & 30 mins' : '1 hr & 20 mins',
                      onConfirm: () => setSlotsState(() {}),
                    ),
                  ),
                );
              }),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedCategorySlots.length == _cartCategories.length
                    ? () {
                        Navigator.pop(context);
                        context.push('/client/checkout-review', extra: {
                          'address': _isHomeSelected ? 'Home' : _otherLabelController.text,
                          'fullAddress': _currentAddress,
                          'houseNumber': _houseController.text,
                          'landmark': _landmarkController.text,
                          'slots': _selectedCategorySlots,
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategorySlots.length == _cartCategories.length ? pinkPrimary : const Color(0xFFEEEEEE),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedCategorySlots.length == _cartCategories.length ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedSlotPicker(BuildContext context, String category, String duration, {VoidCallback? onConfirm}) {
    int activeDateIndex = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSlotState) {
          final now = DateTime.now();
          final dayRange = category == 'Bridle' ? 31 : 4;
          final dates = List.generate(dayRange, (index) => now.add(Duration(days: index)));
          
          // Initial selection if not set
          DateTime? selectedDate;
          // Find if we already have a selection for this category to highlight it
          // For simplicity in the modal, we'll use a local state for the date picker
          // and if they confirmed before, we could pre-select. 
          // Let's use index-based for the 4 days.

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
                          'Service will take approx. $duration',
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
                              final isToday = idx == 0;
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
                              // Trigger a rebuild of the parent slots picker
                              setState(() {}); 
                              if (onConfirm != null) onConfirm!();
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
      // Filter out past slots for today
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
        
        // Rule: First 4 slots (6:00, 6:30, 7:00, 7:30) and Last 4 (6:30 PM, 7:00 PM, 7:30 PM, 8:00 PM) have extra charge
        // Let's be precise: 
        // Early: 06:00, 06:30, 07:00, 07:30
        // Late: 18:30, 19:00, ... 23:00 (6:30 PM to 11:00 PM) have extra charge
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
            // Also notify parent if needed, but setState in setModalState is enough for modal
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

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
        floatingLabelStyle: GoogleFonts.outfit(color: pinkPrimary, fontSize: 13),
        suffixIcon: IconButton(
          icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
          onPressed: () => controller.clear(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: pinkPrimary),
        ),
      ),
    );
  }

  Widget _buildSaveAsChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// Helper models for mock data structures
class _CartItem {
  final String title;
  final String? subtitle;
  final int? price;
  final int? originalPrice;
  final int quantity;
  final bool isSubGroup;
  final List<_SubItem>? subItems;

  _CartItem({
    required this.title,
    this.subtitle,
    this.price,
    this.originalPrice,
    required this.quantity,
    this.isSubGroup = false,
    this.subItems,
  });
}

class _SubItem {
  final String name;
  final int price;
  _SubItem({required this.name, required this.price});
}

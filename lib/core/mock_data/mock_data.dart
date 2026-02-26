import '../models/data_models.dart';

final List<Category> mockCategories = [
  Category(id: 'ac', name: 'AC Repair', iconPath: 'https://cdn-icons-png.flaticon.com/512/954/954031.png'),
  Category(id: 'salon', name: 'Salon', iconPath: 'https://cdn-icons-png.flaticon.com/512/2911/2911360.png'),
  Category(id: 'cleaning', name: 'Cleaning', iconPath: 'https://cdn-icons-png.flaticon.com/512/995/995053.png'),
  Category(id: 'plumbing', name: 'Plumbing', iconPath: 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png'),
  Category(id: 'electric', name: 'Electrician', iconPath: 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png'),
  Category(id: 'painting', name: 'Painting', iconPath: 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png'),
];

final List<Service> mockServices = [
  Service(
    id: 's1',
    categoryId: 'ac',
    name: 'AC Repair',
    description: 'Professional AC servicing and repair.',
    price: 499.0,
    duration: '60 min',
    includedItems: ['Cleaning', 'Gas Check'],
    imageUrl: 'https://images.unsplash.com/photo-1581094288338-2314dddb7bc3?q=80&w=500',
  ),
  Service(
    id: 's2',
    categoryId: 'salon',
    name: 'Salon',
    description: 'Home salon services for men and women.',
    price: 999.0,
    duration: '90 min',
    includedItems: ['Haircut', 'Facial'],
    imageUrl: 'https://images.unsplash.com/photo-1560750584-23e9cb3d3df0?q=80&w=500',
  ),
];

final List<Booking> mockBookings = [
  Booking(
    id: 'b1',
    service: mockServices[0],
    dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    address: '123, Rose Villa, Sector 5, Mumbai',
    status: BookingStatus.accepted,
    totalPrice: 1200.0,
  ),
];

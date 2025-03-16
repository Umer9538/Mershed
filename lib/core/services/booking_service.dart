import 'package:mershed/core/models/hotel.dart';

class BookingService {
  // Mock hotel data (replace with real API call)
  Future<List<Hotel>> getHotels(String destination) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      Hotel(id: '1', name: 'Riyadh Hotel', location: 'Riyadh', pricePerNight: 500.0),
      Hotel(id: '2', name: 'Jeddah Resort', location: 'Jeddah', pricePerNight: 700.0),
    ];
  }

  Future<bool> bookHotel(String hotelId, String userId) async {
    // Simulate booking
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
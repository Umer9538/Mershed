import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mershed/core/models/hotel.dart';
import 'package:mershed/core/models/restaurant.dart';
import 'package:mershed/core/models/activity.dart';
import 'package:mershed/core/booking_category.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookingService {
  final String _amadeusBaseUrl = 'https://api.amadeus.com'; // Updated to production URL
  final CollectionReference _bookingsCollection =
  FirebaseFirestore.instance.collection('bookings');

  // Load Amadeus credentials from .env
  String get _amadeusApiKey => dotenv.env['AMADEUS_API_KEY'] ?? '';
  String get _amadeusApiSecret => dotenv.env['AMADEUS_API_SECRET'] ?? '';

  // City name to IATA code mapping for Saudi Arabia
  final Map<String, String> _cityToIataCode = {
    'riyadh': 'RUH',
    'jeddah': 'JED',
    'mecca': 'MKK',
    'medina': 'MED',
    'dammam': 'DMM',
    'abha': 'AHB',
  };

  // Convert city name to IATA code
  String _getIataCode(String city) {
    String normalizedCity = city.toLowerCase().trim();
    return _cityToIataCode[normalizedCity] ?? city.toUpperCase();
  }

  // Get Amadeus access token
  Future<String> _getAmadeusToken() async {
    if (_amadeusApiKey.isEmpty || _amadeusApiSecret.isEmpty) {
      throw Exception('Amadeus API credentials are missing in .env file');
    }

    print('Using AMADEUS_API_KEY: $_amadeusApiKey'); // Debugging
    print('Using AMADEUS_API_SECRET: $_amadeusApiSecret'); // Debugging

    final response = await http.post(
      Uri.parse('$_amadeusBaseUrl/v1/security/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body:
      'grant_type=client_credentials&client_id=$_amadeusApiKey&client_secret=$_amadeusApiSecret',
    );
    print('Token request response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('Failed to get Amadeus token: ${response.body}');
    }
  }

  // Fetch hotels using Amadeus API
  Future<List<Hotel>> getHotels(String destination,
      {DateTime? checkInDate, DateTime? checkOutDate}) async {
    try {
      final token = await _getAmadeusToken();
      final checkIn = checkInDate ?? DateTime.now().add(Duration(days: 1));
      final checkOut = checkOutDate ?? checkIn.add(Duration(days: 1));

      // Validate check-in and check-out dates
      if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
        throw Exception('Check-out date must be after check-in date');
      }

      // Convert destination to IATA code
      String cityCode = _getIataCode(destination);
      final url = Uri.parse(
          '$_amadeusBaseUrl/v2/shopping/hotel-offers?cityCode=$cityCode&checkInDate=${checkIn.toIso8601String().split('T')[0]}&checkOutDate=${checkOut.toIso8601String().split('T')[0]}');
      print('Hotel request URL: $url');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Hotel response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hotels = (data['data'] as List? ?? []).map((hotel) {
          final price = hotel['offers'] != null && hotel['offers'].isNotEmpty
              ? double.tryParse(hotel['offers'][0]['price']['total'] ?? '0') ?? 0
              : 0;
          final nights = checkOut.difference(checkIn).inDays;
          return Hotel(
            id: hotel['hotel']['hotelId'].toString(),
            name: hotel['hotel']['name'] ?? 'Unknown Hotel',
            location: hotel['hotel']['cityCode'] ?? destination,
            pricePerNight: price / nights,
          );
        }).toList();
        return hotels;
      } else if (response.statusCode == 404) {
        print('No hotels found for $destination: ${response.body}');
        return _getFallbackHotels(destination);
      } else {
        print('Failed to load hotels: ${response.statusCode} - ${response.body}');
        return _getFallbackHotels(destination);
      }
    } catch (e) {
      print('Error in getHotels: $e');
      return _getFallbackHotels(destination);
    }
  }

  // Helper method to provide fallback data for Saudi Arabia cities
  List<Hotel> _getFallbackHotels(String destination) {
    final String location = _getIataCode(destination);

    if (location == 'RUH') {
      return [
        Hotel(
          id: 'RUH-001',
          name: 'Riyadh Season Hotel',
          location: 'Riyadh',
          pricePerNight: 300.0,
        ),
        Hotel(
          id: 'RUH-002',
          name: 'Al Rajhi Grand Hotel',
          location: 'Riyadh',
          pricePerNight: 400.0,
        ),
        Hotel(
          id: 'RUH-003',
          name: 'Kingdom Centre Hotel',
          location: 'Riyadh',
          pricePerNight: 350.0,
        ),
      ];
    } else if (location == 'JED') {
      return [
        Hotel(
          id: 'JED-001',
          name: 'Jeddah Hilton',
          location: 'Jeddah',
          pricePerNight: 320.0,
        ),
        Hotel(
          id: 'JED-002',
          name: 'Rosewood Jeddah',
          location: 'Jeddah',
          pricePerNight: 380.0,
        ),
        Hotel(
          id: 'JED-003',
          name: 'Park Hyatt Jeddah',
          location: 'Jeddah',
          pricePerNight: 340.0,
        ),
      ];
    } else if (location == 'MKK') {
      return [
        Hotel(
          id: 'MKK-001',
          name: 'Mecca Royal Clock Tower',
          location: 'Mecca',
          pricePerNight: 450.0,
        ),
        Hotel(
          id: 'MKK-002',
          name: 'Pullman ZamZam Makkah',
          location: 'Mecca',
          pricePerNight: 400.0,
        ),
        Hotel(
          id: 'MKK-003',
          name: 'Hilton Suites Makkah',
          location: 'Mecca',
          pricePerNight: 420.0,
        ),
      ];
    } else if (location == 'MED') {
      return [
        Hotel(
          id: 'MED-001',
          name: 'Dar Al Taqwa Hotel',
          location: 'Medina',
          pricePerNight: 380.0,
        ),
        Hotel(
          id: 'MED-002',
          name: 'Anwar Al Madinah Mövenpick',
          location: 'Medina',
          pricePerNight: 350.0,
        ),
        Hotel(
          id: 'MED-003',
          name: 'The Oberoi Madinah',
          location: 'Medina',
          pricePerNight: 400.0,
        ),
      ];
    } else if (location == 'DMM') {
      return [
        Hotel(
          id: 'DMM-001',
          name: 'Sheraton Dammam Hotel',
          location: 'Dammam',
          pricePerNight: 280.0,
        ),
        Hotel(
          id: 'DMM-002',
          name: 'Park Inn by Radisson Dammam',
          location: 'Dammam',
          pricePerNight: 250.0,
        ),
        Hotel(
          id: 'DMM-003',
          name: 'Dammam Palace Hotel',
          location: 'Dammam',
          pricePerNight: 270.0,
        ),
      ];
    } else if (location == 'AHB') {
      return [
        Hotel(
          id: 'AHB-001',
          name: 'Abha Palace Hotel',
          location: 'Abha',
          pricePerNight: 260.0,
        ),
        Hotel(
          id: 'AHB-002',
          name: 'InterContinental Abha',
          location: 'Abha',
          pricePerNight: 290.0,
        ),
        Hotel(
          id: 'AHB-003',
          name: 'Blue Inn Boutique Hotel',
          location: 'Abha',
          pricePerNight: 240.0,
        ),
      ];
    } else {
      return [
        Hotel(
          id: '$location-001',
          name: 'Grand Hotel $location',
          location: destination,
          pricePerNight: 250.0,
        ),
        Hotel(
          id: '$location-002',
          name: 'Plaza $location',
          location: destination,
          pricePerNight: 200.0,
        ),
        Hotel(
          id: '$location-003',
          name: 'Luxury Inn $location',
          location: destination,
          pricePerNight: 175.0,
        ),
      ];
    }
  }

  // Fetch restaurants (placeholder)
  Future<List<Restaurant>> getRestaurants(String destination) async {
    throw UnimplementedError('Restaurant API integration pending');
  }

  // Fetch activities (placeholder)
  Future<List<Activity>> getActivities(String destination) async {
    throw UnimplementedError('Activity API integration pending');
  }

  // Book a hotel (using Firestore, no Amadeus token needed)
  Future<bool> bookItem(String itemId, String userId,
      {required BookingCategory type,
        required DateTime checkInDate,
        required DateTime checkOutDate,
        required int guests,
        required double totalPrice}) async {
    if (type != BookingCategory.hotels) {
      throw UnimplementedError('Only hotel booking is implemented');
    }

    try {
      final bookingId = 'AMA-${DateTime.now().millisecondsSinceEpoch}';
      await _bookingsCollection.doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'itemId': itemId,
        'type': type.toString().split('.').last,
        'checkInDate': Timestamp.fromDate(checkInDate),
        'checkOutDate': Timestamp.fromDate(checkOutDate),
        'guests': guests,
        'totalPrice': totalPrice,
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
      });
      print('Booking successful: $bookingId'); // Debugging
      return true;
    } catch (e) {
      print('Error booking item: $e');
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({'status': 'cancelled'});
      print('Booking cancelled: $bookingId'); // Debugging
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mershed/core/models/hotel.dart';

class BookingService {
  final String _rapidApiKey = 'ce933af03amshabbc6a35511223dp1a748djsn095433b0ec40';
  final String _rapidApiHost = 'hotels-com-provider.p.rapidapi.com';
  final String _rapidApiBaseUrl = 'https://hotels-com-provider.p.rapidapi.com';
  String _selectedDomain = 'CN';
  String _selectedLocale = 'en_US';

  final CollectionReference _bookingsCollection =
  FirebaseFirestore.instance.collection('bookings');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Fetch hotels using Hotels.com Provider API
  Future<List<Hotel>> getHotels(String destination,
      {DateTime? checkInDate, DateTime? checkOutDate}) async {
    try {
      final checkIn = checkInDate ?? DateTime.now().add(Duration(days: 1));
      final checkOut = checkOutDate ?? checkIn.add(Duration(days: 1));

      if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
        throw Exception('Check-out date must be after check-in date');
      }

      final regionId = await _getRegionId(destination);

      final url = Uri.parse(
          '$_rapidApiBaseUrl/v2/hotels/search'
              '?domain=$_selectedDomain'
              '&sort_order=RECOMMENDED'
              '&region_id=$regionId'
              '&checkin_date=${checkIn.toIso8601String().split('T')[0]}'
              '&checkout_date=${checkOut.toIso8601String().split('T')[0]}'
              '&adults_number=1'
              '&currency=SAR'
              '&locale=$_selectedLocale');
      print('Hotel request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': _rapidApiKey,
          'X-RapidAPI-Host': _rapidApiHost,
        },
      );
      print('Hotel response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Hotel search response data: $data'); // Debug log

        // Debug the properties field
        print('Properties field: ${data['properties']}');

        // Treat 'properties' as a list directly
        final hotelsList = (data['properties'] as List? ?? []).map((hotel) {
          // Log price-related fields to inspect the response
          print('Hotel price fields: mapMarker=${hotel['mapMarker']}, price=${hotel['price']}');

          // Price is in mapMarker.label (e.g., "CNY965"), so we extract it
          final priceLabel = hotel['mapMarker']?['label']?.toString() ?? '0';
          final priceString = priceLabel.replaceAll(RegExp(r'[^0-9]'), ''); // Extract digits
          var price = double.tryParse(priceString) ?? 0;

          // Check if the price is in CNY and convert to SAR if necessary
          if (priceLabel.startsWith('CNY')) {
            // Approximate conversion rate (as of March 2025, 1 CNY ≈ 0.53 SAR)
            const cnyToSarRate = 0.53;
            price = price * cnyToSarRate;
            print('Converted price from CNY to SAR: $priceLabel -> $price SAR');
          }

          final nights = checkOut.difference(checkIn).inDays;

          return Hotel(
            id: hotel['id']?.toString() ?? '',
            name: hotel['name'] ?? 'Unknown Hotel',
            location: hotel['neighborhood']?['name'] ?? destination,
            pricePerNight: price / nights,
            photos: hotel['propertyImage']?['image'] != null
                ? [hotel['propertyImage']['image']['url']?.toString() ?? '']
                : null,
            reviews: hotel['guestReviews'] != null
                ? (hotel['guestReviews'] as List)
                .map((review) => review['text']?.toString() ?? '')
                .toList()
                : null,
          );
        }).toList();
        print('Parsed hotels: $hotelsList'); // Debug log
        return hotelsList;
      } else {
        print('Failed to load hotels: ${response.statusCode} - ${response.body}');
        return _getFallbackHotels(destination);
      }
    } catch (e) {
      print('Error in getHotels: $e');
      return _getFallbackHotels(destination);
    }
  }

  // Fetch hotel details using Hotels.com Provider API
  Future<Hotel> getHotelDetails(String hotelId, String destination) async {
    try {
      final url = Uri.parse(
          '$_rapidApiBaseUrl/v2/hotels/details'
              '?domain=$_selectedDomain'
              '&hotel_id=$hotelId'
              '&locale=$_selectedLocale');
      print('Hotel details request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': _rapidApiKey,
          'X-RapidAPI-Host': _rapidApiHost,
        },
      );
      print('Hotel details response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'] as Map<String, dynamic>? ?? {};

        return Hotel(
          id: hotelId,
          name: summary['name']?.toString() ?? 'Unknown Hotel',
          location: summary['address']?['city']?.toString() ?? destination,
          pricePerNight: 0, // Price not available in details response, use from search
          photos: summary['images'] != null
              ? (summary['images'] as List)
              .map((img) => img['url']?.toString() ?? '')
              .toList()
              : null,
          reviews: summary['reviews'] != null
              ? (summary['reviews'] as List)
              .map((review) => review['text']?.toString() ?? '')
              .toList()
              : null,
        );
      } else {
        throw Exception('Failed to load hotel details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getHotelDetails: $e');
      return Hotel(
        id: hotelId,
        name: 'Unknown Hotel',
        location: destination,
        pricePerNight: 0,
      );
    }
  }

  // Book a hotel and save to Firestore
  Future<bool> bookHotel({
    required String hotelId,
    required String userId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guests,
    required double totalPrice,
    required String destination,
  }) async {
    try {
      // Log the userId and authentication state
      final currentUser = FirebaseAuth.instance.currentUser;
      print('Booking hotel for userId: $userId');
      print('Current authenticated user: ${currentUser?.uid}');

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      if (userId != currentUser.uid) {
        throw Exception('userId ($userId) does not match authenticated user (${currentUser.uid})');
      }

      final hotel = await getHotelDetails(hotelId, destination);

      final bookingId = 'BOOK-${DateTime.now().millisecondsSinceEpoch}';
      await _bookingsCollection.doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'hotelId': hotelId,
        'hotelDetails': hotel.toMap(),
        'type': 'hotels',
        'checkInDate': Timestamp.fromDate(checkInDate),
        'checkOutDate': Timestamp.fromDate(checkOutDate),
        'guests': guests,
        'totalPrice': totalPrice,
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
      });
      print('Booking successful: $bookingId');

      hotel.bookingId = bookingId;
      return true;
    } catch (e) {
      print('Error booking hotel: $e');
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({'status': 'cancelled'});
      print('Booking cancelled: $bookingId');
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Modify a booking
  Future<bool> modifyBooking({
    required String bookingId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    double? totalPrice,
  }) async {
    try {
      // Fetch the existing booking
      final bookingDoc = await _bookingsCollection.doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found: $bookingId');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final currentStatus = bookingData['status'] as String?;
      if (currentStatus == 'cancelled') {
        throw Exception('Cannot modify a cancelled booking: $bookingId');
      }

      // Fetch hotel details to recalculate price if dates change
      final hotelId = bookingData['hotelId'] as String;
      final destination = bookingData['hotelDetails']['location'] as String;
      final hotel = await getHotelDetails(hotelId, destination);

      // Prepare the updated fields
      final updatedFields = <String, dynamic>{};

      DateTime newCheckInDate = checkInDate ?? (bookingData['checkInDate'] as Timestamp).toDate();
      DateTime newCheckOutDate = checkOutDate ?? (bookingData['checkOutDate'] as Timestamp).toDate();
      int newGuests = guests ?? (bookingData['guests'] as int);

      if (checkInDate != null) {
        updatedFields['checkInDate'] = Timestamp.fromDate(checkInDate);
      }
      if (checkOutDate != null) {
        updatedFields['checkOutDate'] = Timestamp.fromDate(checkOutDate);
      }
      if (guests != null) {
        updatedFields['guests'] = guests;
      }

      // Recalculate totalPrice if dates change or if totalPrice is provided
      if (checkInDate != null || checkOutDate != null || totalPrice != null) {
        if (totalPrice != null) {
          updatedFields['totalPrice'] = totalPrice;
        } else {
          final nights = newCheckOutDate.difference(newCheckInDate).inDays;
          if (nights <= 0) {
            throw Exception('Check-out date must be after check-in date');
          }
          updatedFields['totalPrice'] = hotel.pricePerNight * nights * newGuests;
        }
      }

      // Only update if there are fields to modify
      if (updatedFields.isNotEmpty) {
        updatedFields['updatedAt'] = Timestamp.now();
        await _bookingsCollection.doc(bookingId).update(updatedFields);
        print('Booking modified successfully: $bookingId');
      } else {
        print('No fields to modify for booking: $bookingId');
      }

      return true;
    } catch (e) {
      print('Error modifying booking: $e');
      return false;
    }
  }

  // Fetch user's bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  // Helper method to get region ID
  Future<String> _getRegionId(String destination) async {
    final url = Uri.parse(
        '$_rapidApiBaseUrl/v2/regions?query=$destination&domain=$_selectedDomain&locale=$_selectedLocale');
    print('Region request URL: $url');

    final response = await http.get(
      url,
      headers: {
        'X-RapidAPI-Key': _rapidApiKey,
        'X-RapidAPI-Host': _rapidApiHost,
      },
    );
    print('Region response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final regions = data['data'] as List? ?? [];
      if (regions.isNotEmpty) {
        return regions[0]['gaiaId']?.toString() ?? '3051'; // Default to Riyadh if not found
      }
    }
    return '3051'; // Default to Riyadh
  }

  // Fallback hotels in case of API failure
  List<Hotel> _getFallbackHotels(String destination) {
    return [
      Hotel(
        id: 'fallback1',
        name: 'Fallback Hotel 1',
        location: destination,
        pricePerNight: 500,
        photos: ['https://via.placeholder.com/300x200?text=Fallback+Hotel+1'],
      ),
      Hotel(
        id: 'fallback2',
        name: 'Fallback Hotel 2',
        location: destination,
        pricePerNight: 600,
        photos: ['https://via.placeholder.com/300x200?text=Fallback+Hotel+2'],
      ),
    ];
  }
  /////
// Mock data for restaurants
  List<Map<String, dynamic>> _getFallbackRestaurants(String destination) {
    return [
      {
        'id': 'rest1',
        'name': 'Tasty Bites',
        'location': destination,
        'price': 150.0,
        'type': 'restaurants',
        'photos': ['https://via.placeholder.com/300x200?text=Tasty+Bites+Restaurant'],
        'description': 'A cozy restaurant offering local cuisine.',
      },
      {
        'id': 'rest2',
        'name': 'Spice Haven',
        'location': destination,
        'price': 200.0,
        'type': 'restaurants',
        'photos': ['https://via.placeholder.com/300x200?text=Spice+Haven+Restaurant'],
        'description': 'Authentic flavors in a modern setting.',
      },
    ];
  }

  // Mock data for activities
  List<Map<String, dynamic>> _getFallbackActivities(String destination) {
    return [
      {
        'id': 'act1',
        'name': 'Desert Safari',
        'location': destination,
        'price': 300.0,
        'type': 'activities',
        'photos': ['https://via.placeholder.com/300x200?text=Desert+Safari'],
        'description': 'An adventurous ride through the dunes.',
      },
      {
        'id': 'act2',
        'name': 'City Tour',
        'location': destination,
        'price': 250.0,
        'type': 'activities',
        'photos': ['https://via.placeholder.com/300x200?text=City+Tour'],
        'description': 'Explore the city’s landmarks.',
      },
    ];
  }

  // Fetch restaurants (mock implementation)
  Future<List<Map<String, dynamic>>> getRestaurants(String destination) async {
    try {
      // Simulate an API call delay
      await Future.delayed(Duration(seconds: 1));
      return _getFallbackRestaurants(destination);
    } catch (e) {
      print('Error fetching restaurants: $e');
      return _getFallbackRestaurants(destination);
    }
  }

  // Fetch activities (mock implementation)
  Future<List<Map<String, dynamic>>> getActivities(String destination) async {
    try {
      // Simulate an API call delay
      await Future.delayed(Duration(seconds: 1));
      return _getFallbackActivities(destination);
    } catch (e) {
      print('Error fetching activities: $e');
      return _getFallbackActivities(destination);
    }
  }

  // Book a restaurant or activity
  Future<bool> bookItem({
    required String itemId,
    required String userId,
    required String type, // 'restaurants' or 'activities'
    required double totalPrice,
    required String destination,
    DateTime? date, // Optional for activities/restaurants
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || userId != currentUser.uid) {
        throw Exception('Authentication mismatch');
      }

      final mockData = type == 'restaurants'
          ? _getFallbackRestaurants(destination)
          : _getFallbackActivities(destination);
      final item = mockData.firstWhere((i) => i['id'] == itemId, orElse: () => {});

      if (item.isEmpty) {
        throw Exception('Item not found');
      }

      final bookingId = 'BOOK-${DateTime.now().millisecondsSinceEpoch}';
      await _bookingsCollection.doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'itemId': itemId,
        'itemDetails': item,
        'type': type,
        'date': date != null ? Timestamp.fromDate(date) : null,
        'totalPrice': totalPrice,
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
      });
      print('Booking successful: $bookingId for $type');
      // Add booking confirmation notification
      await _usersCollection.doc(userId).collection('notifications').add({
        'title': 'Booking Confirmed',
        'message': 'Your $type booking for ${item['name']} is confirmed!',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'booking',
        'bookingId': bookingId,
      });
      print('Notification added for $type booking: $bookingId');
      return true;
    } catch (e) {
      print('Error booking $type: $e');
      return false;
    }
  }
///////////



// Inside BookingService class
  List<Map<String, dynamic>> _getFallbackDestinations(String query) {
    final destinations = [
      {
        'id': 'dest1',
        'name': 'Riyadh',
        'location': 'Riyadh, Saudi Arabia',
        'rating': 4.5,
        'type': 'destination',
        'photos': ['https://via.placeholder.com/300x200?text=Riyadh+Destination'],
        'description': 'The vibrant capital city of Saudi Arabia.',
      },
      {
        'id': 'dest2',
        'name': 'Jeddah',
        'location': 'Jeddah, Saudi Arabia',
        'rating': 4.7,
        'type': 'destination',
        'photos': ['https://via.placeholder.com/300x200?text=Jeddah+Destination'],
        'description': 'A historic port city on the Red Sea.',
      },
      {
        'id': 'dest3',
        'name': 'Mecca',
        'location': 'Mecca, Saudi Arabia',
        'rating': 5.0,
        'type': 'destination',
        'photos': ['https://via.placeholder.com/300x200?text=Mecca+Destination'],
        'description': 'The holiest city in Islam.',
      },
    ];

    // Filter based on query (case-insensitive)
    final filtered = destinations
        .where((dest) =>
    dest['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
        dest['location'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    // If no matches, return all destinations to ensure something is shown
    final result = filtered.isNotEmpty ? filtered : destinations;
    print('Filtered Destinations for query "$query": $result');
    return result;
  }

  Future<List<Map<String, dynamic>>> getDestinations(String query) async {
    try {
      await Future.delayed(Duration(seconds: 1));
      final result = _getFallbackDestinations(query);
      print('Destinations fetched: $result');
      return result;
    } catch (e) {
      print('Error fetching destinations: $e');
      return _getFallbackDestinations(query);
    }
  }

}


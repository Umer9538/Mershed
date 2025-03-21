import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CarRentalLocation {
  final String name;
  final String address;
  final latlong.LatLng location;
  final int availableCars;
  final double pricePerDay;

  CarRentalLocation({
    required this.name,
    required this.address,
    required this.location,
    required this.availableCars,
    required this.pricePerDay,
  });
}

class CarRentalService {
  final String _amadeusApiKey = dotenv.env['AMADEUS_API_KEY'] ?? '';
  final String _amadeusApiSecret = dotenv.env['AMADEUS_API_SECRET'] ?? '';

  // Step 1: Generate access token
  Future<String> _getAccessToken() async {
    if (_amadeusApiKey.isEmpty || _amadeusApiSecret.isEmpty) {
      throw Exception('Amadeus API key or secret is missing in .env file');
    }

    const url = 'https://test.api.amadeus.com/v1/security/oauth2/token';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': _amadeusApiKey,
        'client_secret': _amadeusApiSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get Amadeus access token: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['access_token'];
  }

  // Step 2: Fetch car rental locations
  Future<List<CarRentalLocation>> getCarRentalLocations() async {
    // Get access token
    final accessToken = await _getAccessToken();

    // Example: Fetch car rentals in Riyadh (latitude: 24.7136, longitude: 46.6753)
    // Pick-up and drop-off dates (current date + 1 day for testing)
    final pickUpDateTime = DateTime.now().toIso8601String().split('.')[0];
    final dropOffDateTime = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .split('.')[0];

    final url = Uri.parse(
      'https://test.api.amadeus.com/v1/shopping/availability/car-rental'
          '?pickUpLocation.latitude=24.7136'
          '&pickUpLocation.longitude=46.6753'
          '&pickUpLocation.radius=50'
          '&pickUpDateTime=$pickUpDateTime'
          '&dropOffDateTime=$dropOffDateTime',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch car rental locations: ${response.body}');
    }

    final data = jsonDecode(response.body)['data'] as List<dynamic>;
    return data.map((item) {
      final provider = item['provider'];
      final location = item['location'];
      final offers = item['offers'] as List<dynamic>;

      // Assuming the first offer for pricing
      final pricePerDay = offers.isNotEmpty
          ? double.parse(offers[0]['price']['total'])
          : 0.0;

      return CarRentalLocation(
        name: provider['company_name'] ?? 'Unknown Provider',
        address: location['address'] ?? 'Unknown Address',
        location: latlong.LatLng(
          location['latitude'] ?? 24.7136,
          location['longitude'] ?? 46.6753,
        ),
        availableCars: offers.length, // Number of available car offers
        pricePerDay: pricePerDay,
      );
    }).toList();
  }
}
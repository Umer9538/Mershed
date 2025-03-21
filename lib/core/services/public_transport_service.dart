import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Updated import
import 'package:latlong2/latlong.dart' as latlong;

class PublicTransportRoute {
  final String summary;
  final List<latlong.LatLng> polylinePoints;
  final String duration;
  final String distance;
  final List<String> instructions;

  PublicTransportRoute({
    required this.summary,
    required this.polylinePoints,
    required this.duration,
    required this.distance,
    required this.instructions,
  });
}

class PublicTransportService {
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final PolylinePoints _polylinePoints = PolylinePoints(); // Updated to use flutter_polyline_points

  Future<List<PublicTransportRoute>> searchRoutes(String start, String end) async {
    if (_googleApiKey.isEmpty) {
      throw Exception('Google Maps API key is missing in .env file');
    }

    // Step 1: Geocode start and end locations to get their coordinates
    final startCoords = await _geocodeLocation(start);
    final endCoords = await _geocodeLocation(end);

    // Step 2: Call Google Directions API for transit routes
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${startCoords.latitude},${startCoords.longitude}'
          '&destination=${endCoords.latitude},${endCoords.longitude}'
          '&mode=transit'
          '&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch routes: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Directions API error: ${data['status']}');
    }

    // Step 3: Parse the routes
    final routes = data['routes'] as List<dynamic>;
    List<PublicTransportRoute> publicTransportRoutes = [];

    for (var route in routes) {
      final leg = route['legs'][0];
      final duration = leg['duration']['text'];
      final distance = leg['distance']['text'];
      final steps = leg['steps'] as List<dynamic>;

      // Decode polyline for the route
      final polyline = route['overview_polyline']['points'];
      final List<PointLatLng> decodedPoints = _polylinePoints.decodePolyline(polyline);
      final List<latlong.LatLng> routePoints = decodedPoints
          .map((point) => latlong.LatLng(point.latitude, point.longitude))
          .toList();

      // Generate summary and instructions
      String summary = '';
      List<String> instructions = [];
      for (var step in steps) {
        if (step['travel_mode'] == 'TRANSIT') {
          final transitDetails = step['transit_details'];
          final vehicleType = transitDetails['line']['vehicle']['type'];
          final lineName = transitDetails['line']['short_name'] ?? 'Unknown';
          summary = '$vehicleType $lineName: $duration';
          instructions.add(
              'Take $vehicleType $lineName from ${transitDetails['departure_stop']['name']} '
                  'to ${transitDetails['arrival_stop']['name']} (${step['duration']['text']})');
        } else {
          instructions.add(step['html_instructions']);
        }
      }

      publicTransportRoutes.add(PublicTransportRoute(
        summary: summary,
        polylinePoints: routePoints,
        duration: duration,
        distance: distance,
        instructions: instructions,
      ));
    }

    return publicTransportRoutes;
  }

  // Helper method to geocode location names to coordinates
  Future<latlong.LatLng> _geocodeLocation(String location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=$location'
          '&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to geocode location: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Geocoding error: ${data['status']}');
    }

    final result = data['results'][0];
    final geometry = result['geometry']['location'];
    return latlong.LatLng(geometry['lat'], geometry['lng']);
  }
}
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PublicTransportRoute {
  final String summary;
  final List<LatLng> polylinePoints;
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
  final String googleApiKey = 'YOUR_ACTUAL_API_KEY_HERE'; // Replace with your actual Google API key

  Future<List<PublicTransportRoute>> searchRoutes(String start, String end) async {
    try {
      // Step 1: Geocode start aur end using Nominatim
      final startCoords = await _geocodeLocation(start);
      final endCoords = await _geocodeLocation(end);

      // Step 2: Fetch nearby public transport stops using Overpass API
      final stops = await _fetchNearbyStops(startCoords, endCoords);

      // Step 3: Get route details using Google Routes API
      double distanceKm;
      double durationMins;
      List<LatLng> polylinePoints;
      List<String> instructions;

      try {
        final routeData = await _getRouteFromGoogleRoutes(startCoords, endCoords);
        distanceKm = routeData['distance'] / 1000; // Convert meters to km
        durationMins = routeData['duration'] / 60; // Convert seconds to mins
        polylinePoints = routeData['polylinePoints'];
        instructions = routeData['instructions'];
      } catch (e) {
        print('Google Routes API failed: $e');
        // Fallback to basic route and Haversine formula
        polylinePoints = [
          startCoords,
          stops['startStop'] ?? startCoords,
          stops['endStop'] ?? endCoords,
          endCoords,
        ];
        distanceKm = _calculateDistance(startCoords, endCoords);
        durationMins = distanceKm * 2; // Assume 2 mins/km
        instructions = [
          'Walk to nearest stop at ${stops['startStop']}',
          'Take public transport to stop near ${stops['endStop']}',
          'Walk to $end',
        ];
      }

      return [
        PublicTransportRoute(
          summary: 'Public Transport Route from $start to $end',
          polylinePoints: polylinePoints,
          duration: '${durationMins.toStringAsFixed(1)} mins',
          distance: '${distanceKm.toStringAsFixed(1)} km',
          instructions: instructions,
        ),
      ];
    } catch (e) {
      throw Exception('Failed to fetch routes: $e');
    }
  }

  Future<Map<String, dynamic>> _getRouteFromGoogleRoutes(LatLng start, LatLng end) async {
    final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': start.latitude,
            'longitude': start.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': end.latitude,
            'longitude': end.longitude,
          },
        },
      },
      'travelMode': 'TRANSIT', // Use transit mode for public transport
      'routingPreference': 'TRANSIT', // Prefer transit routes
      'computeAlternativeRoutes': false,
      'routeModifiers': {
        'avoidTolls': false,
        'avoidHighways': false,
        'avoidFerries': false,
      },
      'languageCode': 'en',
      'units': 'METRIC',
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleApiKey,
        'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.legs.steps',
      },
      body: body,
    );

    print('Google Routes API response status: ${response.statusCode}');
    print('Google Routes API response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route from Google Routes API');
    }

    final data = jsonDecode(response.body);
    if (data['routes'] == null || data['routes'].isEmpty) {
      throw Exception('No routes found');
    }

    final route = data['routes'][0];
    final distanceMeters = route['distanceMeters'].toDouble();
    final durationSeconds = double.parse(route['duration'].replaceAll('s', '')); // Remove 's' from duration (e.g., "16200s")
    final encodedPolyline = route['polyline']['encodedPolyline'];
    final polylinePoints = _decodePolyline(encodedPolyline);

    // Extract instructions from route legs
    final List<String> instructions = [];
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      for (var leg in route['legs']) {
        if (leg['steps'] != null) {
          for (var step in leg['steps']) {
            if (step['navigationInstruction'] != null && step['navigationInstruction']['instructions'] != null) {
              instructions.add(step['navigationInstruction']['instructions']);
            }
          }
        }
      }
    }

    return {
      'distance': distanceMeters,
      'duration': durationSeconds,
      'polylinePoints': polylinePoints,
      'instructions': instructions.isNotEmpty ? instructions : ['No detailed instructions available'],
    };
  }

  Future<LatLng> _geocodeLocation(String location) async {
    final variations = [
      location,
      'Al $location',
      '$location, Saudi Arabia',
    ];

    for (var query in variations) {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&lang=en',
      );

      print('Geocoding URL for $query: $url');
      final response = await http.get(url, headers: {
        'User-Agent': 'MershedApp/1.0 (muhammadumer7574@gmail.com)',
      });

      print('Geocoding response status: ${response.statusCode}');
      print('Geocoding response body: ${response.body}');

      if (response.statusCode == 200 && jsonDecode(response.body).isNotEmpty) {
        final result = jsonDecode(response.body)[0];
        return LatLng(double.parse(result['lat']), double.parse(result['lon']));
      }

      await Future.delayed(Duration(seconds: 1));
    }

    // Case-insensitive fallback coordinates for major Saudi landmarks
    final lowerLocation = location.toLowerCase();
    if (lowerLocation.contains('masmak fortress')) {
      return LatLng(24.6312, 46.7133); // Masmak Fortress, Riyadh
    } else if (lowerLocation.contains('king khalid grand mosque')) {
      return LatLng(24.7358, 46.6557); // King Khalid Grand Mosque, Riyadh
    } else if (lowerLocation.contains('kaaba') || lowerLocation.contains('masjid al-haram') || lowerLocation.contains('mecca')) {
      return LatLng(21.4225, 39.8262); // Kaaba, Mecca
    } else if (lowerLocation.contains('prophet\'s mosque') || lowerLocation.contains('masjid an-nabawi') || lowerLocation.contains('madina') || lowerLocation.contains('medina')) {
      return LatLng(24.4686, 39.6112); // Prophet's Mosque, Medina
    } else if (lowerLocation.contains('jeddah corniche')) {
      return LatLng(21.4858, 39.1925); // Jeddah Corniche
    } else if (lowerLocation.contains('dammam corniche')) {
      return LatLng(26.4207, 50.0888); // Dammam Corniche
    }

    throw Exception('Failed to geocode $location after trying variations');
  }

  Future<Map<String, LatLng>> _fetchNearbyStops(LatLng start, LatLng end) async {
    final query = '''
      [out:json];
      node["highway"="bus_stop"](around:10000,${start.latitude},${start.longitude});
      node["highway"="bus_stop"](around:10000,${end.latitude},${end.longitude});
      out body;
    ''';
    final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');
    final response = await http.get(url);

    print('Overpass response status: ${response.statusCode}');
    print('Overpass response body: ${response.body}');

    if (response.statusCode != 200 || jsonDecode(response.body)['elements'].isEmpty) {
      return {'startStop': start, 'endStop': end};
    }

    final data = jsonDecode(response.body)['elements'];
    LatLng? startStop, endStop;
    double minStartDist = double.infinity, minEndDist = double.infinity;

    for (var stop in data) {
      final stopCoords = LatLng(stop['lat'], stop['lon']);
      final startDist = _calculateDistance(start, stopCoords);
      final endDist = _calculateDistance(end, stopCoords);

      if (startDist < minStartDist) {
        minStartDist = startDist;
        startStop = stopCoords;
      }
      if (endDist < minEndDist) {
        minEndDist = endDist;
        endStop = stopCoords;
      }
    }

    return {
      'startStop': startStop ?? start,
      'endStop': endStop ?? end,
    };
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const R = 6371.0; // Earth's radius in kilometers
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final deltaLat = (b.latitude - a.latitude) * pi / 180;
    final deltaLon = (b.longitude - a.longitude) * pi / 180;

    final aSin = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(aSin), sqrt(1 - aSin));
    final distance = R * c;

    return double.parse(distance.toStringAsFixed(1));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
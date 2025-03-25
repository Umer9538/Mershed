import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MapService {
  static const LatLng defaultLocation = LatLng(24.7136, 46.6753); // Riyadh coordinates
  final String apiKey;

  MapService() : apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<Set<Marker>> getMarkers() async {
    return {
      Marker(
        markerId: const MarkerId('default'),
        position: defaultLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<LatLng> searchLocation(String query) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Enhance the query by appending the city and country for better geocoding accuracy
    final enhancedQuery = '$query, Riyadh, Saudi Arabia';
    print('Enhanced search query: $enhancedQuery');

    // Use Nominatim API instead of Google Maps Geocoding API
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(enhancedQuery)}'
          '&format=json',
    );

    print('Geocoding URL: $url');
    final response = await http.get(url, headers: {
      'User-Agent': 'MershedApp/1.0 (muhammadumer7574@gmail.com)', // Nominatim requires a User-Agent
    });
    print('Geocoding response status: ${response.statusCode}');
    print('Geocoding response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to geocode location: HTTP ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data.isEmpty) {
      throw Exception('No results found for "$query" in Riyadh, Saudi Arabia');
    }

    final location = data[0];
    return LatLng(double.parse(location['lat']), double.parse(location['lon']));
  }

  Future<LatLng> getCurrentLocation() async {
    return defaultLocation; // Replace with actual location service if available
  }

  Future<List<LatLng>> getDirections(LatLng start, LatLng end) async {
    // For directions, we'll use a hardcoded route for now since Nominatim doesn't provide directions
    // You can implement another free routing API like OSRM (Open Source Routing Machine) if needed
    return [
      start,
      end,
    ];
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

  Future<List<LatLng>> getPredefinedRoute(String routeName) async {
    final Map<String, List<LatLng>> predefinedRoutes = {
      'riyadh_to_jeddah': [
        const LatLng(24.7136, 46.6753), // Riyadh
        const LatLng(21.5433, 39.1728), // Jeddah
      ],
    };
    return predefinedRoutes[routeName] ?? [];
  }
}




/*
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MapService {
  static const LatLng defaultLocation = LatLng(24.7136, 46.6753); // Riyadh coordinates
  final String apiKey;

  MapService() : apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '' {
    if (apiKey.isEmpty) {
      throw Exception('Google Maps API key is missing. Ensure it is set in the .env file.');
    }
  }

  Future<Set<Marker>> getMarkers() async {
    return {
      Marker(
        markerId: const MarkerId('default'),
        position: defaultLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<LatLng> searchLocation(String query) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    // Enhance the query by appending the city and country for better geocoding accuracy
    final enhancedQuery = '$query, Riyadh, Saudi Arabia';
    print('Enhanced search query: $enhancedQuery');

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(enhancedQuery)}'
          '&key=$apiKey',
    );

    print('Geocoding URL: $url'); // Log the URL for debugging
    final response = await http.get(url);
    print('Geocoding response status: ${response.statusCode}');
    print('Geocoding response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to geocode location: HTTP ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Geocoding error: ${data['status']}: ${data['error_message'] ?? 'No error message'}');
    }

    if (data['results'].isEmpty) {
      throw Exception('No results found for "$query" in Riyadh, Saudi Arabia');
    }

    final location = data['results'][0]['geometry']['location'];
    return LatLng(location['lat'], location['lng']);
  }

  Future<LatLng> getCurrentLocation() async {
    return defaultLocation; // Replace with actual location service if available
  }

  Future<List<LatLng>> getDirections(LatLng start, LatLng end) async {
    // Check for internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${start.latitude},${start.longitude}'
          '&destination=${end.latitude},${end.longitude}'
          '&key=$apiKey',
    );

    print('Directions URL: $url'); // Log the URL for debugging
    final response = await http.get(url);
    print('Directions response status: ${response.statusCode}');
    print('Directions response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch directions: HTTP ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') {
      throw Exception('Directions error: ${data['status']}: ${data['error_message'] ?? 'No error message'}');
    }

    if (data['routes'].isEmpty) {
      throw Exception('No routes found between the specified locations');
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    return _decodePolyline(points);
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

  Future<List<LatLng>> getPredefinedRoute(String routeName) async {
    final Map<String, List<LatLng>> predefinedRoutes = {
      'riyadh_to_jeddah': [
        const LatLng(24.7136, 46.6753), // Riyadh
        const LatLng(21.5433, 39.1728), // Jeddah
      ],
    };
    return predefinedRoutes[routeName] ?? [];
  }
}*/

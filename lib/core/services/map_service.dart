import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class MapService {
  static const LatLng defaultLocation = LatLng(24.7136, 46.6753); // Riyadh coordinates

  Future<Set<Marker>> getMarkers() async {
    return {
      Marker(
        point: defaultLocation,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
    };
  }

  Future<LatLng> searchLocation(String query) async {
    final Map<String, LatLng> mockLocations = {
      'riyadh': const LatLng(24.7136, 46.6753),
      'jeddah': const LatLng(21.5433, 39.1728),
      'dubai': const LatLng(25.2769, 55.2962),
      'istanbul': const LatLng(41.0082, 28.9784),
      'london': const LatLng(51.5074, -0.1278),
    };

    final lowerQuery = query.toLowerCase();
    return mockLocations.entries
        .firstWhere(
          (entry) => entry.key.contains(lowerQuery),
      orElse: () => throw Exception('Location not found'),
    )
        .value;
  }

  Future<LatLng> getCurrentLocation() async {
    return defaultLocation;
  }

  // FR13: Offline navigation support
/*  Future<void> downloadTilesForOffline(LatLng center, double zoom, int radius) async {
    final store = FMTC.instance('offlineMap');
    await store.download.startForeground(
      region: CircleRegion(
        center: center,
        radius: radius.toDouble(),
      ),
      minZoom: (zoom - 2).toInt(),
      maxZoom: (zoom + 2).toInt(),
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  }*/
}


/*
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class MapService {
  static const LatLng defaultLocation = LatLng(24.7136, 46.6753); // Riyadh coordinates

  Future<Set<Marker>> getMarkers() async {
    // Placeholder: Add real markers later (e.g., rental locations)
    return {
      Marker(
        point: defaultLocation,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      )
    };
  }

  // Mock search functionality (replace with real geocoding API if needed)
  Future<LatLng> searchLocation(String query) async {
    // Simulated search results
    final Map<String, LatLng> mockLocations = {
      'riyadh': const LatLng(24.7136, 46.6753),
      'jeddah': const LatLng(21.5433, 39.1728),
      'dubai': const LatLng(25.2769, 55.2962),
      'istanbul': const LatLng(41.0082, 28.9784),
      'london': const LatLng(51.5074, -0.1278),
    };

    final lowerQuery = query.toLowerCase();
    return mockLocations.entries
        .firstWhere(
          (entry) => entry.key.contains(lowerQuery),
      orElse: () => throw Exception('Location not found'),
    )
        .value;
  }

  // Mock current location (replace with real location service if needed)
  Future<LatLng> getCurrentLocation() async {
    // Simulate current location as Riyadh for now
    return defaultLocation;
  }
}*/

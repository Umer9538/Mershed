import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarRentalLocation {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final int availableCars;
  final double pricePerDay;
  final String city;
  final CarRentalTier rentalTier;
  final List<CarType> availableCarTypes;

  CarRentalLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.availableCars,
    required this.pricePerDay,
    required this.city,
    required this.rentalTier,
    required this.availableCarTypes,
  });
}

enum CarRentalTier {
  standard,
  premium,
  luxury,
  economic
}

enum CarType {
  sedan,
  suv,
  compact,
  luxury,
  electric,
  hybrid
}

class CarRentalService {
  final Map<String, dynamic> _cityMetadata = {
    'Riyadh': {
      'culturalTheme': 'Modern Urban Hub',
      'rentalFocus': 'Business and Luxury Mobility',
      'recommendedCarTypes': [CarType.luxury, CarType.suv],
    },
    'Jeddah': {
      'culturalTheme': 'Coastal Metropolitan',
      'rentalFocus': 'Diverse Urban Transportation',
      'recommendedCarTypes': [CarType.hybrid, CarType.electric],
    },
    'Dammam': {
      'culturalTheme': 'Industrial Connectivity',
      'rentalFocus': 'Efficient Corporate Solutions',
      'recommendedCarTypes': [CarType.sedan, CarType.compact],
    },
    'Mecca': {
      'culturalTheme': 'Spiritual Destination',
      'rentalFocus': 'Pilgrim-Friendly Services',
      'recommendedCarTypes': [CarType.suv, CarType.sedan],
    },
    'Medina': {
      'culturalTheme': 'Historical Significance',
      'rentalFocus': 'Comfortable Exploration',
      'recommendedCarTypes': [CarType.electric, CarType.hybrid],
    }
  };

  Future<List<CarRentalLocation>> getCarRentalLocations(LatLng center) async {
    // Simulated advanced location fetching with rich metadata
    return [
      CarRentalLocation(
        id: 'RYD001',
        name: 'Urban Mobility Solutions',
        address: 'King Fahd Business District, Riyadh',
        location: LatLng(24.7136, 46.6753),
        availableCars: 25,
        pricePerDay: 250.0,
        city: 'Riyadh',
        rentalTier: CarRentalTier.luxury,
        availableCarTypes: [
          CarType.luxury,
          CarType.suv,
          CarType.electric
        ],
      ),
      CarRentalLocation(
        id: 'JED002',
        name: 'Red Sea Mobility Hub',
        address: 'Al Corniche Waterfront, Jeddah',
        location: LatLng(21.4858, 39.1925),
        availableCars: 18,
        pricePerDay: 180.0,
        city: 'Jeddah',
        rentalTier: CarRentalTier.premium,
        availableCarTypes: [
          CarType.hybrid,
          CarType.electric,
          CarType.compact
        ],
      ),
      CarRentalLocation(
        id: 'DMM003',
        name: 'Eastern Horizon Rentals',
        address: 'King Abdulaziz Business Park, Dammam',
        location: LatLng(26.4207, 50.0888),
        availableCars: 15,
        pricePerDay: 200.0,
        city: 'Dammam',
        rentalTier: CarRentalTier.standard,
        availableCarTypes: [
          CarType.sedan,
          CarType.compact,
          CarType.suv
        ],
      ),
      CarRentalLocation(
        id: 'MEC004',
        name: 'Sacred Journey Mobility',
        address: 'Near Grand Mosque Precinct, Mecca',
        location: LatLng(21.4225, 39.8262),
        availableCars: 10,
        pricePerDay: 300.0,
        city: 'Mecca',
        rentalTier: CarRentalTier.premium,
        availableCarTypes: [
          CarType.suv,
          CarType.sedan,
          CarType.luxury
        ],
      ),
      CarRentalLocation(
        id: 'MED005',
        name: 'Prophetic Path Rentals',
        address: 'Historical District, Medina',
        location: LatLng(24.5247, 39.5692),
        availableCars: 12,
        pricePerDay: 220.0,
        city: 'Medina',
        rentalTier: CarRentalTier.economic,
        availableCarTypes: [
          CarType.electric,
          CarType.hybrid,
          CarType.compact
        ],
      ),
    ];
  }

  // Advanced filtering methods
  List<CarRentalLocation> filterByCity(List<CarRentalLocation> locations, String city) {
    return locations.where((location) => location.city == city).toList();
  }

  List<CarRentalLocation> filterByCarType(List<CarRentalLocation> locations, CarType carType) {
    return locations.where((location) =>
        location.availableCarTypes.contains(carType)
    ).toList();
  }

  // Get city-specific recommendations
  Map<String, dynamic> getCityRecommendations(String city) {
    return _cityMetadata[city] ?? {};
  }
}
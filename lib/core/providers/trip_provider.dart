import 'package:flutter/material.dart';
import 'package:mershed/core/models/trip.dart';
import 'package:mershed/core/services/trip_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = false;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;

  Future<void> fetchTrips(String userId) async {
    try {
      _setLoading(true);
      _trips = await _tripService.fetchTrips(userId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error in TripProvider.fetchTrips: $e');
      rethrow;
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      _setLoading(true);
      await _tripService.addTrip(trip);
      _trips.add(trip);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error in TripProvider.addTrip: $e');
      rethrow;
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      _setLoading(true);
      await _tripService.updateTrip(trip);
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      }
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error in TripProvider.updateTrip: $e');
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      _setLoading(true);
      await _tripService.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('Error in TripProvider.deleteTrip: $e');
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
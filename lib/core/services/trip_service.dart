import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mershed/core/models/trip.dart';
import 'package:mershed/core/models/user_preferences.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'trips';
  static const String _preferencesCollection = 'user_preferences';

  Future<List<Trip>> fetchTrips(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => Trip.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching trips: $e');
      rethrow;
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      await _firestore.collection(_collection).doc(trip.id).set(trip.toJson());
    } catch (e) {
      print('Error adding trip: $e');
      rethrow;
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      await _firestore.collection(_collection).doc(trip.id).update(trip.toJson());
    } catch (e) {
      print('Error updating trip: $e');
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(_collection).doc(tripId).delete();
    } catch (e) {
      print('Error deleting trip: $e');
      rethrow;
    }
  }

  Future<UserPreferences?> fetchUserPreferences(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .get();
      if (snapshot.exists) {
        return UserPreferences.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching user preferences: $e');
      return null;
    }
  }
  Future<void> deleteUserPreferences(String userId) async {
    try {
      await _firestore.collection(_preferencesCollection).doc(userId).delete();
    } catch (e) {
      print('Error deleting user preferences: $e');
      rethrow;
    }
  }
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(preferences.userId)
          .set(preferences.toJson());
    } catch (e) {
      print('Error saving user preferences: $e');
      rethrow;
    }
  }
}
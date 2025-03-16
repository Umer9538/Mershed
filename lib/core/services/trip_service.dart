import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mershed/core/models/trip.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'trips';

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
}
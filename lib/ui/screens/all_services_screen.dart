// lib/ui/screens/all_services_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mershed/config/app_routes.dart';

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchHotels() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('hotels').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'hotel',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'price': data['price']?.toDouble() ?? 0.0,
        'rating': data['rating']?.toDouble() ?? 0.0,
        'isAvailable': data['isAvailable'] ?? false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('activities').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'activity',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'price': data['price']?.toDouble() ?? 0.0,
        'isAvailable': data['isAvailable'] ?? false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRestaurants() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('restaurants').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'type': 'restaurant',
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'location': data['location'] ?? 'Unknown',
        'price': data['price']?.toDouble() ?? 0.0,
        'rating': data['rating']?.toDouble() ?? 0.0,
        'isAvailable': data['isAvailable'] ?? false,
      };
    }).toList();
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> result) {
    Navigator.pushNamed(
      context,
      AppRoutes.booking,
      arguments: result['id'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: const Color(0xFFB94A2F),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hotels Section
          const Text(
            'Hotels',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchHotels(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Error loading hotels');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No hotels available');
              }

              final hotels = snapshot.data!;
              return Column(
                children: hotels.map((hotel) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.hotel, color: Color(0xFFB94A2F)),
                      title: Text(hotel['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hotel['location']),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(hotel['rating'].toString()),
                            ],
                          ),
                          Text('Price: ${hotel['price']} SAR'),
                          Text(
                            hotel['isAvailable'] ? 'Available' : 'Not Available',
                            style: TextStyle(
                              color: hotel['isAvailable'] ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToDetail(context, hotel),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Activities Section
          const Text(
            'Activities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchActivities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Error loading activities');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No activities available');
              }

              final activities = snapshot.data!;
              return Column(
                children: activities.map((activity) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Color(0xFFB94A2F)),
                      title: Text(activity['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity['location']),
                          Text('Price: ${activity['price']} SAR'),
                          Text(
                            activity['isAvailable'] ? 'Available' : 'Not Available',
                            style: TextStyle(
                              color: activity['isAvailable'] ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToDetail(context, activity),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Restaurants Section
          const Text(
            'Restaurants',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Error loading restaurants');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No restaurants available');
              }

              final restaurants = snapshot.data!;
              return Column(
                children: restaurants.map((restaurant) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.restaurant, color: Color(0xFFB94A2F)),
                      title: Text(restaurant['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant['location']),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(restaurant['rating'].toString()),
                            ],
                          ),
                          Text('Price: ${restaurant['price']} SAR'),
                          Text(
                            restaurant['isAvailable'] ? 'Available' : 'Not Available',
                            style: TextStyle(
                              color: restaurant['isAvailable'] ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToDetail(context, restaurant),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
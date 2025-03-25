// lib/ui/screens/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/config/app_routes.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final userId = authProvider.user?.id;

    if (userId == null && !authProvider.isGuest) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view saved destinations')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Destinations'),
        backgroundColor: const Color(0xFFB94A2F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saved_destinations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading saved destinations'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No saved destinations'));
          }

          final savedDestinations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: savedDestinations.length,
            itemBuilder: (context, index) {
              final doc = savedDestinations[index];
              final data = doc.data() as Map<String, dynamic>;
              final destinationId = data['destinationId'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('destinations')
                    .doc(destinationId)
                    .get(),
                builder: (context, destSnapshot) {
                  if (destSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  if (destSnapshot.hasError || !destSnapshot.hasData || !destSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('Destination not found'),
                    );
                  }

                  final destData = destSnapshot.data!.data() as Map<String, dynamic>;
                  final name = destData['name'] ?? 'Unknown';
                  final location = destData['location'] ?? 'Unknown';
                  final rating = destData['rating']?.toDouble() ?? 0.0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Color(0xFFB94A2F)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(rating.toString()),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.destinationDetail,
                          arguments: destinationId,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
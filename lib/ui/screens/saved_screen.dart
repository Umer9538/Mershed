import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/models/trip.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);
    final userId = authProvider.user?.id;

    if (userId == null && !authProvider.isGuest) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view saved trips')),
      );
    }

    // Fetch trips when the screen loads if not already fetched
    if (tripProvider.trips.isEmpty && !tripProvider.isLoading) {
      tripProvider.fetchTrips(userId!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Trips'),
        backgroundColor: const Color(0xFF40557b),
      ),
      body: Consumer<TripProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.trips.isEmpty) {
            return const Center(child: Text('No saved trips found'));
          }

          final savedTrips = provider.trips;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: savedTrips.length,
            itemBuilder: (context, index) {
              final trip = savedTrips[index];
              return _buildTripCard(context, trip);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    final days = trip.endDate.difference(trip.startDate).inDays + 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB94A2F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.flight_takeoff, color: Color(0xFFB94A2F)),
        ),
        title: Text(
          trip.destination,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$days ${days == 1 ? 'day' : 'days'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${trip.budget.toStringAsFixed(0)} SAR',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.tripDetail,
            arguments: trip,
          );
        },
      ),
    );
  }
}
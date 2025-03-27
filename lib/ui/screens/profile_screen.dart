import 'package:flutter/material.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for direct Firestore access

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TripService _tripService = TripService();
  UserPreferences? _preferences;
  Map<String, dynamic>? _userData; // To store additional user data from Firebase
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndPreferences();
  }

  Future<void> _loadUserDataAndPreferences() async {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        // Fetch user preferences
        final preferences = await _tripService.fetchUserPreferences(authProvider.user!.id);

        // Fetch additional user data from Firestore 'users' collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authProvider.user!.id)
            .get();

        setState(() {
          _preferences = preferences;
          _userData = userDoc.exists ? userDoc.data() : null;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading data: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFB94A2F),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Section
            Text(
              'About You',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (authProvider.user == null)
              const Text('Please log in to view your profile.')
            else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFFB94A2F), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _userData?['name'] ?? authProvider.user!.name ?? 'Unknown User',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            authProvider.user!.email ?? 'No email provided',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      if (_userData?['phone'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _userData!['phone'],
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Your Preferences',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_preferences == null)
              const Text('No preferences set yet.')
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Interests: ${_preferences!.interests.join(", ")}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.explore, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Travel Style: ${_preferences!.travelStyle}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/preferences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB94A2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Edit Preferences'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: authProvider.user == null
                  ? null
                  : () async {
                try {
                  await _tripService.deleteUserPreferences(authProvider.user!.id);
                  setState(() => _preferences = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences reset!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error resetting preferences: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Reset Preferences'),
            ),
            const SizedBox(height: 16),
            if (authProvider.isAuthenticated)
              ElevatedButton(
                onPressed: () async {
                  await authProvider.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Sign Out'),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TripService _tripService = TripService();
  UserPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        final preferences = await _tripService.fetchUserPreferences(authProvider.user!.id);
        setState(() {
          _preferences = preferences;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading preferences: $e');
        setState(() => _isLoading = false);
      }
    } else {
      // Handle case where user is not authenticated
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context); // Define authProvider here
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Preferences',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_preferences == null)
              const Text('No preferences set yet.')
            else ...[
              Text(
                'Interests: ${_preferences!.interests.join(", ")}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Travel Style: ${_preferences!.travelStyle}',
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/preferences'),
              child: const Text('Edit Preferences'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authProvider.user == null
                  ? null // Disable button if user is not authenticated
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
              child: const Text('Reset Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
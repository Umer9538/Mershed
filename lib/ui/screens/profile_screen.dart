import 'package:flutter/material.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TripService _tripService = TripService();
  UserPreferences? _preferences;
  Map<String, dynamic>? _userData;
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
        final preferences = await _tripService.fetchUserPreferences(authProvider.user!.id);
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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF40557b),
        title: const Text(
          'Your Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // White for contrast on dark app bar
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFB94A2F),
                    child: Text(
                      authProvider.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['name'] ?? authProvider.user?.name ?? 'Unknown User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2F4A6B), // Deep blue for professionalism
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.user?.email ?? 'No email provided',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Information Section
            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F4A6B),
              ),
            ),
            const SizedBox(height: 12),
            if (authProvider.user == null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Please log in to view your profile.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: _userData?['name'] ?? authProvider.user!.name ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: authProvider.user!.email ?? 'N/A',
                      ),
                      if (_userData?['phone'] != null) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _userData!['phone'],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Preferences Section
            Text(
              'Travel Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F4A6B),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _preferences == null
                    ? const Text(
                  'No preferences set yet. Edit to personalize your experience.',
                  style: TextStyle(color: Colors.grey),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.favorite_border,
                      label: 'Interests',
                      value: _preferences!.interests.join(", "),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.explore_outlined,
                      label: 'Travel Style',
                      value: _preferences!.travelStyle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            _buildActionButton(
              text: 'Edit Preferences',
              color: const Color(0xFFB94A2F),
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/preferences'),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              text: 'Reset Preferences',
              color: Colors.grey[300]!,
              textColor: Colors.black87,
              onPressed: authProvider.user == null
                  ? null
                  : () async {
                try {
                  await _tripService.deleteUserPreferences(authProvider.user!.id);
                  setState(() => _preferences = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences reset successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error resetting preferences: $e')),
                  );
                }
              },
            ),
            if (authProvider.isAuthenticated) ...[
              const SizedBox(height: 16),
              _buildActionButton(
                text: 'Sign Out',
                color: Colors.red[700]!,
                textColor: Colors.white,
                onPressed: () async {
                  await authProvider.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFB94A2F), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2F4A6B), // Deep blue for readability
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
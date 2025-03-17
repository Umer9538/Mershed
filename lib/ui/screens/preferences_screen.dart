import 'package:flutter/material.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:provider/provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _tripService = TripService();
  List<String> _interests = [];
  String? _travelStyle;
  bool _isLoading = false;

  final List<String> _availableInterests = [
    'Adventure', 'Relaxation', 'Culture', 'Food', 'Shopping'
  ];
  final List<String> _availableTravelStyles = [
    'Budget', 'Moderate', 'Luxury'
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select your interests:',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _availableInterests.map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: _interests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _interests.add(interest);
                      } else {
                        _interests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose your travel style:',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _travelStyle,
              hint: const Text('Select travel style'),
              items: _availableTravelStyles.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(style),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _travelStyle = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (_interests.isNotEmpty && _travelStyle != null) {
                    setState(() => _isLoading = true);
                    try {
                      final preferences = UserPreferences(
                        userId: authProvider.user!.id,
                        interests: _interests,
                        travelStyle: _travelStyle!,
                      );
                      await _tripService.saveUserPreferences(preferences);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preferences saved!')),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving preferences: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select all fields')),
                    );
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
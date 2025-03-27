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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFB94A2F), // Warm, professional color
        title: const Text(
          'Personalize Your Journey',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // White for contrast on dark app bar
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_suggest_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tailor your travel experience',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface, // Darker text for readability
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interests Section
              Text(
                'Your Travel Interests',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F4A6B), // Deep blue for professionalism
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableInterests.map((interest) {
                  final isSelected = _interests.contains(interest);
                  return FilterChip(
                    label: Text(
                      interest,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFB94A2F), // Matching app bar color
                    checkmarkColor: Colors.white,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Travel Style Section
              Text(
                'Preferred Travel Style',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F4A6B), // Consistent deep blue
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: _travelStyle,
                  hint: Text(
                    'Choose your style',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  items: _availableTravelStyles.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Text(
                        style,
                        style: const TextStyle(
                          color: Color(0xFF2F4A6B), // Deep blue for dropdown items
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _travelStyle = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFFB94A2F),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
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
                            SnackBar(
                              content: const Text('Preferences Saved Successfully'),
                              backgroundColor: theme.colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete all selections'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB94A2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Save Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mershed/config/app_routes.dart';
import 'package:mershed/core/models/trip.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/core/providers/trip_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/models/recommendation.dart';

class TripPlanScreen extends StatefulWidget {
  const TripPlanScreen({super.key});

  @override
  State<TripPlanScreen> createState() => _TripPlanScreenState();
}

class _TripPlanScreenState extends State<TripPlanScreen> {
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _budgetController = TextEditingController();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showRecommendations = false;
  List<DailyItinerary> _itinerary = [];

  void _saveTrip(MershadAuthProvider authProvider, TripProvider tripProvider, RecommendationProvider recProvider) async {
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save your trip'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      setState(() => _isLoading = true);
      try {
        final budget = double.parse(_budgetController.text);
        print('Budget entered: $budget SAR');
        print('Starting to fetch recommendations for ${authProvider.user!.id}...');
        await recProvider.fetchRecommendations(
          budget: budget,
          destination: _destinationController.text.trim(),
          userId: authProvider.user!.id,
          startDate: _startDate!,
          endDate: _endDate!,
        );

        print('Recommendations fetched: ${recProvider.recommendations.length} items');
        recProvider.recommendations.forEach((rec) {
          print('Recommendation: ${rec.type} - ${rec.name}, Cost: ${rec.cost} SAR');
        });

        _itinerary = _generateItinerary(
          startDate: _startDate!,
          endDate: _endDate!,
          recommendations: recProvider.recommendations,
        );

        print('Itinerary generated with ${_itinerary.length} days');

        final trip = Trip(
          id: const Uuid().v4(),
          userId: authProvider.user!.id,
          destination: _destinationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          budget: budget,
          itinerary: _itinerary,
        );

        await tripProvider.addTrip(trip);
        print('Trip saved: ${trip.id} - ${trip.destination}');
        if (mounted) {
          setState(() => _showRecommendations = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trip to ${trip.destination} has been saved with itinerary!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error during trip saving: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving trip: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      print('Validation failed or dates missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<DailyItinerary> _generateItinerary({
    required DateTime startDate,
    required DateTime endDate,
    required List<Recommendation> recommendations,
  }) {
    List<DailyItinerary> itinerary = [];
    final days = endDate.difference(startDate).inDays + 1;

    // Separate recommendations by type
    final hotel = recommendations.firstWhere((rec) => rec.type == 'hotel', orElse: () => Recommendation(type: 'hotel', name: 'No Hotel', description: 'N/A', cost: 0));
    final activities = recommendations.where((rec) => rec.type == 'activity').toList();
    final restaurants = recommendations.where((rec) => rec.type == 'restaurant').toList();
    final events = recommendations.where((rec) => rec.type == 'event').toList();

    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      List<Recommendation> dailyPlan = [hotel]; // Hotel stays the same each day

      // Add unique activity, restaurant, and event for each day if available
      if (i < activities.length) {
        dailyPlan.add(activities[i]);
      }
      if (i < restaurants.length) {
        dailyPlan.add(restaurants[i]);
      }
      if (i < events.length) {
        dailyPlan.add(events[i]);
      }

      itinerary.add(DailyItinerary(date: day, activities: dailyPlan));
    }

    return itinerary;
  }

  List<String> _popularDestinations = [
    'Riyadh',
    'Jeddah',
    'Mecca',
    'Medina',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MershadAuthProvider>(context);
    final tripProvider = Provider.of<TripProvider>(context);
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFB94A2F),
        title: Text(
          'Create Your Journey',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Planning Tips',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.preferences),
            tooltip: 'Set Preferences',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.5,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Stepper(
                    type: StepperType.horizontal,
                    currentStep: _currentStep,
                    elevation: 0,
                    onStepContinue: () {
                      if (_currentStep < 2) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _saveTrip(authProvider, tripProvider, recommendationProvider);
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep--;
                        });
                      }
                    },
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: _currentStep > 0 ? 150 : 300,
                              child: ElevatedButton(
                                onPressed: details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                                    : Text(
                                  _currentStep == 2 ? 'Save Trip' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 150,
                                child: OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: theme.colorScheme.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Back',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Destination'),
                        content: _buildDestinationStep(),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Dates'),
                        content: _buildDateStep(theme),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                      ),
                      Step(
                        title: const Text('Budget'),
                        content: _buildBudgetStep(),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showRecommendations && recommendationProvider.recommendations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            color: theme.colorScheme.primary,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: theme.colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Curated Recommendations',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: recommendationProvider.recommendations.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final rec = recommendationProvider.recommendations[index];
                              final IconData iconData = _getRecommendationIcon(rec.type);
                              final Color iconColor = _getRecommendationColor(rec.type, theme);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  rec.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${rec.cost.toStringAsFixed(0)} SAR',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: theme.colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            rec.description,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showRecommendations && _itinerary.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            color: theme.colorScheme.secondary,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: theme.colorScheme.onSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Personalized Itinerary',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Journey to ${_destinationController.text}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)} · ${_itinerary.length} ${_itinerary.length == 1 ? 'day' : 'days'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _itinerary.length,
                            itemBuilder: (context, index) {
                              final day = _itinerary[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Day ${index + 1}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('EEEE, MMM d').format(day.date),
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...day.activities.map((activity) {
                                    final IconData iconData = _getRecommendationIcon(activity.type);
                                    final Color iconColor = _getRecommendationColor(activity.type, theme);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 56), // Indent to align with day circle
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: iconColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              iconData,
                                              color: iconColor,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        activity.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${activity.cost.toStringAsFixed(0)} SAR',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  activity.description,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  if (index < _itinerary.length - 1) const Divider(height: 32, indent: 16, endIndent: 16),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showRecommendations && recommendationProvider.recommendations.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No recommendations available for this trip.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: 'Where would you like to go?',
              hintText: 'Enter city (e.g., Riyadh, Jeddah)',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a destination';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular Destinations in Saudi Arabia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularDestinations.map((destination) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _destinationController.text = destination;
                  });
                },
                child: Chip(
                  label: Text(destination),
                  avatar: const Icon(Icons.place, size: 16),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildTripImagePreview(),
        ],
      ),
    );
  }

  Widget _buildDateStep(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(
            title: 'Start Date',
            date: _startDate,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2026),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.colorScheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                setState(() {
                  _startDate = pickedDate;
                  if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                    _endDate = _startDate!.add(const Duration(days: 1));
                  }
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _buildDateSelector(
            title: 'End Date',
            date: _endDate,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _endDate ??
                    (_startDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1))),
                firstDate: _startDate ?? DateTime.now(),
                lastDate: DateTime(2026),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.colorScheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                setState(() {
                  _endDate = pickedDate;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          if (_startDate != null && _endDate != null) _buildTripDuration(),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? 'Select a date'
                        : DateFormat('EEE, MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: date == null ? FontWeight.normal : FontWeight.bold,
                      color: date == null
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDuration() {
    if (_startDate == null || _endDate == null) return const SizedBox.shrink();

    final difference = _endDate!.difference(_startDate!).inDays;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Duration',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '$difference ${difference == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'What\'s your budget?',
              hintText: 'Enter amount in SAR',
              suffixText: 'SAR',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your budget';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildBudgetSlider(),
          const SizedBox(height: 24),
          _buildTripSummary(),
        ],
      ),
    );
  }

  Widget _buildBudgetSlider() {
    const double minBudget = 500;
    const double maxBudget = 50000;
    double currentBudget = double.tryParse(_budgetController.text) ?? 5000;

    currentBudget = currentBudget.clamp(minBudget, maxBudget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Budget Range'),
            Text(
              '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(currentBudget)} SAR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: currentBudget,
          min: minBudget,
          max: maxBudget,
          divisions: 99,
          label: '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(currentBudget)} SAR',
          onChanged: (value) {
            setState(() {
              _budgetController.text = value.round().toString();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(minBudget)} SAR',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(maxBudget)} SAR',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripSummary() {
    if (_destinationController.text.isEmpty || _startDate == null || _endDate == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final difference = _endDate!.difference(_startDate!).inDays;
    final budget = double.tryParse(_budgetController.text) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _destinationController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.date_range),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 8),
              Text(
                '$difference ${difference == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet),
              const SizedBox(width: 8),
              Text(
                '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(budget)} SAR',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_money),
              const SizedBox(width: 8),
              Text(
                'Approx. ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(budget / difference)} SAR per day',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripImagePreview() {
    if (_destinationController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final destination = _destinationController.text.toLowerCase();
    String? imagePath;

    if (destination.contains('riyadh')) {
      imagePath = 'assets/images/riyadh.jpeg';
    } else if (destination.contains('jeddah')) {
      imagePath = 'assets/images/jeddah.jpeg';
    } else if (destination.contains('mecca')) {
      imagePath = 'assets/images/mecca.jpg';
    } else if (destination.contains('medina')) {
      imagePath = 'assets/images/medina.jpg';
    }

    if (imagePath == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip Planning Tips'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTipItem(
                icon: Icons.flight,
                title: 'Book flights in advance',
                description: 'Flights are usually cheaper when booked 2-3 months ahead.',
              ),
              const Divider(),
              _buildTipItem(
                icon: Icons.calendar_today,
                title: 'Travel off-season',
                description: 'Consider traveling during shoulder seasons for better deals.',
              ),
              const Divider(),
              _buildTipItem(
                icon: Icons.attach_money,
                title: 'Set a daily budget',
                description: 'Allocate funds for accommodation, food, activities, and emergencies.',
              ),
              const Divider(),
              _buildTipItem(
                icon: Icons.security,
                title: 'Get travel insurance',
                description: 'Protect yourself against unexpected events and medical emergencies.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for recommendation and itinerary display
  IconData _getRecommendationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'activity':
        return Icons.local_activity;
      case 'event':
        return Icons.event;
      case 'attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  Color _getRecommendationColor(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return Colors.indigo;
      case 'restaurant':
        return Colors.orange;
      case 'activity':
        return Colors.green;
      case 'event':
        return Colors.purple;
      case 'attraction':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }
}
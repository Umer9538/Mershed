import 'package:flutter/material.dart';
import 'package:mershed/core/providers/auth_provider.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/ui/widgets/recommendation_card.dart';
import 'package:provider/provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _showResults = false;

  Future<void> _fetchRecommendations() async {
    if (_budgetController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final recommendationProvider = Provider.of<RecommendationProvider>(context, listen: false);
      final authProvider = Provider.of<MershadAuthProvider>(context, listen: false);
      await recommendationProvider.fetchRecommendations(
        budget: double.parse(_budgetController.text),
        destination: _destinationController.text,
        userId: authProvider.user?.id,
      );
      if (mounted) {
        setState(() {
          _showResults = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Firebase not initialized')
                  ? 'App not initialized properly. Please restart the app.'
                  : 'Error fetching recommendations: $e',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _fetchRecommendations,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          'Budget Explorer',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Where would you like to go?',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _destinationController,
                                    decoration: InputDecoration(
                                      labelText: 'Destination',
                                      prefixIcon: const Icon(Icons.location_on_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'What\'s your budget?',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _budgetController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Budget (SAR)',
                                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                      suffixText: 'SAR',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: recommendationProvider.isLoading ? null : _fetchRecommendations,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: recommendationProvider.isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text(
                                        'Find Budget Options',
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
                          if (_showResults)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommended Options',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (recommendationProvider.recommendations.isEmpty)
                                    Center(
                                      child: Text(
                                        'No recommendations available for this destination.',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: recommendationProvider.recommendations.length,
                                      itemBuilder: (context, index) {
                                        final rec = recommendationProvider.recommendations[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: RecommendationCard(recommendation: rec),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetTipsDialog(context),
        child: const Icon(Icons.lightbulb_outline),
        tooltip: 'Budget Tips',
      ),
    );
  }

  void _showBudgetTipsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Budget Travel Tips',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTipCard(
                  icon: Icons.calendar_today,
                  title: 'Travel Off-Season',
                  description: 'Prices can be up to 40% lower when traveling during off-peak periods.',
                ),
                _buildTipCard(
                  icon: Icons.local_dining,
                  title: 'Eat Like a Local',
                  description: 'Skip tourist restaurants and try authentic local food markets and street food.',
                ),
                _buildTipCard(
                  icon: Icons.card_travel,
                  title: 'Pack Light',
                  description: 'Avoid checked baggage fees by packing efficiently in a carry-on.',
                ),
                _buildTipCard(
                  icon: Icons.public,
                  title: 'Use Public Transport',
                  description: 'Save money by using public transportation instead of taxis or rentals.',
                ),
                _buildTipCard(
                  icon: Icons.hotel,
                  title: 'Alternative Accommodations',
                  description: 'Consider hostels, home-sharing, or apartment rentals for lower prices.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mershed/core/providers/recommendation_provider.dart';
import 'package:mershed/ui/widgets/recommendation_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Budget Explorer',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/background.jpeg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
                          Text(
                            'What\'s your budget?',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
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
                              onPressed: () async {
                                if (_budgetController.text.isNotEmpty &&
                                    _destinationController.text.isNotEmpty) {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  await recommendationProvider.fetchRecommendations(
                                    double.parse(_budgetController.text),
                                    _destinationController.text,
                                  );

                                  setState(() {
                                    _isLoading = false;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill in all fields'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                foregroundColor: theme.colorScheme.onPrimaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
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
                  const SizedBox(height: 24),
                  if (recommendationProvider.recommendations.isNotEmpty)
                    Text(
                      'Recommended Options',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (recommendationProvider.recommendations.isEmpty && !_isLoading)
                    _buildEmptyState(size, theme),
                ],
              ),
            ),
          ),
          if (recommendationProvider.recommendations.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final rec = recommendationProvider.recommendations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: RecommendationCard(recommendation: rec),
                    );
                  },
                  childCount: recommendationProvider.recommendations.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show budget tips or savings calculator
          _showBudgetTipsDialog(context);
        },
        child: const Icon(Icons.lightbulb_outline),
        tooltip: 'Budget Tips',
      ),
    );
  }

  Widget _buildEmptyState(Size size, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.explore,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start your adventure',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Set your destination and budget to discover\nthe perfect travel options for you.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
import 'package:flutter/material.dart';
import 'package:mershed/core/models/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(recommendation.name),
        subtitle: Text('${recommendation.description} - ${recommendation.cost} SAR'),
        leading: Icon(
          recommendation.type == 'hotel' ? Icons.hotel : Icons.local_activity,
        ),
      ),
    );
  }
}
import 'package:mershed/core/models/recommendation.dart';

class AiService {
  Future<List<Recommendation>> getRecommendations(double budget, String destination) async {
    // Mock recommendations based on budget and destination
    return [
      Recommendation(
        type: 'hotel',
        name: 'Riyadh Hotel',
        description: 'A luxurious stay in the capital.',
        cost: 500.0,
      ),
      Recommendation(
        type: 'activity',
        name: 'Desert Tour',
        description: 'Explore the Saudi desert.',
        cost: 200.0,
      ),
    ].where((rec) => rec.cost <= budget).toList();
  }
}
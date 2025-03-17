import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/models/user_preferences.dart';

class AiService {
  Future<List<Recommendation>> getRecommendations({
    required double budget,
    required String destination,
    UserPreferences? preferences,
    String? season,
    List<String>? events,
    String? weather,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay (remove for real implementation)

    List<Recommendation> recommendations = [];

    final dailyBudget = budget / (events?.length ?? 1); // Distribute budget across events if any
    final interests = preferences?.interests ?? ['General']; // Default to 'General' if no preferences
    final travelStyle = preferences?.travelStyle ?? 'Moderate'; // Default to 'Moderate' if no preferences

    // Generate recommendations based on interests
    if (interests.contains('Adventure')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Hiking Tour in $destination',
        description: 'Explore the mountains with a guided tour.',
        cost: dailyBudget * 0.5,
      ));
    }
    if (interests.contains('Relaxation')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Spa Day in $destination',
        description: 'Relax with a full-day spa package.',
        cost: dailyBudget * 0.6,
      ));
    }
    if (interests.contains('Culture')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Cultural Tour in $destination',
        description: 'Visit historical landmarks and museums.',
        cost: dailyBudget * 0.4,
      ));
    }
    if (interests.contains('Food')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Food Tasting Tour in $destination',
        description: 'Experience local cuisine with a guided tour.',
        cost: dailyBudget * 0.3,
      ));
    }
    if (interests.contains('Shopping')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Shopping Spree in $destination',
        description: 'Visit the best shopping districts.',
        cost: dailyBudget * 0.5,
      ));
    }

    // Generate accommodation based on travel style
    if (travelStyle == 'Luxury') {
      recommendations.add(Recommendation(
        type: 'hotel',
        name: 'Luxury Hotel in $destination',
        description: 'Stay at a 5-star hotel with premium amenities.',
        cost: dailyBudget * 0.8,
      ));
    } else if (travelStyle == 'Budget') {
      recommendations.add(Recommendation(
        type: 'hotel',
        name: 'Budget Hostel in $destination',
        description: 'Affordable and cozy hostel stay.',
        cost: dailyBudget * 0.3,
      ));
    } else { // Moderate
      recommendations.add(Recommendation(
        type: 'hotel',
        name: 'Mid-Range Hotel in $destination',
        description: 'Comfortable stay with good amenities.',
        cost: dailyBudget * 0.5,
      ));
    }

    // Seasonal and weather-based recommendations
    if (season == 'Winter' && (weather?.toLowerCase() == 'cold' || weather?.toLowerCase() == 'rainy')) {
      recommendations.add(Recommendation(
        type: 'activity',
        name: 'Indoor Activity in $destination',
        description: 'Enjoy an indoor experience due to cold weather.',
        cost: dailyBudget * 0.4,
      ));
    }

    // Event-based recommendations
    if (events != null && events.isNotEmpty) {
      recommendations.add(Recommendation(
        type: 'event',
        name: events[0],
        description: 'Attend the ${events[0]} in $destination.',
        cost: dailyBudget * 0.3,
      ));
    }

    // Filter recommendations by budget
    return recommendations.where((rec) => rec.cost <= budget).toList();
  }
}
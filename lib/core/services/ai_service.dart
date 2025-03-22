import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/models/user_preferences.dart';

class AiService {
  Future<List<Recommendation>> getRecommendations({
    required double budget,
    required String destination,
    required String userId, // Added userId
    UserPreferences? preferences,
    required String season,
    required String weatherCondition,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _fetchAiRecommendations(
      budget: budget,
      destination: destination,
      userId: userId, // Pass userId
      preferences: preferences,
      season: season,
      weatherCondition: weatherCondition,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Recommendation>> _fetchAiRecommendations({
    required double budget,
    required String destination,
    required String userId, // Added userId
    UserPreferences? preferences,
    required String season,
    required String weatherCondition,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('Gemini API Key is missing in .env file');
      return _getFallbackRecommendations(
        budget: budget,
        destination: destination,
        userId: userId, // Pass userId
        preferences: preferences,
        season: season,
        weatherCondition: weatherCondition,
        startDate: startDate,
        endDate: endDate,
      );
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final tripDays = endDate.difference(startDate).inDays + 1;
    final budgetPerDay = budget / tripDays;

    // Set default preferences if none provided
    final defaultPreferences = preferences ?? UserPreferences(
      interests: ['culture', 'nature'],
      travelStyle: 'moderate', userId: '',
    );

    final prompt = '''
You are a travel assistant specializing in Saudi Arabia. Provide personalized travel recommendations for a user with ID $userId for a trip to $destination from ${startDate.toIso8601String().substring(0, 10)} to ${endDate.toIso8601String().substring(0, 10)}. Consider the following:
- Total Budget: $budget SAR for $tripDays days (approximately $budgetPerDay SAR per day)
- Season: $season
- Weather: $weatherCondition (e.g., Clouds)
- User Preferences: Interests: ${defaultPreferences.interests.join(", ")}, Travel Style: ${defaultPreferences.travelStyle}

Suggest recommendations for a $tripDays-day trip:
- 1 hotel for the entire stay (~50% of budget, e.g., ${budget * 0.5} SAR total).
- $tripDays unique activities (each ~${budget * 0.2 / tripDays} SAR per day).
- $tripDays unique restaurants (each ~${budget * 0.15 / tripDays} SAR per day).
- $tripDays unique local events (each ~${budget * 0.15 / tripDays} SAR per day).
Ensure the recommendations are budget-friendly, suitable for the season, weather, and travel dates, and the total cost does not exceed $budget SAR. Adjust costs if necessary to fit the budget. Return the response in the following JSON format:
{
  "recommendations": [
    {"type": "hotel", "name": "Hotel Name", "description": "Description (for $tripDays nights)", "cost": 1000},
    {"type": "activity", "name": "Activity 1", "description": "Description", "cost": 200},
    {"type": "activity", "name": "Activity 2", "description": "Description", "cost": 200},
    ...
    {"type": "restaurant", "name": "Restaurant 1", "description": "Description", "cost": 150},
    {"type": "restaurant", "name": "Restaurant 2", "description": "Description", "cost": 150},
    ...
    {"type": "event", "name": "Event 1", "description": "Event on ${startDate.toIso8601String().substring(0, 10)}", "cost": 150},
    {"type": "event", "name": "Event 2", "description": "Event on ${startDate.add(Duration(days: 1)).toIso8601String().substring(0, 10)}", "cost": 150},
    ...
  ]
}
Return only the raw JSON object without any markdown formatting.
''';

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
      },
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Gemini API success: ${response.body}');
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        final jsonResponse = jsonDecode(content);
        final recommendations = (jsonResponse['recommendations'] as List<dynamic>)
            .map((item) => Recommendation.fromJson(item))
            .toList();

        final totalCost = recommendations.fold<double>(0, (sum, rec) => sum + rec.cost);
        if (totalCost > budget) {
          print('Total cost ($totalCost SAR) exceeds budget ($budget SAR), scaling down');
          return recommendations.map((rec) => Recommendation(
            type: rec.type,
            name: rec.name,
            description: rec.description,
            cost: rec.cost * (budget / totalCost),
          )).toList();
        }
        print('Total cost within budget: $totalCost SAR');
        return recommendations;
      } else {
        print('Gemini API Error: ${response.statusCode}, ${response.body}');
        return _getFallbackRecommendations(
          budget: budget,
          destination: destination,
          userId: userId, // Pass userId
          preferences: preferences,
          season: season,
          weatherCondition: weatherCondition,
          startDate: startDate,
          endDate: endDate,
        );
      }
    } catch (e) {
      print('Error fetching AI recommendations: $e');
      return _getFallbackRecommendations(
        budget: budget,
        destination: destination,
        userId: userId, // Pass userId
        preferences: preferences,
        season: season,
        weatherCondition: weatherCondition,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  List<Recommendation> _getFallbackRecommendations({
    required double budget,
    required String destination,
    required String userId, // Added userId
    UserPreferences? preferences,
    required String season,
    required String weatherCondition,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final tripDays = endDate.difference(startDate).inDays + 1;
    final budgetPerDay = budget / tripDays;

    // Default preferences
    final defaultPreferences = preferences ?? UserPreferences(
      interests: ['culture', 'nature'],
      travelStyle: 'moderate', userId: '',
    );

    final destinationData = {
      'riyadh': [
        Recommendation(
          type: 'hotel',
          name: 'Four Seasons Riyadh',
          description: 'Luxury hotel for $tripDays nights',
          cost: (budget * 0.5).clamp(1000, budget * 0.6),
        ),
        Recommendation(type: 'activity', name: 'Kingdom Centre Tour', description: 'Panoramic views', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Al Rajhi Grand Mosque', description: 'Cultural visit', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Diriyah Tour', description: 'Historical site', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'restaurant', name: 'The Globe', description: 'Fine dining', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Lusin', description: 'Armenian-Saudi fusion', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Nozomi', description: 'Japanese cuisine', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Riyadh Season Day 1', description: 'Cultural fest Day 1', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Riyadh Season Day 2', description: 'Cultural fest Day 2', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Riyadh Season Day 3', description: 'Cultural fest Day 3', cost: budget * 0.15 / tripDays),
      ],
      'jeddah': [
        Recommendation(
          type: 'hotel',
          name: 'Hilton Jeddah',
          description: 'Sea-view hotel for $tripDays nights',
          cost: (budget * 0.5).clamp(800, budget * 0.6),
        ),
        Recommendation(type: 'activity', name: 'Jeddah Corniche Walk', description: 'Scenic stroll', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Floating Mosque Visit', description: 'Architectural marvel', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Old Jeddah Tour', description: 'Historical exploration', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'restaurant', name: 'Al Nakheel', description: 'Saudi cuisine', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Byblos', description: 'Lebanese dining', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Sakura', description: 'Japanese fusion', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Jeddah Festival Day 1', description: 'Local fest Day 1', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Jeddah Festival Day 2', description: 'Local fest Day 2', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Jeddah Festival Day 3', description: 'Local fest Day 3', cost: budget * 0.15 / tripDays),
      ],
      'mecca': [
        Recommendation(
          type: 'hotel',
          name: 'Pullman ZamZam',
          description: 'Near Holy Mosque for $tripDays nights',
          cost: (budget * 0.5).clamp(1000, budget * 0.6),
        ),
        Recommendation(type: 'activity', name: 'Visit Kaaba', description: 'Spiritual experience', cost: 0),
        Recommendation(type: 'activity', name: 'Jabal al-Nour Climb', description: 'Historical hike', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Mecca Museum', description: 'Cultural visit', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'restaurant', name: 'Al Tazaj', description: 'Grilled chicken', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Al Qasr', description: 'Local flavors', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Al Rajhi', description: 'Traditional meals', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Ramadan Retreat Day 1', description: 'Spiritual event Day 1', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Ramadan Retreat Day 2', description: 'Spiritual event Day 2', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Ramadan Retreat Day 3', description: 'Spiritual event Day 3', cost: budget * 0.15 / tripDays),
      ],
      'medina': [
        Recommendation(
          type: 'hotel',
          name: 'Madinah Hilton',
          description: 'Near Prophet’s Mosque for $tripDays nights',
          cost: (budget * 0.5).clamp(800, budget * 0.6),
        ),
        Recommendation(type: 'activity', name: 'Prophet’s Mosque Visit', description: 'Sacred site', cost: 0),
        Recommendation(type: 'activity', name: 'Quba Mosque Tour', description: 'Historical visit', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'activity', name: 'Uhud Mountain', description: 'Scenic exploration', cost: budget * 0.2 / tripDays),
        Recommendation(type: 'restaurant', name: 'Al Baik', description: 'Fast food', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'Abu Khalid', description: 'Local cuisine', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'restaurant', name: 'House of Grills', description: 'Grilled delights', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Medina Cultural Fest Day 1', description: 'Local event Day 1', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Medina Cultural Fest Day 2', description: 'Local event Day 2', cost: budget * 0.15 / tripDays),
        Recommendation(type: 'event', name: 'Medina Cultural Fest Day 3', description: 'Local event Day 3', cost: budget * 0.15 / tripDays),
      ],
    };

    final cityKey = destination.toLowerCase();
    final allRecommendations = destinationData[cityKey] ?? [];
    final recommendations = <Recommendation>[];

    // Select one hotel
    final hotel = allRecommendations.firstWhere((rec) => rec.type == 'hotel', orElse: () => Recommendation(type: 'hotel', name: 'Generic Hotel', description: 'Stay for $tripDays nights', cost: budget * 0.5));
    recommendations.add(hotel);

    // Select unique activities, restaurants, and events up to tripDays
    final activities = allRecommendations.where((rec) => rec.type == 'activity').toList();
    final restaurants = allRecommendations.where((rec) => rec.type == 'restaurant').toList();
    final events = allRecommendations.where((rec) => rec.type == 'event').toList();

    for (int i = 0; i < tripDays && i < activities.length; i++) {
      recommendations.add(activities[i]);
    }
    for (int i = 0; i < tripDays && i < restaurants.length; i++) {
      recommendations.add(restaurants[i]);
    }
    for (int i = 0; i < tripDays && i < events.length; i++) {
      recommendations.add(events[i]);
    }

    final totalCost = recommendations.fold<double>(0, (sum, rec) => sum + rec.cost);
    if (totalCost > budget) {
      print('Fallback total cost ($totalCost SAR) exceeds budget ($budget SAR), scaling down');
      return recommendations.map((rec) => Recommendation(
        type: rec.type,
        name: rec.name,
        description: rec.description,
        cost: rec.cost * (budget / totalCost),
      )).toList();
    }
    return recommendations;
  }
}
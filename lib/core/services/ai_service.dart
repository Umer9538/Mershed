import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/models/user_preferences.dart';

class AiService {
  Future<List<Recommendation>> getRecommendations({
    required double budget,
    required String destination,
    UserPreferences? preferences,
    required String season,
    required List<String> events,
    required String weather,
  }) async {
    return _fetchAiRecommendations(
      budget: budget,
      destination: destination,
      preferences: preferences,
      season: season,
      weather: weather,
      events: events,
    );
  }

  Future<List<Recommendation>> _fetchAiRecommendations({
    required double budget,
    required String destination,
    UserPreferences? preferences,
    required String season,
    required String weather,
    required List<String> events,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    print('Using Gemini API Key: $apiKey'); // Debug log
    if (apiKey.isEmpty) {
      print('Gemini API Key is missing in .env file');
      return _getFallbackRecommendations(
        budget: budget,
        destination: destination,
        preferences: preferences,
        season: season,
        weather: weather,
        events: events,
      );
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final prompt = '''
You are a travel assistant specializing in Saudi Arabia. Provide personalized travel recommendations for a trip to $destination. Consider the following:
- Budget: $budget SAR
- Season: $season
- Weather: $weather
- Local Events: ${events.isNotEmpty ? events.join(", ") : "None"}
- User Preferences: Interests: ${preferences?.interests.join(", ") ?? "General"}, Travel Style: ${preferences?.travelStyle ?? "Moderate"}

Suggest hotels, activities, and restaurants in $destination. Ensure the recommendations are budget-friendly and suitable for the season, weather, and events. Return exactly 3 recommendations (one hotel, one activity, and one restaurant) in the following JSON format. Ensure the JSON is complete, properly formatted, and includes all necessary closing brackets:
{
  "recommendations": [
    {"type": "hotel", "name": "Hotel Name", "description": "Description", "cost": 1000},
    {"type": "activity", "name": "Activity Name", "description": "Description", "cost": 500},
    {"type": "restaurant", "name": "Restaurant Name", "description": "Description", "cost": 200}
  ]
}
Important: Return only the raw JSON object without any markdown formatting such as ```json or ```. The response must be a valid JSON string with no other text.
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
        'maxOutputTokens': 500,
      },
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('Raw Gemini API Response: $content'); // Debug log

        // Extract JSON from Markdown code block (if present)
        String jsonContent = content;
        if (content.contains('```json')) {
          // More robust extraction of JSON content from Markdown code blocks
          final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
          final match = jsonBlockRegex.firstMatch(content);
          if (match != null && match.groupCount >= 1) {
            jsonContent = match.group(1)!.trim();
          }
        }

        try {
          // Check if the JSON is valid before parsing
          final jsonResponse = jsonDecode(jsonContent);
          final recommendations = (jsonResponse['recommendations'] as List<dynamic>)
              .map((item) => Recommendation.fromJson(item))
              .toList();
          return recommendations.where((rec) => rec.cost <= budget).toList();
        } catch (e) {
          print('JSON parsing error: $e');
          print('Attempted to parse: $jsonContent');
          return _getFallbackRecommendations(
            budget: budget,
            destination: destination,
            preferences: preferences,
            season: season,
            weather: weather,
            events: events,
          );
        }
      } else {
        print('Gemini API Error: ${response.statusCode}, ${response.body}');
        return _getFallbackRecommendations(
          budget: budget,
          destination: destination,
          preferences: preferences,
          season: season,
          weather: weather,
          events: events,
        );
      }
    } catch (e) {
      print('Error fetching AI recommendations: $e');
      return _getFallbackRecommendations(
        budget: budget,
        destination: destination,
        preferences: preferences,
        season: season,
        weather: weather,
        events: events,
      );
    }
  }

  List<Recommendation> _getFallbackRecommendations({
    required double budget,
    required String destination,
    UserPreferences? preferences,
    required String season,
    required String weather,
    required List<String> events,
  }) {
    final destinationData = {
      'riyadh': [
        Recommendation(
          type: 'hotel',
          name: 'Four Seasons Hotel Riyadh',
          description: 'A luxury hotel in the heart of Riyadh.',
          cost: 1500,
        ),
        Recommendation(
          type: 'hotel',
          name: 'Holiday Inn Riyadh',
          description: 'A comfortable hotel for moderate budgets.',
          cost: 600,
        ),
        Recommendation(
          type: 'hotel',
          name: 'Ibis Riyadh Olaya Street',
          description: 'A budget-friendly hotel with good amenities.',
          cost: 300,
        ),
        Recommendation(
          type: 'activity',
          name: 'Visit Kingdom Centre Tower',
          description: 'Enjoy panoramic views of Riyadh from the Sky Bridge.',
          cost: 70,
        ),
        Recommendation(
          type: 'activity',
          name: 'Explore Al Masmak Fortress',
          description: 'Discover the history of Riyadh at this iconic fortress.',
          cost: 0,
        ),
        Recommendation(
          type: 'activity',
          name: 'Food Tasting Tour in Riyadh',
          description: 'Sample local Saudi cuisine on a guided food tour.',
          cost: budget > 500 ? 200 : 100,
        ),
        Recommendation(
          type: 'activity',
          name: 'Desert Safari in Riyadh',
          description: 'Experience an adventurous desert safari with dune bashing.',
          cost: budget > 1000 ? 500 : 300,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'The Globe Restaurant',
          description: 'Fine dining with a view at Kingdom Centre.',
          cost: 200,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'Al Baik',
          description: 'A popular fast-food chain for fried chicken.',
          cost: 30,
        ),
      ],
      'jeddah': [
        Recommendation(
          type: 'hotel',
          name: 'Hilton Jeddah',
          description: 'A family-friendly hotel with sea views.',
          cost: 1000,
        ),
        Recommendation(
          type: 'hotel',
          name: 'Radisson Blu Jeddah',
          description: 'A mid-range hotel with great amenities.',
          cost: 700,
        ),
        Recommendation(
          type: 'hotel',
          name: 'Ibis Jeddah City Center',
          description: 'A budget-friendly option in the city center.',
          cost: 250,
        ),
        Recommendation(
          type: 'activity',
          name: 'Stroll Along Jeddah Corniche',
          description: 'Enjoy a scenic walk along the Red Sea coast.',
          cost: 0,
        ),
        Recommendation(
          type: 'activity',
          name: 'Visit Al-Balad',
          description: 'Explore the historic old town of Jeddah.',
          cost: 0,
        ),
        Recommendation(
          type: 'activity',
          name: 'Food Tasting Tour in Jeddah',
          description: 'Taste traditional Saudi dishes in Jeddah.',
          cost: budget > 500 ? 150 : 80,
        ),
        Recommendation(
          type: 'activity',
          name: 'Desert Safari in Jeddah',
          description: 'An exciting desert adventure near Jeddah.',
          cost: budget > 1000 ? 400 : 250,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'Al Nakheel Restaurant',
          description: 'Authentic Saudi cuisine with a sea view.',
          cost: 150,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'Khayal Restaurant',
          description: 'A cozy spot for traditional Saudi meals.',
          cost: 80,
        ),
      ],
      'mecca': [
        Recommendation(
          type: 'hotel',
          name: 'Pullman ZamZam Makkah',
          description: 'A luxury hotel near the Holy Mosque.',
          cost: 1200,
        ),
        Recommendation(
          type: 'activity',
          name: 'Visit the Kaaba',
          description: 'Experience the spiritual heart of Islam.',
          cost: 0,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'Al Tazaj',
          description: 'A popular spot for grilled chicken in Mecca.',
          cost: 40,
        ),
      ],
      'medina': [
        Recommendation(
          type: 'hotel',
          name: 'Madinah Hilton',
          description: 'A comfortable hotel near the Prophets Mosque.',
          cost: 900,
        ),
        Recommendation(
          type: 'activity',
          name: 'Visit the Prophets Mosque',
          description: 'Pray and explore this sacred site.',
          cost: 0,
        ),
        Recommendation(
          type: 'restaurant',
          name: 'Al Baik Medina',
          description: 'Fast food with a local twist.',
          cost: 30,
        ),
      ],
    };

    final cityKey = destination.toLowerCase();
    final recommendations = destinationData.entries
        .where((entry) => cityKey.contains(entry.key))
        .map((entry) => entry.value)
        .expand((element) => element)
        .toList();

    // If no recommendations are found for the destination, return an empty list
    if (recommendations.isEmpty) {
      print('No fallback recommendations available for $destination');
      return [];
    }

    // Filter by travel style
    final travelStyle = preferences?.travelStyle ?? 'Moderate';
    final budgetRange = {
      'Luxury': [1000, double.infinity],
      'Moderate': [400, 1000],
      'Budget': [0, 400],
    };

    final range = budgetRange[travelStyle] ?? [400, 1000];
    var filteredRecommendations = recommendations.where((rec) {
      if (rec.type == 'hotel') {
        return rec.cost >= range[0] && rec.cost <= range[1];
      }
      return true;
    }).toList();

    // Filter by interests
    final interests = preferences?.interests ?? [];
    if (interests.contains('Food')) {
      filteredRecommendations
          .retainWhere((rec) => rec.type != 'activity' || rec.name.contains('Food'));
    }
    if (interests.contains('Adventure')) {
      filteredRecommendations
          .retainWhere((rec) => rec.type != 'activity' || rec.name.contains('Safari'));
    }

    // Adjust for weather
    if (weather == 'Rain' && season == 'Winter') {
      filteredRecommendations
          .retainWhere((rec) => rec.type != 'activity' || !rec.name.contains('Safari'));
    }

    // Filter by budget
    return filteredRecommendations.where((rec) => rec.cost <= budget).toList();
  }
}
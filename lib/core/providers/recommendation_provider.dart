import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/services/ai_service.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class RecommendationProvider with ChangeNotifier {
  final AiService _aiService = AiService();
  final TripService _tripService = TripService();
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;

  List<Recommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  Future<void> fetchRecommendations({
    required double budget,
    required String destination,
    String? userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Please restart the app.');
    }

    setLoading(true);
    try {
      UserPreferences? preferences =
      userId != null ? await _tripService.fetchUserPreferences(userId) : null;

      print('Fetched preferences for user $userId: ${preferences?.toJson()}');

      String currentSeason = await _getCurrentSeason(startDate);
      String weatherCondition = await _fetchWeatherCondition(destination);

      print('Season: $currentSeason, Weather: $weatherCondition');

      _recommendations = await _aiService.getRecommendations(
        budget: budget,
        destination: destination,
        preferences: preferences,
        season: currentSeason,
        weatherCondition: weatherCondition, // Pass weather
        startDate: startDate,
        endDate: endDate, userId: '',
      );

      notifyListeners();
    } catch (e) {
      print('Error fetching recommendations: $e');
      _recommendations = [];
      notifyListeners();
      rethrow;
    } finally {
      setLoading(false);
    }
  }
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String> _getCurrentSeason(DateTime date) async {
    final month = date.month;
    if ([12, 1, 2].contains(month)) return 'Winter';
    if ([3, 4, 5].contains(month)) return 'Spring';
    if ([6, 7, 8].contains(month)) return 'Summer';
    return 'Autumn';
  }

  Future<String> _fetchWeatherCondition(String destination) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '7556c9c69d94241807167c755a875fb1';
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$destination&appid=$apiKey&units=metric';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weatherCondition = data['weather'][0]['main'];
        print('Fetched weather for $destination: $weatherCondition');
        return weatherCondition;
      } else {
        print('Failed to fetch weather: ${response.statusCode}, Response: ${response.body}');
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return 'Unknown';
    }
  }
}








/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mershed/core/models/recommendation.dart';
import 'package:mershed/core/models/user_preferences.dart';
import 'package:mershed/core/services/ai_service.dart';
import 'package:mershed/core/services/trip_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class RecommendationProvider with ChangeNotifier {
  final AiService _aiService = AiService();
  final TripService _tripService = TripService();
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;

  List<Recommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  Future<void> fetchRecommendations({
    required double budget,
    required String destination,
    String? userId,
  }) async {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Please restart the app.');
    }

    setLoading(true);
    try {
      UserPreferences? preferences = userId != null
          ? await _tripService.fetchUserPreferences(userId)
          : null;

      print('Fetched preferences for user $userId: ${preferences?.toJson()}');

      String currentSeason = await _getCurrentSeason();
      List<String> localEvents = await _fetchLocalEvents(destination);
      String weatherCondition = await _fetchWeatherCondition(destination);

      print('Season: $currentSeason, Events: $localEvents, Weather: $weatherCondition');

      _recommendations = await _aiService.getRecommendations(
        budget: budget,
        destination: destination,
        preferences: preferences,
        season: currentSeason,
        events: localEvents,
        weather: weatherCondition,
      );
      notifyListeners();
    } catch (e) {
      print('Error fetching recommendations: $e');
      _recommendations = [];
      notifyListeners();
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String> _getCurrentSeason() async {
    final now = DateTime.now();
    final month = now.month;
    if ([12, 1, 2].contains(month)) return 'Winter';
    if ([3, 4, 5].contains(month)) return 'Spring';
    if ([6, 7, 8].contains(month)) return 'Summer';
    return 'Fall';
  }

  Future<List<String>> _fetchLocalEvents(String destination) async {
    // Use the private token for authentication
    final privateToken = dotenv.env['EVENTBRITE_PRIVATE_TOKEN'] ?? 'OFDVQN5PJ2FDXW7BAJVB';

    // Fetch coordinates from OpenWeatherMap
    final weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?q=$destination&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric';
    double? lat, lon;
    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      if (weatherResponse.statusCode == 200) {
        final weatherData = jsonDecode(weatherResponse.body);
        lat = weatherData['coord']['lat'];
        lon = weatherData['coord']['lon'];
      }
    } catch (e) {
      print('Error fetching coordinates for $destination: $e');
    }

    // Use the v3 search endpoint with proper parameters
    // Note: Removed the 'expand=event' parameter which might be causing issues
    final url = lat != null && lon != null
        ? 'https://www.eventbriteapi.com/v3/organizations/my-organization/events/?location.latitude=$lat&location.longitude=$lon&location.within=10mi'
        : 'https://www.eventbriteapi.com/v3/organizations/my-organization/events/?location.address=${Uri.encodeComponent(destination)}';

    print('Fetching events with URL: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $privateToken',
          'Content-Type': 'application/json',
        },
      );

      print('Eventbrite response status: ${response.statusCode}');
      print('Eventbrite response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = (data['events'] as List?)
            ?.map((event) => event['name']['text'] as String)
            .take(3)
            .toList() ?? [];

        print('Fetched events for $destination: $events');
        return events.isNotEmpty ? events : ['No events available'];
      } else {
        print('Failed to fetch events: ${response.statusCode}, Response: ${response.body}');
        return ['No events available'];
      }
    } catch (e) {
      print('Error fetching events: $e');
      return ['No events available'];
    }
  }
 */
/* Future<List<String>> _fetchLocalEvents(String destination) async {
    final privateToken = 'OFDVQN5PJF2DXW7BAJVB';
    // Fetch coordinates from OpenWeatherMap
    final weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?q=$destination&appid=${dotenv.env['OPENWEATHERMAP_API_KEY']}&units=metric';
    double? lat, lon;
    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      if (weatherResponse.statusCode == 200) {
        final weatherData = jsonDecode(weatherResponse.body);
        lat = weatherData['coord']['lat'];
        lon = weatherData['coord']['lon'];
      }
    } catch (e) {
      print('Error fetching coordinates for $destination: $e');
    }

    // Use coordinates for Eventbrite API
    final url = lat != null && lon != null
        ? 'https://www.eventbriteapi.com/v3/events/search/?location.latitude=$lat&location.longitude=$lon&location.within=10mi'
        : 'https://www.eventbriteapi.com/v3/events/search/?location.address=${Uri.encodeComponent(destination)},SA&location.within=10mi';
    print('Fetching events with URL: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $privateToken',
        },
      );
      print('Eventbrite response status: ${response.statusCode}');
      print('Eventbrite response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = (data['events'] as List)
            .map((event) => event['name']['text'] as String)
            .take(3)
            .toList();
        print('Fetched events for $destination: $events');
        return events.isNotEmpty ? events : ['No events available'];
      } else {
        print('Failed to fetch events: ${response.statusCode}, Response: ${response.body}');
        return ['No events available'];
      }
    } catch (e) {
      print('Error fetching events: $e');
      return ['No events available'];
    }
  }
*//*

  Future<String> _fetchWeatherCondition(String destination) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? '7556a9c69d94241807167c755a875fb1';
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$destination&appid=$apiKey&units=metric';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weatherCondition = data['weather'][0]['main'];
        print('Fetched weather for $destination: $weatherCondition');
        return weatherCondition;
      } else {
        print('Failed to fetch weather: ${response.statusCode}, Response: ${response.body}');
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return 'Unknown';
    }
  }
}*/

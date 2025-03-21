import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EventbriteService {
  Future<List<String>> fetchEvents({
    required String city,
    required double lat,
    required double lon,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = dotenv.env['EVENTBRITE_TOKEN'] ?? '';
    print('Using Eventbrite Token: $token');
    if (token.isEmpty) {
      print('Eventbrite Token is missing in .env file');
      return _getMockEvents(city);
    }

    // Format the start and end dates for the Eventbrite API (ISO 8601 format)
    final startDateStr = startDate != null
        ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(startDate)
        : DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now());
    final endDateStr = endDate != null
        ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(endDate)
        : DateFormat('yyyy-MM-ddTHH:mm:ss')
        .format(DateTime.now().add(Duration(days: 30)));

    final url =
        'https://www.eventbriteapi.com/v3/events/search/?q=$city&location.latitude=$lat&location.longitude=$lon&location.within=50km&start_date.range_start=$startDateStr&start_date.range_end=$endDateStr';
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = (data['events'] as List<dynamic>);

        // Filter events by date (already filtered by API, but double-check)
        List<String> filteredEvents = [];
        for (var event in events) {
          final eventName = event['name']['text'] as String;
          final eventStart = event['start']['local'] as String?;

          if (eventStart != null && startDate != null && endDate != null) {
            try {
              final eventDate = DateFormat('yyyy-MM-ddTHH:mm:ss').parse(eventStart);
              if (eventDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  eventDate.isBefore(endDate.add(const Duration(days: 1)))) {
                filteredEvents.add(eventName);
              }
            } catch (e) {
              print('Error parsing event date for $eventName: $e');
              continue;
            }
          } else {
            filteredEvents.add(eventName);
          }
        }

        print('Fetched events from Eventbrite: $filteredEvents');
        return filteredEvents;
      } else {
        print('Eventbrite API Error: ${response.statusCode}, ${response.body}');
        return _getMockEvents(city);
      }
    } catch (e) {
      print('Error fetching events from Eventbrite: $e');
      return _getMockEvents(city);
    }
  }

  List<String> _getMockEvents(String city) {
    final mockEvents = {
      'jeddah': [
        'Jeddah Festival 2025 (April 2025)',
        'Red Sea Film Festival (December 2025)',
        'Jeddah Art Fair (March 22-28, 2025)',
      ],
      'riyadh': [
        'Riyadh Season 2025 (March 2025)',
        'Riyadh Food Festival (April 2025)',
        'Cultural Exhibition at Kingdom Centre (March 20-25, 2025)',
      ],
      'mecca': [
        'Islamic Heritage Exhibition (March 2025)',
        'Ramadan Spiritual Retreat (March 2025)',
      ],
      'medina': [
        'Medina Cultural Festival (April 2025)',
        'Prophet’s Mosque Tour (Ongoing)',
      ],
    };
    return mockEvents[city.toLowerCase()] ?? [];
  }
}
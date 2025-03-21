import 'package:mershed/core/models/recommendation.dart';

class Trip {
  final String id;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<DailyItinerary>? itinerary; // Added for FR6

  Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.itinerary,
  }) {
    if (destination.trim().isEmpty) {
      throw ArgumentError('Destination cannot be empty');
    }
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('Start date must be before end date');
    }
    if (budget < 0) {
      throw ArgumentError('Budget cannot be negative');
    }
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      userId: json['userId'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      budget: (json['budget'] as num).toDouble(),
      itinerary: (json['itinerary'] as List<dynamic>?)
          ?.map((item) => DailyItinerary.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'itinerary': itinerary?.map((day) => day.toJson()).toList() ?? [],
    };
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    List<DailyItinerary>? itinerary,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      itinerary: itinerary ?? this.itinerary,
    );
  }
}

class DailyItinerary {
  final DateTime date;
  final List<Recommendation> activities;

  DailyItinerary({
    required this.date,
    required this.activities,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  factory DailyItinerary.fromJson(Map<String, dynamic> json) {
    return DailyItinerary(
      date: DateTime.parse(json['date']),
      activities: (json['activities'] as List<dynamic>)
          .map((item) => Recommendation.fromJson(item))
          .toList(),
    );
  }
}
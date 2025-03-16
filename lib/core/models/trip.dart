class Trip {
  final String id;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;

  Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
  }) {
    // Validation
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
    };
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
    );
  }
}
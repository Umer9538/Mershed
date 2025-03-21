class Recommendation {
  final String type; // e.g., 'hotel', 'activity', 'restaurant', 'event'
  final String name;
  final String description;
  final double cost;

  Recommendation({
    required this.type,
    required this.name,
    required this.description,
    required this.cost,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'description': description,
      'cost': cost,
    };
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cost: (json['cost'] as num).toDouble(),
    );
  }
}
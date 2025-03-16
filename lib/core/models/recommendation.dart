class Recommendation {
  final String type; // e.g., 'hotel', 'activity'
  final String name;
  final String description;
  final double cost;

  Recommendation({
    required this.type,
    required this.name,
    required this.description,
    required this.cost,
  });
}
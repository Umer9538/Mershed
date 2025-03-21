class Activity {
  final String id;
  final String name;
  final String location;
  final double cost;
  String? bookingId;

  Activity({
    required this.id,
    required this.name,
    required this.location,
    required this.cost,
    this.bookingId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'cost': cost,
    'bookingId': bookingId,
  };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
    id: map['id'],
    name: map['name'],
    location: map['location'],
    cost: map['cost'],
    bookingId: map['bookingId'],
  );
}
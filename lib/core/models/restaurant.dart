class Restaurant {
  final String id;
  final String name;
  final String location;
  final double averageCostPerPerson;
  String? bookingId;

  Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.averageCostPerPerson,
    this.bookingId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'averageCostPerPerson': averageCostPerPerson,
    'bookingId': bookingId,
  };

  factory Restaurant.fromMap(Map<String, dynamic> map) => Restaurant(
    id: map['id'],
    name: map['name'],
    location: map['location'],
    averageCostPerPerson: map['averageCostPerPerson'],
    bookingId: map['bookingId'],
  );
}
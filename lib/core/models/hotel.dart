class Hotel {
  final String id;
  final String name;
  final String location;
  final double pricePerNight;
  String? bookingId; // Added to track booking status
  final List<String>? photos; // List of photo URLs
  final List<String>? reviews; // List of review texts

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerNight,
    this.bookingId,
    this.photos,
    this.reviews,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'pricePerNight': pricePerNight,
    'bookingId': bookingId,
    'photos': photos ?? [],
    'reviews': reviews ?? [],
  };

  factory Hotel.fromMap(Map<String, dynamic> map) => Hotel(
    id: map['id'].toString(),
    name: map['name'] ?? 'Unknown Hotel',
    location: map['location'] ?? 'Unknown Location',
    pricePerNight: double.tryParse(map['pricePerNight']?.toString() ?? '0') ?? 0,
    bookingId: map['bookingId'],
    photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
    reviews: map['reviews'] != null ? List<String>.from(map['reviews']) : null,
  );
}
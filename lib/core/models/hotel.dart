class Hotel {
  final String id;
  final String name;
  final String location;
  final double pricePerNight;

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerNight,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      pricePerNight: json['pricePerNight'],
    );
  }
}
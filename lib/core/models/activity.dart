class Activity {
  String id;
  String name;
  String location;
  double cost;
  List<String>? photos;
  List<String>? reviews;
  String? _bookingId;

  Activity({
    required this.id,
    required this.name,
    required this.location,
    required this.cost,
    this.photos,
    this.reviews,
  });

  String? get bookingId => _bookingId;

  set bookingId(String? value) {
    _bookingId = value;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'cost': cost,
      'photos': photos,
      'reviews': reviews,
      'bookingId': _bookingId,
    };
  }
}
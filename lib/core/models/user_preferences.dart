class UserPreferences {
  final String userId;
  final List<String> interests; // e.g., ["Adventure", "Relaxation", "Culture"]
  final String travelStyle; // e.g., "Budget", "Luxury", "Moderate"

  UserPreferences({
    required this.userId,
    required this.interests,
    required this.travelStyle,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String,
      interests: List<String>.from(json['interests'] as List),
      travelStyle: json['travelStyle'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'interests': interests,
      'travelStyle': travelStyle,
    };
  }
}
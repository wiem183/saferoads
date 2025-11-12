class Signalement {
  final String id;
  final String type; // accident, obstacle, route endommagée, etc.
  final String description;
  final double latitude;
  final double longitude;
  final DateTime date;
  final int confirmations; // votes/confirmations
  final String userId; // who reported it
  final String? photoUrl; // <-- put it inside the class

  Signalement({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.confirmations,
    required this.userId,
    this.photoUrl, // optional
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'date': date.toIso8601String(),
    'confirmations': confirmations,
    'userId': userId,
    'photoUrl': photoUrl,
  };

  static Signalement fromJson(Map<String, dynamic> json) => Signalement(
    id: json['id'],
    type: json['type'],
    description: json['description'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    date: DateTime.parse(json['date']),
    confirmations: json['confirmations'],
    userId: json['userId'],
    photoUrl: json['photoUrl'], // optional
  );
}

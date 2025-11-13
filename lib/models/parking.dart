class Parking {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final int availableSpots;
  final String status;
  final double pricePerHour;
  final bool isEcoFriendly;

  Parking({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.availableSpots,
    required this.status,
    required this.pricePerHour,
    required this.isEcoFriendly,
  });

  factory Parking.fromJson(Map<String, dynamic> json, String documentId) {
    return Parking(
      id: documentId,
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      capacity: json['capacity'] ?? 0,
      availableSpots: json['available_spots'] ?? 0,
      status: json['status'] ?? '',
      pricePerHour: (json['price_per_hour'] ?? 0).toDouble(),
      isEcoFriendly: json['isEcoFriendly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'capacity': capacity,
        'available_spots': availableSpots,
        'status': status,
        'price_per_hour': pricePerHour,
        'isEcoFriendly': isEcoFriendly,
      };
}

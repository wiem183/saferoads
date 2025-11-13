enum AmendeType {
  speeding,
  parking,
  redLight,
  seatBelt,
  phoneUse,
  documentaryOffense,
  other
}

enum AmendeStatus {
  unpaid,
  paid,
  contested,
  rejected
}

class Amende {
  String id;
  String userId; // User receiving the fine
  String agentId; // Agent/Admin who created it
  String? photoUrl; // Photo evidence
  String location; // Location where violation occurred
  AmendeType type;
  double amount;

  Amende({
    required this.id,
    required this.userId,
    required this.agentId,
    this.photoUrl,
    required this.location,
    required this.type,
    required this.amount,
  });

  /// Convert Amende to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'agentId': agentId,
      'photoUrl': photoUrl,
      'location': location,
      'type': type.toString().split('.').last,
      'amount': amount,
    };
  }

  /// Create Amende from JSON
  factory Amende.fromJson(Map<String, dynamic> json) {
    return Amende(
      id: json['id'] as String,
      userId: json['userId'] as String,
      agentId: json['agentId'] as String,
      photoUrl: json['photoUrl'] as String?,
      location: json['location'] as String,
      type: AmendeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AmendeType.other,
      ),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  /// Get type label in French
  String getTypeLabel() {
    switch (type) {
      case AmendeType.speeding:
        return 'Excès de vitesse';
      case AmendeType.parking:
        return 'Stationnement interdit';
      case AmendeType.redLight:
        return 'Feu rouge';
      case AmendeType.seatBelt:
        return 'Ceinture de sécurité';
      case AmendeType.phoneUse:
        return 'Utilisation du téléphone';
      case AmendeType.documentaryOffense:
        return 'Défaut de documents';
      case AmendeType.other:
        return 'Autre';
    }
  }

  /// Validate amende data
  bool isValid() {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        agentId.isNotEmpty &&
        location.isNotEmpty &&
        amount > 0;
  }
}

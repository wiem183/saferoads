class UserStatistics {
  // Statistiques pour les conducteurs
  int totalTripsPublished;
  int totalSeatsOffered;
  int totalSeatsBooked;
  double totalRevenue;
  double averageOccupancyRate; // Taux d'occupation moyen (%)
  int completedTrips;
  int upcomingTrips;
  double totalDistanceKm;

  // Statistiques pour les passagers
  int totalReservationsMade;
  int totalSeatsReserved;
  double totalMoneySpent;
  double totalMoneySaved; // Économies par rapport au taxi
  double co2SavedKg; // CO2 économisé en kg

  // Statistiques générales
  double userRating;
  int totalRatingsReceived;

  UserStatistics({
    this.totalTripsPublished = 0,
    this.totalSeatsOffered = 0,
    this.totalSeatsBooked = 0,
    this.totalRevenue = 0.0,
    this.averageOccupancyRate = 0.0,
    this.completedTrips = 0,
    this.upcomingTrips = 0,
    this.totalDistanceKm = 0.0,
    this.totalReservationsMade = 0,
    this.totalSeatsReserved = 0,
    this.totalMoneySpent = 0.0,
    this.totalMoneySaved = 0.0,
    this.co2SavedKg = 0.0,
    this.userRating = 0.0,
    this.totalRatingsReceived = 0,
  });

  // Calculer le taux de réservation (%)
  double get bookingRate {
    if (totalSeatsOffered == 0) return 0.0;
    return (totalSeatsBooked / totalSeatsOffered) * 100;
  }

  // Calculer le prix moyen par siège offert
  double get averagePricePerSeat {
    if (totalSeatsOffered == 0) return 0.0;
    return totalRevenue / totalSeatsOffered;
  }

  // Calculer le prix moyen payé par siège réservé
  double get averagePricePerReservation {
    if (totalSeatsReserved == 0) return 0.0;
    return totalMoneySpent / totalSeatsReserved;
  }

  // Calculer les économies moyennes par trajet
  double get averageSavingsPerTrip {
    if (totalReservationsMade == 0) return 0.0;
    return totalMoneySaved / totalReservationsMade;
  }

  // Calculer le CO2 économisé par km
  double get co2SavedPerKm {
    if (totalDistanceKm == 0) return 0.0;
    return co2SavedKg / totalDistanceKm;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTripsPublished': totalTripsPublished,
      'totalSeatsOffered': totalSeatsOffered,
      'totalSeatsBooked': totalSeatsBooked,
      'totalRevenue': totalRevenue,
      'averageOccupancyRate': averageOccupancyRate,
      'completedTrips': completedTrips,
      'upcomingTrips': upcomingTrips,
      'totalDistanceKm': totalDistanceKm,
      'totalReservationsMade': totalReservationsMade,
      'totalSeatsReserved': totalSeatsReserved,
      'totalMoneySpent': totalMoneySpent,
      'totalMoneySaved': totalMoneySaved,
      'co2SavedKg': co2SavedKg,
      'userRating': userRating,
      'totalRatingsReceived': totalRatingsReceived,
    };
  }

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalTripsPublished: json['totalTripsPublished'] ?? 0,
      totalSeatsOffered: json['totalSeatsOffered'] ?? 0,
      totalSeatsBooked: json['totalSeatsBooked'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      averageOccupancyRate: (json['averageOccupancyRate'] ?? 0.0).toDouble(),
      completedTrips: json['completedTrips'] ?? 0,
      upcomingTrips: json['upcomingTrips'] ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] ?? 0.0).toDouble(),
      totalReservationsMade: json['totalReservationsMade'] ?? 0,
      totalSeatsReserved: json['totalSeatsReserved'] ?? 0,
      totalMoneySpent: (json['totalMoneySpent'] ?? 0.0).toDouble(),
      totalMoneySaved: (json['totalMoneySaved'] ?? 0.0).toDouble(),
      co2SavedKg: (json['co2SavedKg'] ?? 0.0).toDouble(),
      userRating: (json['userRating'] ?? 0.0).toDouble(),
      totalRatingsReceived: json['totalRatingsReceived'] ?? 0,
    );
  }
}

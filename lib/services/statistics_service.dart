import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_statistics.dart';
import '../models/announcement.dart';
import '../models/reservation.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Calculer toutes les statistiques d'un utilisateur
  Future<UserStatistics> calculateUserStatistics(String userPhone) async {
    try {
      // Récupérer tous les trajets publiés par l'utilisateur
      final announcementsSnapshot = await _db
          .collection('announcements')
          .where('driverPhone', isEqualTo: userPhone)
          .get();

      // Récupérer toutes les réservations faites par l'utilisateur
      final reservationsSnapshot = await _db
          .collection('reservations')
          .where('reserverPhone', isEqualTo: userPhone)
          .get();

      // Initialiser les statistiques
      UserStatistics stats = UserStatistics();

      // ========== STATISTIQUES CONDUCTEUR ==========
      if (announcementsSnapshot.docs.isNotEmpty) {
        stats = _calculateDriverStatistics(announcementsSnapshot.docs, stats);
      }

      // ========== STATISTIQUES PASSAGER ==========
      if (reservationsSnapshot.docs.isNotEmpty) {
        stats = await _calculatePassengerStatistics(
          reservationsSnapshot.docs,
          stats,
        );
      }

      return stats;
    } catch (e) {
      print('Error calculating statistics: $e');
      return UserStatistics();
    }
  }

  // Calculer les statistiques du conducteur
  UserStatistics _calculateDriverStatistics(
    List<QueryDocumentSnapshot> docs,
    UserStatistics stats,
  ) {
    stats.totalTripsPublished = docs.length;

    int totalSeatsOffered = 0;
    int totalSeatsBooked = 0;
    double totalRevenue = 0.0;
    int completedTrips = 0;
    int upcomingTrips = 0;
    double totalDistance = 0.0;

    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final announcement = Announcement.fromJson(data);

      // Calculer les sièges
      final initialSeats =
          announcement.availableSeats +
          announcement.reservations.fold<int>(
            0,
            (sum, r) => sum + r.seatsReserved,
          );
      totalSeatsOffered += initialSeats;

      final seatsBooked = announcement.reservations.fold(
        0,
        (sum, r) => sum + r.seatsReserved,
      );
      totalSeatsBooked += seatsBooked;

      // Calculer le revenu
      totalRevenue += announcement.price * seatsBooked;

      // Trajets complétés vs à venir
      if (announcement.departureDateTime.isBefore(now)) {
        completedTrips++;
      } else {
        upcomingTrips++;
      }

      // Estimer la distance (si disponible)
      if (announcement.originLatLng != null &&
          announcement.destinationLatLng != null) {
        totalDistance += _calculateDistance(
          announcement.originLatLng!.latitude,
          announcement.originLatLng!.longitude,
          announcement.destinationLatLng!.latitude,
          announcement.destinationLatLng!.longitude,
        );
      }
    }

    stats.totalSeatsOffered = totalSeatsOffered;
    stats.totalSeatsBooked = totalSeatsBooked;
    stats.totalRevenue = totalRevenue;
    stats.completedTrips = completedTrips;
    stats.upcomingTrips = upcomingTrips;
    stats.totalDistanceKm = totalDistance;

    // Calculer le taux d'occupation moyen
    if (totalSeatsOffered > 0) {
      stats.averageOccupancyRate = (totalSeatsBooked / totalSeatsOffered) * 100;
    }

    return stats;
  }

  // Calculer les statistiques du passager
  Future<UserStatistics> _calculatePassengerStatistics(
    List<QueryDocumentSnapshot> docs,
    UserStatistics stats,
  ) async {
    stats.totalReservationsMade = docs.length;

    int totalSeatsReserved = 0;
    double totalMoneySpent = 0.0;
    double totalMoneySaved = 0.0;
    double co2Saved = 0.0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final reservation = Reservation.fromJson(data);

      totalSeatsReserved += reservation.seatsReserved;

      // Récupérer le trajet correspondant pour le prix
      if (data['announcementId'] != null) {
        try {
          final announcementDoc = await _db
              .collection('announcements')
              .doc(data['announcementId'])
              .get();

          if (announcementDoc.exists) {
            final announcement = Announcement.fromJson(announcementDoc.data()!);

            final costPerSeat = announcement.price;
            final totalCost = costPerSeat * reservation.seatsReserved;
            totalMoneySpent += totalCost;

            // Calculer les économies (comparé au taxi)
            // Prix moyen taxi en Tunisie: ~2 DT/km
            // Covoiturage: économise environ 50-70%
            final taxiEquivalent = totalCost * 2.5; // Estimation
            totalMoneySaved += (taxiEquivalent - totalCost);

            // Calculer le CO2 économisé
            // Voiture moyenne: 120g CO2/km
            // Partage de voiture: divise par nombre de passagers
            if (announcement.originLatLng != null &&
                announcement.destinationLatLng != null) {
              final distance = _calculateDistance(
                announcement.originLatLng!.latitude,
                announcement.originLatLng!.longitude,
                announcement.destinationLatLng!.latitude,
                announcement.destinationLatLng!.longitude,
              );

              // CO2 économisé = distance * émission par km * part économisée
              co2Saved += distance * 0.12 * 0.6; // 60% d'économie en moyenne
            }
          }
        } catch (e) {
          print('Error fetching announcement for reservation: $e');
        }
      }
    }

    stats.totalSeatsReserved = totalSeatsReserved;
    stats.totalMoneySpent = totalMoneySpent;
    stats.totalMoneySaved = totalMoneySaved;
    stats.co2SavedKg = co2Saved;

    return stats;
  }

  // Calculer la distance entre deux points (formule de Haversine simplifiée)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  // Stream pour mettre à jour les statistiques en temps réel
  Stream<UserStatistics> statisticsStream(String userPhone) async* {
    // Réévaluer les statistiques toutes les 30 secondes
    while (true) {
      yield await calculateUserStatistics(userPhone);
      await Future.delayed(const Duration(seconds: 30));
    }
  }
}

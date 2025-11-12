// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reservation.dart';

class ReservationController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Reservation> _reservations = [];

  List<Reservation> get reservations => _reservations;

  Stream<List<Reservation>> get reservationsStream =>
      _db.collection('reservations').snapshots().map((snap) =>
          snap.docs.map((doc) => Reservation.fromJson(doc.data())).toList());

  ReservationController() {
    reservationsStream.listen((list) {
      _reservations = list;
      notifyListeners();
    });
  }

  /// ✅ Version corrigée : enregistre la réservation liée à un parking
  Future<bool> reserveSeatsOrParking({
    String? announcementId,
    String? parkingId,
    required Reservation res,
  }) async {
    if (!res.isValid()) {
      print("❌ Reservation invalide");
      return false;
    }

    try {
      bool reservationCreated = false; // 🔹 nouveau drapeau

      if (parkingId != null && parkingId.isNotEmpty) {
        print("🚗 Tentative de réservation parking pour ID: $parkingId");

        var parkDoc = await _db.collection('parkings').doc(parkingId).get();
        if (!parkDoc.exists) {
          print("❌ Parking introuvable !");
          return false;
        }

        int availableSpots = parkDoc.data()!['available_spots'] ?? 0;
        print("🔢 Places disponibles : $availableSpots");

        if (availableSpots <= 0) {
          print("❌ Parking complet !");
          // Récupère le token FCM sauvegardé pour ce téléphone
  final tokenSnap = await _db.collection('fcm_tokens').doc(res.reserverPhone).get();
  final token = tokenSnap.data()?['token'];

  await _db.collection('waiting_list').add({
    'parking_id': parkingId,
    'user_name': res.reserverName,
    'user_phone': res.reserverPhone,
    'fcm_token': token,          // peut être null si non trouvé; c'est ok
    'notified': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

          return false;
        }

        // 🔽 Mise à jour des places disponibles
        await _db.collection('parkings').doc(parkingId).update({
          'available_spots': availableSpots - 1,
        });

        // 🔽 Enregistrement de la réservation
        final ref = await _db.collection('reservations').add({
          ...res.toJson(),
          'parking_id': parkingId,
          'type': 'parking',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ Réservation ajoutée → id=${ref.id} / path=${ref.path}');
        final snap = await ref.get();
        print('📄 Relecture immédiate → exists=${snap.exists} data=${snap.data()}');

        reservationCreated = true; // ✅ succès confirmé
      }

      // Cas covoiturage (si tu veux garder plus tard)
      if (announcementId != null && announcementId.isNotEmpty) {
        print("🚌 Réservation pour annonce");
        // logique covoiturage ici...
        reservationCreated = true;
      }

      // ✅ Retourne `true` si au moins une réservation a été créée
      if (reservationCreated) {
        print("✅ Réservation enregistrée avec succès — retour TRUE");
        return true;
      } else {
        print("⚠️ Aucun ID parking ou annonce fourni");
        return false;
      }
    } catch (e) {
      print("🔥 ERREUR FIRESTORE : $e");
      return false;
    }
  }
}

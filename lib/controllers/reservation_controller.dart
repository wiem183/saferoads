// ignore_for_file: avoid_print, use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/announcement.dart';
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

  // --- Email sending ---
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      final smtpServer = gmail(
        'errouissi.wiem18@gmail.com',
        'eoku svhn awsd ckcq', // App password
      );

      final emailMessage = Message()
        ..from = const Address('errouissi.wiem18@gmail.com', 'Covoiturage App')
        ..recipients.add(to)
        ..subject = subject
        ..text = message;

      await send(emailMessage, smtpServer);
      if (kDebugMode) print("✅ Email sent to: $to");
    } catch (e) {
      if (kDebugMode) print("❌ Error sending email: $e");
    }
  }

  /// Reserve seats for an announcement or a parking spot
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
      bool reservationCreated = false;

      // --- Parking reservation ---
      if (parkingId != null && parkingId.isNotEmpty) {
        print("🚗 Reserving parking ID: $parkingId");

        final parkDoc = await _db.collection('parkings').doc(parkingId).get();
        if (!parkDoc.exists) {
          print("❌ Parking not found!");
          return false;
        }

        int availableSpots = parkDoc.data()?['available_spots'] ?? 0;
        if (availableSpots <= 0) {
          print("❌ Parking full! Adding to waiting list.");
          final tokenSnap = await _db.collection('fcm_tokens').doc(res.reserverPhone).get();
          final token = tokenSnap.data()?['token'];

          await _db.collection('waiting_list').add({
            'parking_id': parkingId,
            'user_name': res.reserverName,
            'user_phone': res.reserverPhone,
            'fcm_token': token,
            'notified': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return false;
        }

        await _db.collection('parkings').doc(parkingId).update({
          'available_spots': availableSpots - 1,
        });

        await _db.collection('reservations').add({
          ...res.toJson(),
          'parking_id': parkingId,
          'type': 'parking',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        reservationCreated = true;
      }

      // --- Announcement reservation ---
      if (announcementId != null && announcementId.isNotEmpty) {
        print("🚗 Reserving announcement ID: $announcementId");

        final annDoc = await _db.collection('announcements').doc(announcementId).get();
        if (!annDoc.exists) {
          print("❌ Announcement with ID $announcementId not found!");
          return false;
        }

        final ann = Announcement.fromJson(annDoc.data()!);

        if (ann.availableSeats < res.seatsReserved) {
          print("❌ Not enough seats! Requested: ${res.seatsReserved}, Available: ${ann.availableSeats}");
          return false;
        }

        // Firestore transaction
        await _db.runTransaction((transaction) async {
          transaction.update(
            _db.collection('announcements').doc(announcementId),
            {
              'availableSeats': FieldValue.increment(-res.seatsReserved),
              'reservations': FieldValue.arrayUnion([res.toJson()]),
            },
          );

          final reservationRef = _db.collection('reservations').doc();
          transaction.set(reservationRef, {
            ...res.toJson(),
            'announcementId': announcementId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        reservationCreated = true;

        // --- Send emails ---
        // --- Send emails ---
        final String formattedDate =
        DateFormat('dd/MM/yyyy à HH:mm').format(ann.departureDateTime);
        final double totalPrice = ann.price * res.seatsReserved;

// Send email to reserver if email exists
        final reserverEmail = res.reserverEmail;
        if (reserverEmail != null && reserverEmail.isNotEmpty) {
          _sendEmail(
            to: reserverEmail,
            subject: "Réservation confirmée pour votre trajet",
            message:
            "Bonjour ${res.reserverName},\n\nVotre réservation pour le trajet de ${ann.origin} à ${ann.destination} le $formattedDate "
                "a été confirmée.\nNombre de sièges: ${res.seatsReserved}\nPrix total: $totalPrice TND.\n\nMerci d'utiliser notre application.",
          );
        }

// Send email to driver if email exists
        final driverEmail = ann.driverEmail;
        if (driverEmail != null && driverEmail.isNotEmpty) {
          _sendEmail(
            to: driverEmail,
            subject: "Nouvelle réservation pour votre trajet",
            message:
            "Bonjour ${ann.driverName},\n\n${res.reserverName} a réservé ${res.seatsReserved} siège(s) pour votre trajet de ${ann.origin} à ${ann.destination} le $formattedDate.\n\nMerci d'utiliser notre application.",
          );
        }

      }

      return reservationCreated;
    } catch (e) {
      print("🔥 Firestore error: $e");
      return false;
    }
  }

  // --- User reservations ---
  Stream<List<Reservation>> getUserReservations(String userEmail) {
    return _db
        .collection('reservations')
        .where('reserverEmail', isEqualTo: userEmail)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => Reservation.fromJson(doc.data())).toList());
  }

  // --- Cancel reservation ---
  Future<bool> cancelReservation(
      String reservationId,
      String announcementId,
      int seats,
      ) async {
    try {
      await _db.runTransaction((transaction) async {
        transaction.update(
          _db.collection('announcements').doc(announcementId),
          {'availableSeats': FieldValue.increment(seats)},
        );
        transaction.delete(_db.collection('reservations').doc(reservationId));
      });

      print("✅ Reservation cancelled successfully");
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error cancelling reservation: $e");
      return false;
    }
  }
}

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

  Stream<List<Reservation>> get reservationsStream => _db
      .collection('reservations')
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Reservation.fromJson(data);
        }).toList(),
      );

  ReservationController() {
    reservationsStream.listen((list) {
      _reservations = list;
      notifyListeners();
    });
  }

  // 📧 Méthode pour envoyer des emails directement
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        print('🎯 📧 DÉBUT _sendEmail');
        print('🎯 À: $to');
        print('🎯 Sujet: $subject');
        print('🔧 Tentative d\'envoi SMTP réel...');
      }

      // Configuration SMTP Gmail
      final smtpServer = gmail(
        'errouissi.wiem18@gmail.com',
        'eoku svhn awsd ckcq', // Mot de passe d'application
      );

      // Création du message
      final emailMessage = Message()
        ..from = const Address('errouissi.wiem18@gmail.com', 'Covoiturage App')
        ..recipients.add(to)
        ..subject = subject
        ..text = message;

      // Envoi de l'email
      final sendReport = await send(emailMessage, smtpServer);

      if (kDebugMode) {
        print('✅ Email envoyé avec succès à: $to');
        print('📨 Rapport d\'envoi: $sendReport');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 ❌ ERREUR CAPTURÉE dans _sendEmail: $e');
        print('🎯 ❌ Type d\'erreur: ${e.runtimeType}');
      }
    }
  }

  Future<bool> reserveSeats(String announcementId, Reservation res) async {
    if (!res.isValid()) {
      if (kDebugMode) print("❌ Réservation invalide");
      return false;
    }

    try {
      if (kDebugMode) print("🔄 Début de la réservation...");

      // Récupération du trajet
      var annDoc = await _db
          .collection('announcements')
          .doc(announcementId)
          .get();

      if (!annDoc.exists) {
        if (kDebugMode) print("❌ Annonce non trouvée: $announcementId");
        return false;
      }

      Announcement ann = Announcement.fromJson(annDoc.data()!);

      // Vérification des sièges disponibles
      if (ann.availableSeats < res.seatsReserved) {
        if (kDebugMode) {
          print(
            "❌ Sièges insuffisants. Disponibles: ${ann.availableSeats}, Demandés: ${res.seatsReserved}",
          );
        }
        return false;
      }

      String? reservationId;

      // Utiliser une transaction pour plus de sécurité
      await _db.runTransaction((transaction) async {
        // Mise à jour des sièges disponibles
        transaction.update(
          _db.collection('announcements').doc(announcementId),
          {
            'availableSeats': FieldValue.increment(-res.seatsReserved),
            'reservations': FieldValue.arrayUnion([res.toJson()]),
          },
        );

        // Ajout de la réservation
        final reservationData = res.toJson()
          ..['announcementId'] = announcementId
          ..['createdAt'] = FieldValue.serverTimestamp();

        final reservationRef = _db.collection('reservations').doc();
        reservationId = reservationRef.id;
        transaction.set(reservationRef, reservationData);
      });

      if (kDebugMode) print("✅ Transaction Firestore réussie");

      // Préparation des données pour les emails
      final String formattedDate = DateFormat(
        'dd/MM/yyyy à HH:mm',
      ).format(ann.departureDateTime);
      final double totalPrice = ann.price * res.seatsReserved;

      if (kDebugMode) {
        print("🎯 AVANT ENVOI EMAILS - DEBUG");
        print("🎯 Email passager: ${res.reserverEmail}");
        print("🎯 Email conducteur: ${ann.driverEmail}");
      }

      // 📧 Email de confirmation au PASSAGER
      if (kDebugMode) print("🎯 APPEL _sendEmail PASSAGER");
      await _sendEmail(
        to: res.reserverEmail,
        subject: 'Confirmation de votre réservation - Covoiturage App',
        message:
            '''
Bonjour ${res.reserverName},

VOTRE RÉSERVATION EST CONFIRMÉE ! 🎉

Détails de votre réservation :
---------------------------------
🔸 Trajet : ${ann.origin} → ${ann.destination}
🔸 Date et heure : $formattedDate
🔸 Sièges réservés : ${res.seatsReserved}
🔸 Prix total : ${totalPrice.toStringAsFixed(2)} TND
🔸 Conducteur : ${ann.driverName}
🔸 Téléphone conducteur : ${ann.driverPhone}

Informations importantes :
• Présentez-vous au point de rendez-vous 10 minutes à l'avance
• Ayez votre pièce d'identité avec vous
• Le paiement se fait directement au conducteur

En cas de problème, contactez le conducteur :
${ann.driverName} - ${ann.driverPhone}

Merci d'utiliser notre application de covoiturage !

Cordialement,
L'équipe Covoiturage App
📞 Contact : +216 12 345 678
''',
      );

      // 📧 Email de notification au CONDUCTEUR
      if (kDebugMode) print("🎯 APPEL _sendEmail CONDUCTEUR");
      await _sendEmail(
        to: ann.driverEmail,
        subject: 'Nouvelle réservation sur votre trajet - Covoiturage App',
        message:
            '''
Bonjour ${ann.driverName},

VOUS AVEZ UNE NOUVELLE RÉSERVATION ! 🚗

Détails de la réservation :
-----------------------------
🔸 Passager : ${res.reserverName}
🔸 Email : ${res.reserverEmail}
🔸 Téléphone : ${res.reserverPhone}
🔸 Trajet : ${ann.origin} → ${ann.destination}
🔸 Date : $formattedDate
🔸 Sièges réservés : ${res.seatsReserved}
🔸 Revenu : ${totalPrice.toStringAsFixed(2)} TND

Informations du passager :
• Nom : ${res.reserverName}
• Email : ${res.reserverEmail}
• Téléphone : ${res.reserverPhone}

Actions requises :
1. Contactez le passager pour confirmer le point de rendez-vous
2. Vérifiez les documents si nécessaire
3. Soyez à l'heure au point de rendez-vous

En cas de problème, contactez le passager :
${res.reserverName} - ${res.reserverPhone}

Bon trajet !

Cordialement,
L'équipe Covoiturage App
📞 Support : +216 12 345 678
''',
      );

      if (kDebugMode) {
        print("🎯 APRÈS ENVOI EMAILS - DEBUG");
        print("✅ Réservation complétée avec succès");
        print("📧 Méthodes _sendEmail appelées");
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Erreur lors de la réservation : $e");
        print("❌ Stack trace: ${e.toString()}");
      }
      return false;
    }
  }

  // Méthode pour récupérer les réservations d'un utilisateur
  Stream<List<Reservation>> getUserReservations(String userEmail) {
    return _db
        .collection('reservations')
        .where('reserverEmail', isEqualTo: userEmail)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Reservation.fromJson(data);
          }).toList(),
        );
  }

  // Méthode pour annuler une réservation
  Future<bool> cancelReservation(
    String reservationId,
    String announcementId,
    int seats,
  ) async {
    try {
      await _db.runTransaction((transaction) async {
        // Remettre les sièges disponibles
        transaction.update(
          _db.collection('announcements').doc(announcementId),
          {'availableSeats': FieldValue.increment(seats)},
        );

        // Supprimer la réservation
        transaction.delete(_db.collection('reservations').doc(reservationId));
      });

      if (kDebugMode) print("✅ Réservation annulée avec succès");
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print("❌ Erreur lors de l'annulation : $e");
      return false;
    }
  }
}

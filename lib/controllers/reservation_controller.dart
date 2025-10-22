import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> reserveSeats(String announcementId, Reservation res) async {
    if (!res.isValid()) return false;
    try {
      var annDoc = await _db.collection('announcements').doc(announcementId).get();
      if (!annDoc.exists) return false;
      Announcement ann = Announcement.fromJson(annDoc.data()!);
      if (ann.availableSeats < res.seatsReserved) return false;
      ann.availableSeats -= res.seatsReserved;
      ann.reservations.add(res);
      await _db.collection('announcements').doc(announcementId).update(ann.toJson());
      await _db.collection('reservations').add(res.toJson()..['announcementId'] = announcementId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}